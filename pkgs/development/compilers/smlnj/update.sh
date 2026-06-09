#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=./. -i bash -p bash curl nix-prefetch jq nix-prefetch-github
# shellcheck shell=bash

set -euo pipefail

dir="$(dirname "$0")"
url="https://smlnj.cs.uchicago.edu/dist/working/"
hashfile="$dir/hashes.json"
nixfile="$dir/default.nix"

version="$(curl --silent "$url" \
    | sed -n 's:.*<b>\([0-9]\{3\}\.[0-9.-]\+\)</b>.*:\1:p' \
    | head -n1)"

echo "Latest SML/NJ release: $version"

if [[ -e "$hashfile" ]]; then
    old_version="$(jq -r .version "$hashfile")"
    if [[ $old_version = "$version" ]]; then
        echo "Package is already up-to-date, skipping"
        exit 0
    fi
    echo "Upgrading from $old_version to $version"
else
    echo "Generating hashes for $version"
fi

files=(
    boot.amd64-unix.tgz boot.x86-unix.tgz
)

tmpdir="$(mktemp --directory)"
trap 'rm -rf -- "$tmpdir"' EXIT

declare -a pids=()

for file in "${files[@]}"; do
    nix-prefetch --silent fetchurl --url "$url/$version/$file" > "$tmpdir/$file" &
    pids+=($!)
done

for pid in "${pids[@]}"; do
    wait "$pid"
done

srcHash="$(nix-prefetch-github smlnj legacy --tag "$version" | jq --raw-output .hash)"

{
  printf '{\n'
  for file in "${files[@]}"; do
    printf '  "%s": "%s",\n' "$file" "$(cat "$tmpdir/$file")"
  done
  printf '  "git": "%s"\n' "$srcHash"
  printf '}\n'
} > "$hashfile"

sed --in-place 's:version = "[0-9.]\+";:version = "'"$version"'";:' "$nixfile"

echo "Done"
