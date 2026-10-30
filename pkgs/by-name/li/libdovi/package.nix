{
  lib,
  rustPlatform,
  fetchCrate,
  cargo-c,
  buildPackages,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "libdovi";
  version = "3.3.1";

  __structuredAttrs = true;

  src = fetchCrate {
    pname = "dolby_vision";
    inherit (finalAttrs) version;
    hash = "sha256-ecd+r0JWZtP/rxt4Y3Cj2TkygXIMy5KZhZpXBwJNPx4=";
  };

  crateDeps = [
    "anyhow@1"
    "bitvec@1"
    "bitvec_helpers@3!:bitstream-io"
    "crc@3"
    "criterion@0.5"
    "libc@0.2"
    "roxmltree@0.20"
    "serde@1:derive"
    "serde_json@1:preserve_order"
    "tinyvec@1:rustc_1_55,serde"
  ];

  nativeBuildInputs = [ cargo-c ];

  buildPhase = ''
    runHook preBuild
    ${buildPackages.rust.envVars.setEnv} cargo cbuild -j $NIX_BUILD_CORES --release --frozen --prefix=${placeholder "out"} --target ${stdenv.hostPlatform.rust.rustcTarget}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ${buildPackages.rust.envVars.setEnv} cargo cinstall -j $NIX_BUILD_CORES --release --frozen --prefix=${placeholder "out"} --target ${stdenv.hostPlatform.rust.rustcTarget}
    runHook postInstall
  '';

  checkPhase = ''
    runHook preCheck
    ${buildPackages.rust.envVars.setEnv} cargo ctest -j $NIX_BUILD_CORES --release --frozen --prefix=${placeholder "out"} --target ${stdenv.hostPlatform.rust.rustcTarget}
    runHook postCheck
  '';

  meta = {
    description = "C library for Dolby Vision metadata parsing and writing";
    homepage = "https://crates.io/crates/dolby_vision";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
