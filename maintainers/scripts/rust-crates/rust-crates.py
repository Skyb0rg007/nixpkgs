#!/usr/bin/env python3
"""Maintain the nixpkgs crate set in pkgs/development/rust-crates.

See pkgs/development/rust-crates/default.nix for the data format.

Crates are only ever added or bumped when something needs them ("lazy
bumps"): `deps` adds the crates reachable from a package and bumps slots whose
version no longer satisfies a requirement; `update` bumps explicitly named
crates. Everything that evaluation does not need (version requirements,
rust-version, yanked state, dev-dependencies) is fetched from the crates.io
index when the tool runs instead of being stored.
"""

from __future__ import annotations

import argparse
import base64
import concurrent.futures
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

NIXPKGS = Path(__file__).resolve().parents[3]
CRATES_FILE = NIXPKGS / "pkgs/development/rust-crates/crates.json"
INDEX_URL = "https://index.crates.io"
USER_AGENT = "nixpkgs-rust-crates (https://github.com/NixOS/nixpkgs)"


def eprint(*args: Any) -> None:
    print(*args, file=sys.stderr)


# --- semver -----------------------------------------------------------------

VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$")
COMPARATOR_RE = re.compile(
    r"^(=|>=|<=|>|<|~|\^)?\s*(\*|[xX]|\d+)(?:\.(\*|[xX]|\d+))?(?:\.(\*|[xX]|\d+))?"
    r"(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$"
)

Key = tuple[int, int, int, tuple]


def pre_key(pre: str | None) -> tuple:
    if pre is None:
        return (1,)
    ids = tuple((0, int(i), "") if i.isdigit() else (1, 0, i) for i in pre.split("."))
    return (0, *ids)


def version_key(v: str) -> Key:
    m = VERSION_RE.match(v)
    if m is None:
        raise ValueError(f"invalid version {v!r}")
    return (int(m[1]), int(m[2]), int(m[3]), pre_key(m[4]))


def is_prerelease(v: str) -> bool:
    m = VERSION_RE.match(v)
    return m is not None and m[4] is not None


def matches_slot(version: str, slot: str) -> bool:
    """Whether `version` belongs to `slot`; `=version` slots are pins."""
    return version == slot[1:] if slot.startswith("=") else slot_of(version) == slot


def slot_of(v: str) -> str:
    major, minor, patch, _ = version_key(v)
    if major:
        return str(major)
    if minor:
        return f"0.{minor}"
    return f"0.0.{patch}"


@dataclass(frozen=True)
class Comparator:
    op: str
    major: int | None
    minor: int | None
    patch: int | None
    pre: str | None

    def matches(self, key: Key) -> bool:
        M, m, p = self.major, self.minor, self.patch
        if M is None:
            return True
        lo: Key = (M, m or 0, p or 0, pre_key(self.pre))
        full = m is not None and p is not None
        # Exclusive upper bound on major.minor.patch for partial versions.
        partial_hi = (M + 1, 0, 0) if m is None else (M, m + 1, 0)
        num = key[:3]
        if self.op == "^":
            if M > 0 or m is None:
                hi = (M + 1, 0, 0)
            elif m > 0 or p is None:
                hi = (0, m + 1, 0)
            else:
                hi = (0, 0, p + 1)
            return key >= lo and num < hi
        if self.op == "~":
            return key >= lo and num < partial_hi
        if self.op == "=":
            return key == lo if full else key >= lo and num < partial_hi
        if self.op == ">":
            return key > lo if full else num >= partial_hi
        if self.op == ">=":
            return key >= lo
        if self.op == "<":
            return key < lo
        if self.op == "<=":
            return key <= lo if full else num < partial_hi
        raise AssertionError(self.op)


def parse_part(s: str | None) -> int | None:
    return None if s is None or s in ("*", "x", "X") else int(s)


def parse_req(req: str) -> list[Comparator]:
    comparators = []
    for part in req.split(","):
        part = part.strip()
        m = COMPARATOR_RE.match(part)
        if m is None:
            raise ValueError(f"unsupported version requirement {req!r}")
        op, major, minor, patch, pre = m[1], parse_part(m[2]), parse_part(m[3]), parse_part(m[4]), m[5]
        wildcard = any(x in ("*", "x", "X") for x in (m[2], m[3], m[4]) if x is not None)
        if op is None:
            op = "=" if wildcard else "^"
        comparators.append(Comparator(op, major, minor, patch, pre))
    return comparators


def req_matches(req: str, version: str) -> bool:
    comparators = parse_req(req)
    key = version_key(version)
    if key[3] != (1,):
        # Pre-releases only match comparators naming the same major.minor.patch with a pre-release.
        if not any(c.pre is not None and (c.major, c.minor, c.patch) == key[:3] for c in comparators):
            return False
    return all(c.matches(key) for c in comparators)


def slot_from_req(req: str) -> str | None:
    """The slot a requirement selects, if it can be told without the index."""
    try:
        comparators = parse_req(req)
    except ValueError:
        return None
    if len(comparators) != 1:
        return None
    c = comparators[0]
    if c.major is None:
        return None
    if c.op in ("^", "="):
        if c.major > 0:
            return str(c.major)
        if c.minor is not None and c.minor > 0:
            return f"0.{c.minor}"
        if c.minor == 0 and c.patch is not None:
            return f"0.0.{c.patch}"
        return None
    if c.op == "~":
        if c.major > 0:
            return str(c.major)
        if c.minor is not None and c.minor > 0:
            return f"0.{c.minor}"
    return None


# --- crates.io index --------------------------------------------------------


def index_path(name: str) -> str:
    n = name.lower()
    if len(n) <= 2:
        return f"{len(n)}/{n}"
    if len(n) == 3:
        return f"3/{n[0]}/{n}"
    return f"{n[0:2]}/{n[2:4]}/{n}"


class Index:
    def __init__(self) -> None:
        self.cache: dict[str, list[dict[str, Any]]] = {}

    def fetch(self, name: str) -> list[dict[str, Any]]:
        key = name.lower().replace("-", "_")
        if key in self.cache:
            return self.cache[key]
        candidates = {name, name.replace("_", "-"), name.replace("-", "_")}
        records: list[dict[str, Any]] = []
        for candidate in sorted(candidates):
            body = self.get(f"{INDEX_URL}/{index_path(candidate)}")
            if body is not None:
                records = [json.loads(line) for line in body.splitlines() if line]
                break
        if not records:
            raise SystemExit(f"error: crate {name!r} not found in the crates.io index")
        self.cache[key] = records
        return records

    @staticmethod
    def get(url: str) -> str | None:
        """GET `url`, retrying transient failures; None on 404."""
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        for attempt in range(6):
            try:
                with urllib.request.urlopen(request, timeout=60) as response:
                    return response.read().decode()
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return None
                if e.code < 500 and e.code != 429 or attempt == 5:
                    raise
            except (urllib.error.URLError, ConnectionError, TimeoutError):
                if attempt == 5:
                    raise
            time.sleep(0.5 * 2**attempt)
        raise AssertionError

    def prefetch(self, names: Iterable[str]) -> None:
        todo = sorted({n for n in names if n.lower().replace("-", "_") not in self.cache})
        with concurrent.futures.ThreadPoolExecutor(16) as pool:
            list(pool.map(self.fetch, todo))

    def canonical_name(self, name: str) -> str:
        return self.fetch(name)[0]["name"]

    def record(self, name: str, version: str) -> dict[str, Any]:
        for rec in self.fetch(name):
            if rec["vers"] == version:
                return rec
        raise SystemExit(f"error: {name} {version} not found in the crates.io index")

    def pick(self, name: str, req: str | None = None, slot: str | None = None, rust_version: str | None = None) -> dict[str, Any] | None:
        """Newest version matching `req` and `slot`, preferring non-yanked
        releases that build with `rust_version`."""
        records = [
            r for r in self.fetch(name)
            if VERSION_RE.match(r["vers"])
            and (slot is None or matches_slot(r["vers"], slot))
            and (req is None or req_matches(req, r["vers"]))
        ]
        if req is None or "-" not in req:
            records = [r for r in records if not is_prerelease(r["vers"])] or records

        def usable(r: dict[str, Any]) -> bool:
            msrv = r.get("rust_version")
            return rust_version is None or msrv is None or rust_version_key(msrv) <= rust_version_key(rust_version)

        for candidates in (
            [r for r in records if not r.get("yanked") and usable(r)],
            [r for r in records if not r.get("yanked")],
            records,
        ):
            if candidates:
                return max(candidates, key=lambda r: version_key(r["vers"]))
        return None

    def slot_for(self, name: str, req: str) -> str:
        """The crate slot a requirement resolves to.

        Requirements excluding the newest release of their slot (`=` pins,
        `~`, upper bounds) get a pin slot `=version` instead, which can
        coexist with the slot in a registry.
        """
        slot = slot_from_req(req)
        if slot is None:
            rec = self.pick(name, req)
            if rec is None:
                raise SystemExit(f"error: no version of {name} matches {req!r}")
            slot = slot_of(rec["vers"])
        if any(c.op in ("=", "~", "<", "<=") for c in parse_req(req)):
            newest = self.pick(name, None, slot)
            if newest is not None and not req_matches(req, newest["vers"]):
                rec = self.pick(name, req, slot)
                if rec is not None:
                    return "=" + rec["vers"]
        return slot


def rust_version_key(v: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", v)[:3])


# --- edges ------------------------------------------------------------------

EDGE_RE = re.compile(r"^([^@]+)@(=[0-9A-Za-z.+-]+|[0-9.]+)(!?)(?::(.*))?$")


@dataclass(frozen=True)
class Edge:
    name: str
    slot: str
    features: tuple[str, ...]  # includes "default" when default features are enabled


def parse_edge(s: str) -> Edge | None:
    m = EDGE_RE.match(s)
    if m is None:
        return None
    features = tuple(m[4].split(",")) if m[4] else ()
    if m[3] == "":
        features = ("default", *features)
    return Edge(m[1], m[2], features)


def format_edge(name: str, slot: str, features: Iterable[str]) -> str:
    features = set(features)
    marker = "" if "default" in features else "!"
    features.discard("default")
    return f"{name}@{slot}{marker}" + (":" + ",".join(sorted(features)) if features else "")


def merge_edges(edges: Iterable[tuple[str, str, frozenset[str]]]) -> list[str]:
    """Merge edges to the same crate slot into one, unioning their features."""
    merged: dict[tuple[str, str], set[str]] = {}
    for name, slot, features in edges:
        merged.setdefault((name, slot), set()).update(features)
    return sorted(format_edge(n, s, f) for (n, s), f in merged.items())


def make_entry(rec: dict[str, Any], index: Index) -> dict[str, Any]:
    """Turn an index record into the stored metadata for its crate slot."""
    # dependency key (the name features refer to it by) -> [(crate, slot, features, optional)]
    decls: dict[str, list[tuple[str, str, frozenset[str], bool]]] = {}
    for d in rec["deps"]:
        if d.get("kind", "normal") == "dev":
            continue
        if d.get("registry") not in (None, "https://github.com/rust-lang/crates.io-index"):
            raise SystemExit(f"error: {rec['name']} {rec['vers']} depends on a crate from another registry")
        name = d.get("package") or d["name"]
        features = set(d.get("features") or ())
        if d.get("default_features", True):
            features.add("default")
        decls.setdefault(d["name"], []).append(
            (name, index.slot_for(name, d["req"]), frozenset(features), bool(d.get("optional")))
        )

    def optional_decls(key: str) -> list[tuple[str, str, frozenset[str]]]:
        return [(n, s, f) for n, s, f, opt in decls.get(key, []) if opt]

    def required_decls(key: str) -> list[tuple[str, str, frozenset[str]]]:
        return [(n, s, f) for n, s, f, opt in decls.get(key, []) if not opt]

    # Features already enabled on dependencies that are always part of the closure.
    required: dict[tuple[str, str], set[str]] = {}
    for key in decls:
        for n, s, f in required_decls(key):
            required.setdefault((n, s), set()).update(f)
    base = merge_edges((n, s, frozenset(f)) for (n, s), f in required.items())

    features: dict[str, list[str]] = {**rec.get("features", {}), **rec.get("features2", {})}
    explicit_dep_refs = {v[4:] for vals in features.values() for v in vals if v.startswith("dep:")}
    for key in decls:
        if optional_decls(key) and key not in features and key not in explicit_dep_refs:
            features[key] = [f"dep:{key}"]

    # feature -> (edges as (crate, slot, features), referenced features of this crate)
    #
    # Weak dependency features (`dep?/feature`) are treated like `dep/feature`:
    # cargo's dependency resolver, which writes Cargo.lock, activates the
    # optional dependency for them anyway. Only the feature resolver used for
    # compilation honours the weak semantics.
    expanded: dict[str, tuple[list[tuple[str, str, frozenset[str]]], set[str]]] = {}
    for feature, values in features.items():
        edges: list[tuple[str, str, frozenset[str]]] = []
        refs: set[str] = set()
        for value in values:
            if value.startswith("dep:"):
                edges += optional_decls(value[4:])
            elif "/" in value:
                key, sub = value.split("/", 1)
                weak = key.endswith("?")
                key = key.removesuffix("?")
                edges += [(n, s, f | {sub}) for n, s, f in optional_decls(key)]
                edges += [(n, s, frozenset({sub})) for n, s, _ in required_decls(key)]
                if not weak and key in features and key != feature:
                    refs.add(key)
            elif value in features:
                if value != feature:
                    refs.add(value)
            else:
                edges += optional_decls(value)
        expanded[feature] = (edges, refs)

    def encode(edges: list[tuple[str, str, frozenset[str]]]) -> list[str]:
        out = []
        for n, s, f in edges:
            if (n, s) in required:
                # Always in the closure, so only features the dependency
                # declaration doesn't already enable matter.
                extra = f - required[(n, s)]
                if extra:
                    out.append((n, s, frozenset(extra)))
            else:
                out.append((n, s, f))
        return merge_edges(out)

    encoded = {feature: encode(edges) for feature, (edges, _) in expanded.items()}

    # Drop features that activate no edges, directly or through other features.
    useful = {f for f, items in encoded.items() if items}
    changed = True
    while changed:
        changed = False
        for f, (_, refs) in expanded.items():
            if f not in useful and refs & useful:
                useful.add(f)
                changed = True

    entry: dict[str, Any] = {
        "v": rec["vers"],
        "h": base64.b64encode(bytes.fromhex(rec["cksum"])).decode(),
    }
    if base:
        entry["d"] = base
    if useful:
        entry["f"] = {f: sorted(set(encoded[f]) | (expanded[f][1] & useful)) for f in sorted(useful)}
    return entry


# --- crate set on disk ------------------------------------------------------


class CrateSet:
    """The crate set, stored in a single JSON file.

    The file has one line per crate name, followed by one line per slot, so
    that changes to neighbouring crates are separated by an unchanged line
    and merge without conflicts.
    """

    def __init__(self) -> None:
        self._data: dict[str, dict[str, dict[str, Any]]] | None = None
        self.dirty = False

    @property
    def data(self) -> dict[str, dict[str, dict[str, Any]]]:
        if self._data is None:
            self._data = json.loads(CRATES_FILE.read_text()) if CRATES_FILE.exists() else {}
        return self._data

    def slots(self, name: str) -> dict[str, dict[str, Any]]:
        return self.data.get(name, {})

    def get(self, name: str, slot: str) -> dict[str, Any] | None:
        return self.slots(name).get(slot)

    def put(self, name: str, slot: str, entry: dict[str, Any]) -> None:
        old = self.get(name, slot)
        if old != entry:
            self.data.setdefault(name, {})[slot] = entry
            self.dirty = True
            eprint(f"{'updated' if old else 'added'} {name}@{slot}: {old['v'] + ' -> ' if old else ''}{entry['v']}")

    def remove(self, name: str, slot: str) -> None:
        slots = self.data.get(name, {})
        if slots.pop(slot, None) is not None:
            if not slots:
                del self.data[name]
            self.dirty = True
            eprint(f"removed {name}@{slot}")

    def all(self) -> list[tuple[str, str]]:
        return sorted((n, s) for n, slots in self.data.items() for s in slots)

    def save(self) -> None:
        if not self.dirty:
            return
        names = sorted(self.data, key=lambda n: (n.lower(), n))
        lines = ["{"]
        for i, name in enumerate(names):
            slots = self.data[name]
            order = sorted(slots, key=lambda s: version_key(slots[s]["v"]), reverse=True)
            lines.append(f"{json.dumps(name)}: {{")
            for j, slot in enumerate(order):
                entry = json.dumps(slots[slot], sort_keys=True, separators=(",", ":"))
                lines.append(f" {json.dumps(slot)}: {entry}" + ("," if j < len(order) - 1 else ""))
            lines.append("}," if i < len(names) - 1 else "}")
        lines.append("}")
        CRATES_FILE.write_text("\n".join(lines) + "\n")
        self.dirty = False


# --- closure (mirrors closure in pkgs/development/rust-crates/default.nix) ---


def closure(crates: CrateSet, roots: Iterable[str]) -> tuple[set[tuple[str, str]], set[tuple[str, str]]]:
    """Returns (present, missing) crate slots."""
    seen: set[tuple[str, str, str]] = set()
    work: list[tuple[str, str, str]] = []
    missing: set[tuple[str, str]] = set()

    def push(node: tuple[str, str, str]) -> None:
        if node not in seen:
            seen.add(node)
            work.append(node)

    def push_edge(e: Edge) -> None:
        push((e.name, e.slot, ""))
        for f in e.features:
            push((e.name, e.slot, f))

    for root in roots:
        e = parse_edge(root)
        if e is None:
            raise SystemExit(f"error: malformed crate reference {root!r}")
        push_edge(e)

    while work:
        name, slot, feature = work.pop()
        entry = crates.get(name, slot)
        if entry is None:
            missing.add((name, slot))
            continue
        items = entry.get("d", []) if feature == "" else entry.get("f", {}).get(feature, [])
        for item in items:
            e = parse_edge(item)
            if e is None:
                push((name, slot, item))
            else:
                push_edge(e)
    return {(n, s) for n, s, _ in seen} - missing, missing


class Solver:
    def __init__(self, crates: CrateSet, index: Index, rust_version: str | None) -> None:
        self.crates = crates
        self.index = index
        self.rust_version = rust_version

    def requirements(self, present: set[tuple[str, str]]) -> dict[tuple[str, str], set[tuple[str, str]]]:
        """(crate, slot) -> {(req, needed_by)} from the dependencies of `present`."""
        reqs: dict[tuple[str, str], set[tuple[str, str]]] = {}
        for name, slot in sorted(present):
            rec = self.index.record(name, self.crates.get(name, slot)["v"])
            for d in rec["deps"]:
                if d.get("kind", "normal") == "dev":
                    continue
                target = d.get("package") or d["name"]
                reqs.setdefault((target, self.index.slot_for(target, d["req"])), set()).add(
                    (d["req"], f"{name}@{slot}")
                )
        return reqs

    def solve(
        self, root_sets: list[list[str]], root_reqs: dict[tuple[str, str], set[str]] | None = None
    ) -> set[tuple[str, str]]:
        """Add crates until the closures of `root_sets` are packaged, and pick
        versions satisfying every requirement on them.

        Slots whose version already satisfies all requirements are left alone
        (lazy bumps); otherwise the newest version satisfying all of them is
        chosen, which may also be a downgrade (e.g. for `=` pins).
        """
        reported: set[tuple[str, str]] = set()
        for _ in range(100):
            present: set[tuple[str, str]] = set()
            missing: set[tuple[str, str]] = set()
            for roots in root_sets:
                p, m = closure(self.crates, roots)
                present |= p
                missing |= m
            self.index.prefetch(n for n, _ in present | missing)

            reqs = self.requirements(present)
            for key, rs in (root_reqs or {}).items():
                reqs.setdefault(key, set()).update((r, "the package") for r in rs)

            changed = False
            for name, slot in sorted(present | missing):
                entry = self.crates.get(name, slot)
                rs = reqs.get((name, slot), set())
                if entry is not None and all(req_matches(r, entry["v"]) for r, _ in rs):
                    continue
                rec = self.index.pick(name, ",".join(sorted({r for r, _ in rs})) or None, slot, self.rust_version)
                if rec is None:
                    if (name, slot) not in reported:
                        reported.add((name, slot))
                        eprint(
                            f"warning: no version of {name}@{slot} satisfies all of: "
                            + "; ".join(f"{r} (from {by})" for r, by in sorted(rs))
                            + ". Patch a requirement or add a pinned crate."
                        )
                    if entry is not None:
                        continue
                    rec = self.index.pick(name, None, slot, self.rust_version)
                    if rec is None:
                        raise SystemExit(f"error: {name}@{slot} has no published versions")
                if rec["name"] != name:
                    raise SystemExit(f"error: crate {name!r} is published as {rec['name']!r}; fix the reference to it")
                self.crates.put(name, slot, make_entry(rec, self.index))
                changed = True
            if not changed:
                return present
        raise SystemExit("error: crate versions did not converge")


# --- packages ---------------------------------------------------------------

CRATE_DEPS_RE = re.compile(r"^(?P<indent>[ \t]*)crateDeps\s*=\s*\[(?P<body>.*?)\];[ \t]*\n", re.S | re.M)
CARGO_HASH_RE = re.compile(r"^(?P<indent>[ \t]*)cargoHash\s*=\s*\"[^\"]*\";[ \t]*\n", re.M)
CARGO_LOCK_RE = re.compile(r"^(?P<indent>[ \t]*)cargoLock(?:\.lockFile\s*=\s*[^;]*;|\s*=\s*\{)", re.M)


def find_cargo_lock(text: str) -> tuple[int, int, str] | None:
    """Span (including the trailing newline) and indentation of a `cargoLock` attribute."""
    m = CARGO_LOCK_RE.search(text)
    if m is None:
        return None
    end = m.end()
    if text[end - 1] == "{":
        depth = 1
        while depth:
            c = text[end]
            depth += {"{": 1, "}": -1}.get(c, 0)
            end += 1
        end = text.index(";", end) + 1
    if text[end : end + 1] == "\n":
        end += 1
    return m.start(), end, m["indent"]


def all_roots() -> dict[Path, list[str]]:
    """crateDeps of every package in nixpkgs, found by scanning the source."""
    out = subprocess.run(
        ["git", "-C", str(NIXPKGS), "grep", "--untracked", "-l", "-z", "crateDeps = \\[", "--", "*.nix"],
        capture_output=True,
        text=True,
    ).stdout
    roots = {}
    for rel in filter(None, out.split("\0")):
        text = (NIXPKGS / rel).read_text()
        for m in CRATE_DEPS_RE.finditer(text):
            roots[NIXPKGS / rel] = re.findall(r'"([^"]+)"', m["body"])
    return roots


def nix(*args: str) -> str:
    return subprocess.run(args, check=True, capture_output=True, text=True, cwd=NIXPKGS).stdout.strip()


def find_cargo() -> str:
    cargo = shutil.which("cargo")
    if cargo:
        return cargo
    return nix("nix-build", "--no-out-link", "-A", "cargo") + "/bin/cargo"


def default_rust_version() -> str | None:
    try:
        return json.loads(nix("nix-instantiate", "--eval", "--json", "-A", "rustc.version"))
    except subprocess.CalledProcessError:
        return None


def package_expr(args: argparse.Namespace) -> str:
    """A Nix expression for the package selected by -A or -E."""
    if args.attr:
        return f"(import ./. {{ }}).{args.attr}"
    return f"(let pkgs = import ./. {{ }}; in {args.expr})"


def package_source(pkg_expr: str, workdir: Path) -> Path:
    """Unpack and patch the source of the package, returning the cargo root."""
    expr = f"""
      let
        pkgs = import ./. {{ }};
        pkg = {pkg_expr};
      in
      pkgs.stdenvNoCC.mkDerivation {{
        name = "rust-crates-src";
        src = pkg.src or null;
        srcs = pkg.srcs or null;
        sourceRoot = pkg.sourceRoot or null;
        patches = pkg.patches or [ ];
        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;
        # Keep everything that was unpacked: path dependencies may point
        # outside of the source root.
        installPhase = ''
          root=$(realpath --relative-to="$NIX_BUILD_TOP" "$PWD")
          mkdir $out
          cd "$NIX_BUILD_TOP"
          for d in */; do cp -r "$d" $out/; done
          printf %s "$root" > $out/.rust-crates-root
        '';
      }}
    """
    out = Path(nix("nix-build", "--no-out-link", "-E", expr))
    src = workdir / "src"
    shutil.copytree(out, src, symlinks=True)
    for p in [src, *src.rglob("*")]:
        if not p.is_symlink():
            p.chmod(p.stat().st_mode | 0o200)
    src = src / (out / ".rust-crates-root").read_text()
    cargo_root = json.loads(nix("nix-instantiate", "--eval", "--json", "-E", f"{pkg_expr}.cargoRoot or null"))
    return src / cargo_root if cargo_root else src


def manifest_roots(cargo_root: Path, index: Index) -> tuple[list[str], dict[tuple[str, str], set[str]]]:
    """Direct dependencies of the workspace at `cargo_root`, as edges.

    Cargo resolves lockfiles for all workspace members with all features, all
    targets and dev-dependencies, so all of those are roots. Path dependencies
    outside of the workspace contribute their normal and build dependencies.
    """
    cargo = find_cargo()
    edges: list[tuple[str, str, frozenset[str]]] = []
    reqs: dict[tuple[str, str], set[str]] = {}
    visited: set[Path] = set()
    manifests = [(cargo_root / "Cargo.toml", True)]
    while manifests:
        manifest, workspace = manifests.pop()
        manifest = manifest.resolve()
        if manifest in visited:
            continue
        p = subprocess.run(
            [cargo, "metadata", "--format-version", "1", "--no-deps", "--offline", "--manifest-path", str(manifest)],
            capture_output=True,
            text=True,
        )
        if p.returncode != 0:
            raise SystemExit(f"error: cargo metadata failed for {manifest}:\n{p.stderr.strip()}")
        metadata = json.loads(p.stdout)
        packages = metadata["packages"]
        if workspace:
            visited |= {Path(p["manifest_path"]).resolve() for p in packages}
        else:
            packages = [p for p in packages if Path(p["manifest_path"]).resolve() == manifest]
        visited.add(manifest)
        for package in packages:
            # dependency key (rename or name) -> [(crate, slot)]
            keys: dict[str, list[tuple[str, str]]] = {}
            for d in package["dependencies"]:
                if not workspace and d["kind"] == "dev":
                    continue
                source = d.get("source")
                if source is None:
                    if d.get("path"):
                        manifests.append((Path(d["path"]) / "Cargo.toml", False))
                    continue
                if not source.startswith(("registry+https://github.com/rust-lang/crates.io-index", "sparse+https://index.crates.io/")):
                    raise SystemExit(
                        f"error: {package['name']} depends on {d['name']} from {source}; "
                        "only crates.io dependencies are supported"
                    )
                name = index.canonical_name(d["name"])
                slot = index.slot_for(name, d["req"])
                features = set(d["features"])
                if d["uses_default_features"]:
                    features.add("default")
                edges.append((name, slot, frozenset(features)))
                reqs.setdefault((name, slot), set()).add(d["req"])
                keys.setdefault(d.get("rename") or d["name"], []).append((name, slot))
            # All features of the package are enabled, including the ones it
            # enables on its dependencies (`dep/feature`, `dep?/feature`).
            for values in package["features"].values():
                for value in values:
                    if "/" in value:
                        key, sub = value.split("/", 1)
                        for name, slot in keys.get(key.removesuffix("?"), []):
                            edges.append((name, slot, frozenset({sub})))
    return merge_edges(edges), reqs


def format_crate_deps(roots: list[str], indent: str) -> str:
    inner = indent + "  "
    return f"{indent}crateDeps = [\n" + "".join(f'{inner}"{r}"\n' for r in roots) + f"{indent}];\n"


def package_file(pkg_expr: str) -> Path:
    position = nix("nix-instantiate", "--eval", "--json", "-E", f"{pkg_expr}.meta.position")
    return Path(json.loads(position).rsplit(":", 1)[0])


def write_crate_deps(file: Path, roots: list[str]) -> None:
    """Replace crateDeps, cargoHash or cargoLock in `file` with `roots`."""
    text = file.read_text()
    m = CRATE_DEPS_RE.search(text) or CARGO_HASH_RE.search(text)
    span = (m.start(), m.end(), m["indent"]) if m else find_cargo_lock(text)
    if span is None:
        raise SystemExit(f"error: found none of crateDeps, cargoHash or cargoLock in {file}; add crateDeps by hand")
    start, end, indent = span
    file.write_text(text[:start] + format_crate_deps(roots, indent) + text[end:])
    eprint(f"wrote crateDeps to {file}")


# --- commands ---------------------------------------------------------------


def parse_spec(spec: str) -> tuple[str, str | None]:
    name, _, rest = spec.partition("@")
    return name, rest or None


def cmd_deps(args: argparse.Namespace, solver: Solver) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        if args.src:
            src = Path(args.src).resolve()
            if src.is_file():
                with tarfile.open(src) as tar:
                    tar.extractall(tmp, filter="data")
                (src,) = [p for p in Path(tmp).iterdir() if p.is_dir()]
            cargo_root = src
        else:
            cargo_root = package_source(package_expr(args), Path(tmp))
        roots, reqs = manifest_roots(cargo_root, solver.index)
    file = None
    if args.write:
        if args.write != "auto":
            file = Path(args.write).resolve()
        elif not args.src:
            file = package_file(package_expr(args))
        else:
            raise SystemExit("error: --write needs a file name when used with --src")
    # Solve together with every other package, so that shared crate slots stay consistent.
    others = [r for f, r in all_roots().items() if f.resolve() != file]
    solver.solve([roots, *others], reqs)
    solver.crates.save()
    present, _ = closure(solver.crates, roots)
    eprint(f"{len(roots)} direct dependencies, {len(present)} crates in the closure")
    if file is not None:
        write_crate_deps(file, roots)
    else:
        print(format_crate_deps(roots, "  "), end="")


def cmd_add(args: argparse.Namespace, solver: Solver) -> None:
    roots = []
    for spec in args.crates:
        name, req = parse_spec(spec)
        name = solver.index.canonical_name(name)
        slot = solver.index.slot_for(name, req or "*")
        if solver.crates.get(name, slot) is None:
            solver.add(name, slot, req)
        roots.append(format_edge(name, slot, {"default"}))
    solver.solve([roots, *all_roots().values()])
    solver.crates.save()


def cmd_update(args: argparse.Namespace, solver: Solver) -> None:
    targets = solver.crates.all() if args.all else []
    for spec in args.crates:
        name, slot = parse_spec(spec)
        slots = [slot] if slot else list(solver.crates.slots(name))
        if not slots:
            raise SystemExit(f"error: {name} is not packaged")
        targets += [(name, s) for s in slots]
    solver.index.prefetch(n for n, _ in targets)
    for name, slot in targets:
        rec = solver.index.pick(name, None, slot, solver.rust_version)
        if rec is not None:
            solver.crates.put(name, slot, make_entry(rec, solver.index))
    solver.solve(list(all_roots().values()))
    solver.crates.save()


def cmd_check(args: argparse.Namespace, solver: Solver) -> None:
    crates = solver.crates
    errors = 0
    everything = crates.all()
    solver.index.prefetch(n for n, _ in everything)
    for name, slot in everything:
        entry = crates.get(name, slot)
        expected = make_entry(solver.index.record(name, entry["v"]), solver.index)
        if expected != entry:
            if args.fix:
                crates.put(name, slot, expected)
            else:
                eprint(f"error: {name}@{slot} does not match the crates.io index (fix with `check --fix`)")
                errors += 1
    if args.fix:
        crates.save()
    packaged = set(everything)
    for name, slot in everything:
        rec = solver.index.record(name, crates.get(name, slot)["v"])
        for d in rec["deps"]:
            if d.get("kind", "normal") == "dev":
                continue
            target = d.get("package") or d["name"]
            target_slot = solver.index.slot_for(target, d["req"])
            if (target, target_slot) in packaged and not req_matches(d["req"], crates.get(target, target_slot)["v"]):
                eprint(f"error: {name}@{slot} requires {target} {d['req']}, but {target}@{target_slot} is {crates.get(target, target_slot)['v']}")
                errors += 1
    reachable: set[tuple[str, str]] = set()
    for file, roots in all_roots().items():
        present, missing = closure(crates, roots)
        reachable |= present
        for name, slot in sorted(missing):
            eprint(f"error: {file.relative_to(NIXPKGS)} needs {name}@{slot}, which is not packaged")
            errors += 1
    for name, slot in sorted(packaged - reachable):
        eprint(f"warning: {name}@{slot} is not used by any package (remove it with `prune`)")
    if errors:
        raise SystemExit(f"{errors} error(s)")
    eprint(f"{len(packaged)} crate slots OK")


def cmd_prune(args: argparse.Namespace, solver: Solver) -> None:
    reachable: set[tuple[str, str]] = set()
    for roots in all_roots().values():
        reachable |= closure(solver.crates, roots)[0]
    for name, slot in solver.crates.all():
        if (name, slot) not in reachable:
            solver.crates.remove(name, slot)
    solver.crates.save()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--rust-version", help="newest rust-version crates may require (default: nixpkgs' rustc)")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("deps", help="compute crateDeps for a package, adding or bumping the crates it needs")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("-A", dest="attr", help="nixpkgs attribute of the package")
    g.add_argument("-E", dest="expr", help="Nix expression for the package; `pkgs` is in scope")
    g.add_argument("--src", help="path to a source tree or tarball containing the cargo workspace")
    p.add_argument(
        "--write",
        nargs="?",
        const="auto",
        metavar="FILE",
        help="replace crateDeps, cargoHash or cargoLock in FILE (default: the file defining the package)",
    )
    p.set_defaults(func=cmd_deps)

    p = sub.add_parser("add", help="add crates, e.g. `serde` or `rand@^0.8`")
    p.add_argument("crates", nargs="+")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("update", help="bump crate slots to their newest compatible version")
    p.add_argument("crates", nargs="*", help="`name` (all slots) or `name@slot`")
    p.add_argument("--all", action="store_true", help="bump every crate slot")
    p.set_defaults(func=cmd_update)

    p = sub.add_parser("check", help="validate the crate set against the crates.io index and all packages")
    p.add_argument("--fix", action="store_true", help="regenerate entries that differ from the index, keeping their versions")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("prune", help="remove crate slots no package needs")
    p.set_defaults(func=cmd_prune)

    args = parser.parse_args()
    rust_version = args.rust_version or os.environ.get("RUST_VERSION") or default_rust_version()
    args.func(args, Solver(CrateSet(), Index(), rust_version))


if __name__ == "__main__":
    main()
