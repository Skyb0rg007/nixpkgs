#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update cargo python3 git
# shellcheck shell=bash

set -euf -o pipefail

# toposorted manually, please keep in order
PACKAGES=(
    "folly"
    "fizz"
    "mvfst"
    "wangle"
    "fbthrift"
    "fb303"
    "edencommon"
)

for P in "${PACKAGES[@]}"; do
    nix-update "$P" --commit
done

nix-update watchman --commit
"$(dirname "$0")/../../../../maintainers/scripts/rust-crates/rust-crates.py" deps -A watchman --write
git add "$(dirname "$0")" "$(dirname "$0")/../../../development/rust-crates"
git commit --amend --no-edit
