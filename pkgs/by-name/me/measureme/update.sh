#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nix jq gnused curl nix-prefetch-git cargo python3

set -eu -o pipefail

package_dir="$(dirname "${BASH_SOURCE[0]}")"

echo "Fetching latest version"
version=$(curl -sfL ${GITHUB_TOKEN:+-u ":$GITHUB_TOKEN"} https://api.github.com/repos/rust-lang/measureme/releases/latest | jq -r '.tag_name')

echo "Latest version is $version"
if [[ "$UPDATE_NIX_OLD_VERSION" == "$version" ]]; then
    echo "Already up to date!"
    exit 0
fi

echo "Fetching source hash"
hash="$(nix-prefetch-git https://github.com/rust-lang/measureme.git --quiet --rev "refs/tags/$version" | jq -r '.hash')"

sed -i "s#hash = \".*\";#hash = \"$hash\";#g" "$package_dir/package.nix"
sed -i "s#version = \".*\";#version = \"$version\";#g" "$package_dir/package.nix"

echo "Updating crateDeps"
"$package_dir/../../../../maintainers/scripts/rust-crates/rust-crates.py" deps -A measureme --write
