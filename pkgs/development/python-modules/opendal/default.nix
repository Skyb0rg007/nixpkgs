{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  rustCrates,

  # tests
  pytest-asyncio,
  pytestCheckHook,
  python-dotenv,
}:
buildPythonPackage (finalAttrs: {
  pname = "opendal";
  version = "0.46.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "apache";
    repo = "opendal";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OQGpz6o4R0Yp+1vAgFtik/l7wvHwJNcB1BhZLk+BFPg=";
  };

  sourceRoot = "${finalAttrs.src.name}/bindings/python";

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "anyhow@1:std"
      "arbitrary@1:derive"
      "async-backtrace@0.2"
      "async-tls@0.13"
      "async-trait@0.1"
      "atomic_lib@0.34"
      "await-tree@0.1"
      "aws-config@1:behavior-version-latest"
      "aws-credential-types@1:hardcoded-credentials"
      "aws-sdk-s3@1"
      "backon@0.4"
      "base64@0.22"
      "bb8-postgres@0.8"
      "bb8@0.8"
      "bytes@1"
      "cacache@13!:mmap,tokio-runtime"
      "chrono@0.4!:clock,std"
      "compio@0.10:bytes,polling,runtime"
      "crc32c@0.6"
      "criterion@0.5:async,async_tokio"
      "dashmap@5"
      "dotenvy@0.15"
      "etcd-client@0.12:tls"
      "flagset@0.4"
      "foundationdb@0.8:embedded-fdb-include"
      "futures@0.3:std"
      "getrandom@0.2:js"
      "governor@0.6:std"
      "hdfs-native@0.6"
      "hdrs@0.3:async_file"
      "hmac@0.12"
      "hrana-client-proto@0.2"
      "http@1"
      "libfuzzer-sys@0.4"
      "libtest-mimic@0.6"
      "log@0.4"
      "madsim@0.2"
      "md-5@0.10"
      "metrics@0.20"
      "mini-moka@0.10"
      "minitrace@0.6:enable"
      "moka@0.12:future,sync"
      "mongodb@2:tokio-runtime"
      "mysql_async@0.32!:default-rustls"
      "once_cell@1"
      "openssh-sftp-client@0.14:openssh,tracing"
      "openssh@0.10"
      "opentelemetry@0.21:trace"
      "percent-encoding@2"
      "persy@1"
      "pretty_assertions@1"
      "probe@0.5"
      "prometheus-client@0.22"
      "prometheus@0.13:process"
      "prost@0.11"
      "pyo3-asyncio@0.20:tokio-runtime"
      "pyo3@0.20"
      "quick-xml@0.31:overlapped-lists,serialize"
      "r2d2@0.8"
      "rand@0.8"
      "redb@1"
      "redis@0.23:cluster-async,connection-manager,tokio-comp,tokio-native-tls-comp,tokio-rustls-comp"
      "reqsign@0.15!:reqwest_request,services-aliyun,services-aws,services-azblob,services-google,services-huaweicloud,services-tencent"
      "reqwest@0.12!:rustls-tls,stream"
      "rocksdb@0.21!"
      "rusqlite@0.29:bundled"
      "serde@1:derive"
      "serde_json@1"
      "sha1@0.10"
      "sha2@0.10"
      "size@0.4"
      "sled@0.34"
      "suppaftp@5!:async-rustls,async-secure,rustls"
      "surrealdb@1:protocol-http"
      "tikv-client@0.3!"
      "tokio-postgres@0.7"
      "tokio@1:fs,full,io-util,macros,rt-multi-thread,sync"
      "tracing-subscriber@0.3:env-filter,tracing-log"
      "tracing@0.1"
      "uuid@1:serde,v4"
      "wasm-bindgen-futures@0.4"
      "wasm-bindgen-test@0.3"
      "wasm-bindgen@0.2"
    ];
  };

  env = {
    PYO3_USE_ABI3_FORWARD_COMPATIBILITY = 1;
  };

  build-system = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  pythonImportsCheck = [ "opendal" ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
    python-dotenv
  ];

  meta = {
    description = "native Python binding for Apache OpenDAL";
    homepage = "https://github.com/apache/opendal/blob/main/bindings/python";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
})
