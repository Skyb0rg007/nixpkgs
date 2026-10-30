{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo,
  cmake,
  pkg-config,
  rustPlatform,
  rustCrates,
  rustc,
  fcitx5,
  ibus,
  libsForQt5,
  zstd,
  withFcitx5Support ? false,
  withIbusSupport ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openbangla-keyboard";
  version = "2.0.0-unstable-2025-08-19";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "openbangla";
    repo = "openbangla-keyboard";
    rev = "723e348ad2cb0607684d907ce8a9457e12993f4f";
    hash = "sha256-XAcL4gBcu84DMR6o9JSJ/PmI1PsDdTETknD6C48E8ek=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    cargo
    rustc
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    libsForQt5.wrapQtAppsHook
  ];

  buildInputs =
    lib.optionals withFcitx5Support [
      fcitx5
    ]
    ++ lib.optionals withIbusSupport [
      ibus
    ]
    ++ [
      libsForQt5.qtbase
      zstd
    ];

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "ahash@0.8:serde"
      "edit-distance@2"
      "emojicon@0.5:custom"
      "okkhor@0.7"
      "poriborton@0.2"
      "regex@1"
      "rustversion@1"
      "serde_json@1"
      "stringplus@0.1"
      "upodesh@0.2"
    ];
  };

  cmakeFlags =
    lib.optionals withFcitx5Support [
      "-DENABLE_FCITX=YES"
    ]
    ++ lib.optionals withIbusSupport [
      "-DENABLE_IBUS=YES"
    ];

  patches = [
    ./0001-skip-enable-language-rust.patch
  ];

  cargoRoot = "src/engine/riti";

  meta = {
    isIbusEngine = withIbusSupport;
    description = "OpenSource, Unicode compliant Bengali Input Method";
    mainProgram = "openbangla-gui";
    homepage = "https://openbangla.github.io/";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ johnrtitor ];
    platforms = lib.platforms.linux;
    # never built on aarch64-linux since first introduction in nixpkgs
    broken = stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64;
  };
})
