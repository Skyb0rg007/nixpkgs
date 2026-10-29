{
  lib,
  runCommand,
  fetchurl,
  jq,
  writers,
}:

let
  cargoLockOverridesUtil = writers.writePython3Bin "cargo-lock-overrides-util" {
    flakeIgnore = [
      "E501"
      "W503"
    ];
  } (builtins.readFile ./cargo-lock-overrides-util.py);

  fetchCrate =
    {
      name,
      version,
      checksum,
      ...
    }:
    fetchurl {
      name = "${name}-${version}.tar.gz";
      url = "https://static.crates.io/crates/${name}/${version}/download";
      sha256 = checksum;
    };
in

/**
  Add nixpkgs-provided crates.io crates to a vendor directory, so that
  `cargoSetupHook` can move the lockfile to them.

  `cargoDeps` is the vendor directory produced by `fetchCargoVendor` or
  `importCargoLock`. Each locked crate that has a newer semver-compatible
  version in `overrides` is updated to that version. When `cargoDeps` is null
  the overrides are the only dependency source and the lockfile is generated
  from them during the build.

  `overrides` is a list of `{ name, version, checksum }`, where `checksum` is
  the sha256 of the `.crate` file as written in `Cargo.lock`.
*/
{
  name,
  cargoDeps ? null,
  overrides,
}:

assert lib.assertMsg (overrides != [ ]) "applyCargoLockOverrides: `overrides` must not be empty";

runCommand "${name}-vendor-overridden"
  {
    nativeBuildInputs = [
      cargoLockOverridesUtil
      jq
    ];
    inherit cargoDeps;
    crates = map (crate: {
      inherit (crate) name version checksum;
      tarball = fetchCrate crate;
    }) overrides;
    __structuredAttrs = true;
    strictDeps = true;
    passthru = {
      inherit overrides;
      ${if cargoDeps != null then "originalCargoDeps" else null} = cargoDeps;
    };
  }
  ''
    mkdir -p "$out"

    if [ -n "''${cargoDeps-}" ]; then
      if ! [ -d "$cargoDeps" ]; then
        echo "ERROR: cargoLockOverrides only support vendor directories, not $cargoDeps"
        exit 1
      fi
      # Symlink farm of the original vendor directory with writable directories.
      cp -rs --no-preserve=mode "$cargoDeps/." "$out"

      # importCargoLock refers to its vendor directory by its store name,
      # which this derivation does not keep.
      config="$out/.cargo/config.toml"
      if [ -e "$config" ]; then
        sed 's|^directory = "cargo-vendor-dir"$|directory = "@vendor@"|' "$(readlink -f "$config")" > config.toml
        mv config.toml "$config"
      fi
    fi

    # fetchCargoVendor vendors crates.io into source-registry-0, while
    # importCargoLock and the default config use the vendor root.
    registryDir="$out"
    if [ -d "$out/source-registry-0" ]; then
      registryDir="$out/source-registry-0"
    fi

    overridesJson=$(mktemp)
    jq '.crates | map({ name, version, checksum })' "$NIX_ATTRS_JSON_FILE" > "$overridesJson"

    jq -r '.crates[] | [.name, .version, .checksum, .tarball] | @tsv' "$NIX_ATTRS_JSON_FILE" |
      while IFS=$'\t' read -r crateName crateVersion crateChecksum crateTarball; do
        crateDir="$registryDir/$crateName-$crateVersion"
        if [ -e "$crateDir" ]; then
          continue
        fi
        echo "Adding $crateName $crateVersion"
        mkdir -p "$crateDir"
        tar xf "$crateTarball" -C "$crateDir" --strip-components=1
        printf '{"files":{},"package":"%s"}' "$crateChecksum" > "$crateDir/.cargo-checksum.json"
      done

    if [ -e "$out/Cargo.lock" ]; then
      cargo-lock-overrides-util plan "$out/Cargo.lock" "$overridesJson" > "$out/.cargo-lock-overrides"
    else
      # No upstream lockfile was vendored: generate one from the overrides.
      touch "$out/.cargo-lock-generate"
    fi
  ''
