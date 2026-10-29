{
  lib,
  importCargoLock,
  fetchCargoVendor,
  applyCargoLockOverrides,
  stdenv,
  cargoBuildHook,
  cargoCheckHook,
  cargoInstallHook,
  cargoNextestHook,
  cargoSetupHook,
  cargo,
  cargo-auditable,
  buildPackages,
  rustc,
  windows,
}:

let
  getOptionalAttrs =
    names: attrs: lib.getAttrs (lib.intersectLists names (lib.attrNames attrs)) attrs;

  interpolateString =
    s:
    if lib.isList s then
      lib.concatMapStringsSep " " (s: "${s}") (lib.filter (s: s != null) s)
    else if s == null then
      ""
    else
      "${s}";
in
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "depsExtraArgs"
    "cargoUpdateHook"
    "cargoLock"
    "cargoLockOverrides"
    "RUSTFLAGS"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      # Name for the vendored dependencies tarball
      cargoDepsName ? null,

      cargoPatches ? [ ],
      patches ? [ ],
      sourceRoot ? null,
      cargoRoot ? null,
      logLevel ? "",
      buildInputs ? [ ],
      nativeBuildInputs ? [ ],
      cargoUpdateHook ? "",
      cargoDepsHook ? "",
      buildType ? "release",
      meta ? { },
      cargoDeps ? null,
      cargoHash ? null,
      cargoLock ? null,
      # Newer semver-compatible crates.io crates to use instead of the locked
      # ones, as a list of `{ name, version, checksum }`. Without any other
      # dependency source the lockfile is generated from these crates alone.
      cargoLockOverrides ? [ ],
      cargoVendorDir ? null,
      checkType ? buildType,
      buildNoDefaultFeatures ? false,
      checkNoDefaultFeatures ? buildNoDefaultFeatures,
      buildFeatures ? [ ],
      checkFeatures ? buildFeatures,
      useNextest ? false,
      auditable ? !cargo-auditable.meta.broken,

      depsExtraArgs ? { },

      # Needed to `pushd`/`popd` into a subdir of a tarball if this subdir
      # contains a Cargo.toml, but isn't part of a workspace (which is e.g. the
      # case for `rustfmt`/etc from the `rust-sources).
      # Otherwise, everything from the tarball would've been built/tested.
      buildAndTestSubdir ? null,
      ...
    }@args:

    {
      env =
        let
          isDarwinDebug = stdenv.hostPlatform.isDarwin && buildType == "debug";
        in
        {
          PKG_CONFIG_ALLOW_CROSS = if stdenv.buildPlatform != stdenv.hostPlatform then 1 else 0;
          RUST_LOG = logLevel;
          # Prevent shadowing *_RUSTFLAGS environment variables
          ${if args ? RUSTFLAGS || isDarwinDebug then "RUSTFLAGS" else null} =
            lib.optionalString isDarwinDebug "-C split-debuginfo=packed "
            # Workaround the existing RUSTFLAGS specified as a list.
            + interpolateString (args.RUSTFLAGS or "");
        }
        // args.env or { };

      cargoDeps =
        let
          baseCargoDeps =
            if cargoVendorDir != null then
              null
            else if cargoDeps != null then
              cargoDeps
            else if cargoLock != null then
              importCargoLock cargoLock
            else if finalAttrs.cargoHash == null then
              if cargoLockOverrides != [ ] then
                null
              else
                throw "cargoHash, cargoVendorDir, cargoDeps, cargoLock, or cargoLockOverrides must be set"
            else
              fetchBaseCargoDeps;
          fetchBaseCargoDeps = fetchCargoVendor (
            getOptionalAttrs [
              "name"
              "pname"
              "version"
              "src"
              "srcs"
              "sourceRoot"
              "cargoRoot"
              "preUnpack"
              "unpackPhase"
              "postUnpack"
            ] finalAttrs
            // {
              ${if cargoDepsName != null then "name" else null} = cargoDepsName;
              patches = cargoPatches;
              hash = finalAttrs.cargoHash;
            }
            // depsExtraArgs
          );
        in
        if cargoLockOverrides == [ ] then
          baseCargoDeps
        else
          assert lib.assertMsg (
            cargoVendorDir == null
          ) "cargoLockOverrides cannot be used together with cargoVendorDir";
          applyCargoLockOverrides {
            name =
              if cargoDepsName != null then
                cargoDepsName
              else
                finalAttrs.name or "${finalAttrs.pname}-${finalAttrs.version}";
            cargoDeps = baseCargoDeps;
            overrides = cargoLockOverrides;
          };
      inherit
        buildAndTestSubdir
        cargoHash
        ;

      cargoBuildType = buildType;

      cargoCheckType = checkType;

      cargoBuildNoDefaultFeatures = buildNoDefaultFeatures;

      cargoCheckNoDefaultFeatures = checkNoDefaultFeatures;

      cargoBuildFeatures = buildFeatures;

      cargoCheckFeatures = checkFeatures;

      nativeBuildInputs =
        nativeBuildInputs
        ++ lib.optionals auditable [
          (buildPackages.cargo-auditable-cargo-wrapper.override {
            inherit cargo cargo-auditable;
          })
        ]
        ++ [
          cargoBuildHook
          (if useNextest then cargoNextestHook else cargoCheckHook)
          cargoInstallHook
          cargoSetupHook
          rustc
          cargo
        ];

      buildInputs = buildInputs ++ lib.optionals stdenv.hostPlatform.isMinGW [ windows.pthreads ];

      patches = cargoPatches ++ patches;

      configurePhase =
        args.configurePhase or ''
          runHook preConfigure
          runHook postConfigure
        '';

      doCheck = args.doCheck or true;

      strictDeps = true;

      meta = meta // {
        badPlatforms = meta.badPlatforms or [ ] ++ rustc.badTargetPlatforms;
        # default to Rust's platforms
        platforms = lib.intersectLists meta.platforms or lib.platforms.all rustc.targetPlatforms;
      };
    };
}
