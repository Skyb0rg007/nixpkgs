# Resolve dependencies against a crate registry built by rustCrates.mkRegistry.
#
# Such registries carry no Cargo.lock: upstream's lockfile is replaced by one
# generated against the crates in the registry. The result is also placed in
# the registry copy, so that cargoSetupPostPatchHook's consistency check
# passes. This hook must therefore come before cargoSetupHook.

cargoRegistryPostPatchHook() {
    echo "Executing cargoRegistryPostPatchHook"

    if [ ! -e "${cargoDepsCopy-}/.nixpkgs-crate-registry" ]; then
        echo "ERROR: cargoRegistryHook requires cargoDeps to be built by rustCrates.mkRegistry"
        exit 1
    fi

    local cargoRootDir
    cargoRootDir="$(pwd)/${cargoRoot:+$cargoRoot/}"

    echo "Generating ${cargoRootDir}Cargo.lock from the nixpkgs crate registry"
    rm -f "${cargoRootDir}Cargo.lock"
    if ! (cd "$cargoRootDir" && cargo generate-lockfile --offline); then
        echo
        echo "ERROR: dependencies could not be resolved against the nixpkgs crate registry"
        echo
        echo "crateDeps is probably out of date, or a crate in rustCrates is too old."
        echo "To fix the issue, regenerate crateDeps (adding or bumping crates as needed):"
        echo "  maintainers/scripts/rust-crates/rust-crates.py deps -A <attr> --write"
        echo

        exit 1
    fi

    # The lockfile lives at the root of the workspace, which may be above
    # cargoRoot. Put a copy where cargoSetupPostPatchHook looks for it.
    local lockfile
    lockfile="$(dirname "$(cd "$cargoRootDir" && cargo locate-project --workspace --message-format plain)")/Cargo.lock"
    if [ "$(realpath "$lockfile")" != "$(realpath -m "${cargoRootDir}Cargo.lock")" ]; then
        cp "$lockfile" "${cargoRootDir}Cargo.lock"
    fi
    cp "$lockfile" "$cargoDepsCopy/Cargo.lock"

    echo "Finished cargoRegistryPostPatchHook"
}

postPatchHooks+=(cargoRegistryPostPatchHook)
