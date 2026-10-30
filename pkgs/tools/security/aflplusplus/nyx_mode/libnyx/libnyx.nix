{
  lib,
  stdenv,
  rustPlatform,
  aflplusplus,
  python3,
}:

rustPlatform.buildRustPackage {
  version = builtins.readFile (aflplusplus.src + "/nyx_mode/LIBNYX_VERSION");
  pname = "libnyx";

  src = aflplusplus.src;
  postUnpack = ''
    sourceRoot="$sourceRoot/nyx_mode/libnyx/libnyx"
  '';

  crateDeps = [
    "byteorder@1"
    "cbindgen@0.28"
    "colored@2"
    "derivative@2"
    "fs4@0.5"
    "glob@0.3"
    "libc@0.2"
    "nix@0.26"
    "quick-error@2"
    "rand@0.7"
    "ron@0.6"
    "serde@1"
    "serde_derive@1"
    "snafu@0.6"
    "subprocess@0.2"
    "time@0.2"
    "timeout-readwrite@0.3"
  ];

  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp "target/${stdenv.hostPlatform.rust.rustcTarget}/release/liblibnyx.so" $out/lib/libnyx.so
    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/nyx-fuzz/libnyx";
    description = "Rust library to build hypervisor-based snapshot fuzzers";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ ekzyis ];
  };
}
