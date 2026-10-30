{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rewrk";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "lnx-search";
    repo = "rewrk";
    rev = finalAttrs.version;
    hash = "sha256-Bqr5kmIIx+12hW4jpINcv0GBJBbMAkd4di/hZSXlT18=";
  };

  crateDeps = [
    "anyhow@1"
    "clap@2"
    "colored@2"
    "http@0.2"
    "hyper@0.14:client,http1,http2,runtime"
    "rand@0.8"
    "regex@1"
    "rustls-native-certs@0.5"
    "rustls@0.19"
    "serde_json@1"
    "tokio-rustls@0.22"
    "tokio@1:macros,net,rt,rt-multi-thread"
    "tower@0.4:util"
  ];

  meta = {
    description = "More modern http framework benchmarker supporting HTTP/1 and HTTP/2 benchmarks";
    homepage = "https://github.com/lnx-search/rewrk";
    changelog = "https://github.com/lnx-search/rewrk/releases/tag/${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "rewrk";
  };
})
