#! /usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils curl jq common-updater-scripts cargo python3
# shellcheck shell=bash

set -euo pipefail

version=$(curl -s https://api.github.com/repos/systemd/zram-generator/tags | jq -r '.[0].name')
update-source-version zram-generator "${version#v}"
"$(dirname "$0")/../../../../maintainers/scripts/rust-crates/rust-crates.py" deps -A zram-generator --write
