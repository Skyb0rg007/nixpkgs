import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any

SEMVER_REGEX = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$")

CRATES_IO_SOURCES = {
    "registry+https://github.com/rust-lang/crates.io-index",
    "sparse+https://index.crates.io/",
}


def parse_version(version: str) -> tuple[int, int, int, str | None]:
    match = SEMVER_REGEX.match(version)
    if match is None:
        raise Exception(f"Unable to parse crate version: {version}")
    major, minor, patch, pre = match.groups()
    return int(major), int(minor), int(patch), pre


def compatibility_key(version: tuple[int, int, int, str | None]) -> tuple[int, ...]:
    # Same rules as cargo's caret requirements:
    # 1.2.3 is compatible with 1.x.y, 0.2.3 with 0.2.x, 0.0.3 only with itself.
    major, minor, patch, _ = version
    if major != 0:
        return (major,)
    if minor != 0:
        return (0, minor)
    return (0, 0, patch)


def is_newer(new: tuple[int, int, int, str | None], old: tuple[int, int, int, str | None]) -> bool:
    if new[:3] != old[:3]:
        return new[:3] > old[:3]
    # a release is newer than its pre-releases
    return new[3] is None and old[3] is not None


def plan_overrides(lockfile_path: Path, overrides_path: Path) -> None:
    """
    Print one `<name>@<locked version> <override version>` line for every
    locked crates.io package that an override supersedes.
    """
    with open(lockfile_path, "rb") as f:
        lockfile = tomllib.load(f)
    with open(overrides_path) as f:
        overrides: list[dict[str, Any]] = json.load(f)

    for pkg in lockfile.get("package", []):
        if pkg.get("source") not in CRATES_IO_SOURCES:
            continue
        locked = parse_version(pkg["version"])
        candidates = [
            override for override in overrides
            if override["name"] == pkg["name"]
            and compatibility_key(parse_version(override["version"])) == compatibility_key(locked)
            and is_newer(parse_version(override["version"]), locked)
        ]
        if not candidates:
            continue
        best = max(candidates, key=lambda override: parse_version(override["version"])[:3])
        print(f"{pkg['name']}@{pkg['version']} {best['version']}")


def main() -> None:
    subcommand = sys.argv[1]
    if subcommand == "plan":
        plan_overrides(lockfile_path=Path(sys.argv[2]), overrides_path=Path(sys.argv[3]))
    else:
        raise Exception(f"Unknown subcommand: '{subcommand}'. Must be one of ['plan']")


if __name__ == "__main__":
    main()
