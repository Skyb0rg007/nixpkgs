{
  lib,
  bzip2,
  fetchFromGitHub,
  pkg-config,
  rustPlatform,
  zstd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "fim-rs";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "Achiefs";
    repo = "fim";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xJzglrNB5rqaRQTgRFIl8/AXjeDwFPykIE5LJwJ3cX4=";
  };

  crateDeps = [
    "ctrlc@3!:termination"
    "flate2@1"
    "futures@0.3"
    "gethostname@1!"
    "hex@0.4"
    "itertools@0.14"
    "log-panics@2:with-backtrace"
    "log@0.4!"
    "notify@6"
    "regex@1!:std"
    "reqwest@0.12!:json,rustls-tls,stream"
    "rusqlite@0.32:bundled"
    "serde_json@1!"
    "serial_test@4"
    "sha2@0.10:asm"
    "sha3@0.10!"
    "simplelog@0.12"
    "tar@0.4"
    "time@0.3!"
    "tokio-test@0.4"
    "tokio-util@0.7!:codec"
    "tokio@1!:macros,rt,rt-multi-thread"
    "uuid@1!:v4"
    "walkdir@2"
    "windows-service@0.7"
    "yaml-rust@0.4"
    "zip@4"
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    bzip2
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  # Relies on /var/lib/fim existing, but /var is not available under nix-build.
  doCheck = false;

  meta = {
    description = "Host-based file integrity monitoring tool";
    longDescription = ''
      FIM is a File Integrity Monitoring tool that tracks any event over your
      files. It is capable of keeping historical data of your files. It checks
      the filesystem changes in the background.

      FIM is the fastest alternative to other software like Ossec, which
      performs file integrity monitoring. It could integrate with other
      security tools. The produced data can be ingested and analyzed with
      tools like ElasticSearch/OpenSearch.
    '';
    homepage = "https://github.com/Achiefs/fim";
    changelog = "https://github.com/Achiefs/fim/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ fab ];
    mainProgram = "fim";
  };
})
