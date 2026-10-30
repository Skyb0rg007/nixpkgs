{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  glib,
  openssl,
  zlib,
  ostree,
  stdenv,
  util-linux,
  skopeo,
  gnutar,
  ima-evm-utils,
}:

rustPlatform.buildRustPackage rec {
  pname = "ostree-rs-ext";
  version = "0.10.6";

  src = fetchFromGitHub {
    owner = "ostreedev";
    repo = "ostree-rs-ext";
    rev = "ostree-ext-v${version}";
    hash = "sha256-kk/icUevzKMpAQ6IoruUxuKwTxXHlKLrr63Hch1w7po=";
  };

  crateDeps = [
    "anyhow@1"
    "async-compression@0.3:gzip,tokio"
    "bitflags@1"
    "camino@1"
    "cap-std-ext@1"
    "cap-tempfile@1"
    "chrono@0.4"
    "clap@3:derive"
    "clap_mangen@0.1"
    "containers-image-proxy@0.5"
    "flate2@1!:zlib"
    "fn-error-context@0.2"
    "futures-util@0.3"
    "gvariant@0.4"
    "hex@0.4"
    "indicatif@0.17"
    "indoc@1"
    "io-lifetimes@1"
    "libc@0.2"
    "libsystemd@0.5"
    "log@0.4"
    "oci-spec@0.5"
    "olpc-cjson@0.1"
    "once_cell@1"
    "openssl@0.10"
    "ostree@0.17:cap-std-apis,dox,v2022_5"
    "pin-project@1"
    "quickcheck@1"
    "regex@1"
    "serde@1:derive"
    "serde_json@1"
    "sh-inline@0.4:cap-std-ext"
    "tar@0.4"
    "tempfile@3"
    "term_size@0.3"
    "tokio-stream@0.1:sync"
    "tokio-util@0.7:io-util"
    "tokio@1:io-std,macros,net,process,rt,time"
    "tracing-subscriber@0.2"
    "tracing@0.1"
  ];

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    glib
    openssl
    zlib
    ostree
  ];

  checkFlags = [
    # these tests expects /var/tmp to be available
    "--skip=test_cli_fns"
    "--skip=test_container_chunked"
    "--skip=test_container_import_export_v1"
    "--skip=test_container_var_content"
    "--skip=test_container_write_derive"
    "--skip=test_container_write_derive_sysroot_hardlink"
    "--skip=test_diff"
    "--skip=test_tar_export_reproducible"
    "--skip=test_tar_export_structure"
    "--skip=test_tar_import_empty"
    "--skip=test_tar_import_export"
    "--skip=test_tar_import_signed"
    "--skip=test_tar_write"
    "--skip=test_tar_write_tar_layer"
  ];

  postInstall = ''
    wrapProgram "$out/bin/${meta.mainProgram}" --prefix PATH : ${
      lib.makeBinPath [
        util-linux
        skopeo
        gnutar
        ostree
        ima-evm-utils
      ]
    }
  '';

  meta = {
    description = "Rust library with higher level APIs on top of the core ostree API";
    homepage = "https://github.com/ostreedev/ostree-rs-ext";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ nickcao ];
    mainProgram = "ostree-ext-cli";
  };
}
