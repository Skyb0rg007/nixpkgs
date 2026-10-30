# shellcheck shell=bash
# shellcheck disable=SC2154 # out, src, patches, postPatch, crateHash come from the derivation
# Unpack a .crate tarball into $out, as an entry of a cargo directory source.

mkdir "$out"
tar -xzf "$src" -C "$out" --strip-components=1 --no-same-owner
cd "$out" || exit 1

for patch in $patches; do
    patch -p1 < "$patch"
done
eval "$postPatch"

# An empty `files` map disables cargo's per-file verification, which allows
# crates to be patched in ./overrides.nix.
checksum=$(echo "$crateHash" | base64 -d | od -An -v -tx1 | tr -d ' \n')
printf '{"files":{},"package":"%s"}' "$checksum" > .cargo-checksum.json
