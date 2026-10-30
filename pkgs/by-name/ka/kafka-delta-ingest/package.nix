{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
  perl,
  rdkafka,
  # these are features in the cargo, where one may be disabled to reduce the final size
  enableS3 ? true,
  enableAzure ? true,
}:

assert lib.assertMsg (enableS3 || enableAzure) "Either S3 or azure support needs to be enabled";
rustPlatform.buildRustPackage {
  pname = "kafka-delta-ingest";
  version = "0-unstable-2025-05-05";

  src = fetchFromGitHub {
    owner = "delta-io";
    repo = "kafka-delta-ingest";
    rev = "da9c932be3a98649da74ed91f5e1593bece65e89";
    hash = "sha256-omeIuvi2OEU4jBWbE/EEM/nqHr25sy2+5Q9qsXzZh8E=";
  };

  nativeBuildInputs = [
    pkg-config
    perl
  ];

  buildFeatures = [
    "dynamic-linking"
  ]
  ++ lib.optional enableS3 "s3"
  ++ lib.optional enableAzure "azure";

  buildInputs = [
    openssl
    rdkafka
  ];

  # #![deny(warnings)] breaks the build when newer rustc emits new lints.
  env.RUSTFLAGS = "--cap-lints warn";

  crateDeps = [
    "anyhow@1"
    "apache-avro@0.17"
    "async-trait@0.1"
    "azure_core@0.18"
    "azure_storage@0.18"
    "azure_storage_blobs@0.18"
    "base64@0.13"
    "bytes@1"
    "chrono@0.4"
    "clap@4:color,env"
    "dashmap@6"
    "deltalake-aws@0.9"
    "deltalake-azure@0.9"
    "deltalake-core@0.26:datafusion,json"
    "dipstick@0.9"
    "dynamodb_lock@0.6"
    "env_logger@0.11"
    "flate2@1"
    "futures@0.3"
    "jmespatch@0.3:sync"
    "lazy_static@1"
    "log@0.4"
    "maplit@1"
    "rdkafka@0.37:dynamic-linking,ssl"
    "rusoto_core@0.47!:rustls"
    "rusoto_credential@0.47"
    "rusoto_s3@0.47!:rustls"
    "schema_registry_converter@3:avro,easy,json"
    "sentry@0.23"
    "serde@1:derive"
    "serde_json@1"
    "serial_test@4"
    "strum@0.27"
    "strum_macros@0.27"
    "tempfile@3"
    "thiserror@1"
    "time@0.3"
    "tokio-stream@0.1:fs"
    "tokio-util@0.6"
    "tokio@1:full"
    "url@2"
    "utime@0.3"
    "uuid@0.8:serde,v4"
  ];

  # many tests seem to require a running kafka instance
  doCheck = false;

  meta = {
    broken = stdenv.hostPlatform.isDarwin;
    description = "Highly efficient daemon for streaming data from Kafka into Delta Lake";
    mainProgram = "kafka-delta-ingest";
    homepage = "https://github.com/delta-io/kafka-delta-ingest";
    license = lib.licenses.asl20;
    maintainers = [ ];
  };
}
