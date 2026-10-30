{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPackages,
  rustPlatform,
  cargo-c,
  python3,

  # tests
  testers,
  vips,
  libimagequant,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "libimagequant";
  version = "4.4.1";

  src = fetchFromGitHub {
    owner = "ImageOptim";
    repo = "libimagequant";
    rev = finalAttrs.version;
    hash = "sha256-A7idjAAJ+syqIahyU+LPZBF+MLxVDymY+M3HM7d/qk0=";
  };

  crateDeps = [
    "arrayvec@0.7"
    "bitflags@2"
    "cc@1"
    "libc@0.2"
    "lodepng@3"
    "once_cell@1"
    "rayon@1"
    "rgb@0.8!:bytemuck"
    "thread_local@1"
  ];

  nativeBuildInputs = [ cargo-c ];

  postBuild = ''
    pushd imagequant-sys
    ${buildPackages.rust.envVars.setEnv} cargo cbuild --release --frozen --prefix=${placeholder "out"} --target ${stdenv.hostPlatform.rust.rustcTarget}
    popd
  '';

  postInstall = ''
    pushd imagequant-sys
    ${buildPackages.rust.envVars.setEnv} cargo cinstall --release --frozen --prefix=${placeholder "out"} --target ${stdenv.hostPlatform.rust.rustcTarget}
    popd
  '';

  passthru.tests = {
    inherit vips;
    inherit (python3.pkgs) pillow;

    pkg-config = testers.hasPkgConfigModules {
      package = libimagequant;
      moduleNames = [ "imagequant" ];
    };
  };

  meta = {
    homepage = "https://pngquant.org/lib/";
    description = "Image quantization library";
    longDescription = "Small, portable C library for high-quality conversion of RGBA images to 8-bit indexed-color (palette) images.";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ma9e ];
  };
})
