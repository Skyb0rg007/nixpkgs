{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  zlib,
  stdenv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "add-determinism";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "keszybz";
    repo = "add-determinism";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Gg1tObrUtHDjw52g3jjJm5bD5ctxujWOolaCqV7+ZjQ=";
  };

  crateDeps = [
    "anyhow@1"
    "chrono@0.4"
    "clap@4:derive"
    "crossbeam-channel@0.5"
    "executable-path@1"
    "glob@0.3"
    "indoc@2"
    "itertools@0.13"
    "log@0.4:std"
    "num-bigint-dig@0.8"
    "num-integer@0.1"
    "num-traits@0.2"
    "regex@1!:perf,std,unicode-case"
    "rlimit@0.10"
    "selinux@0.4"
    "tempfile@3"
    "thiserror@1"
    "time@0.3"
    "walkdir@2"
    "zip@0.6!:deflate,deflate-zlib,time"
  ];

  postInstall = ''
    ln -s add-det $out/bin/add-determinism
  '';

  doCheck = !stdenv.hostPlatform.isDarwin; # it seems to be running forever on darwin

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    zlib
  ];

  meta = {
    description = "Build postprocessor to reset metadata fields for build reproducibility";
    homepage = "https://github.com/keszybz/add-determinism";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      Emin017
      sharzy
    ];
    platforms = lib.platforms.all;
    mainProgram = "add-det";
  };
})
