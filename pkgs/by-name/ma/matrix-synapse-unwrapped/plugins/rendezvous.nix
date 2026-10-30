{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  rustCrates,
  setuptools-rust,
}:

buildPythonPackage rec {
  pname = "matrix-http-rendezvous-synapse";
  version = "0.1.12";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "rust-http-rendezvous-server";
    rev = "v${version}";
    sha256 = "sha256-minwa+7HLTNSBtBtt5pnoHsFnNEh834nsVw80+FIQi8=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "anyhow@1"
      "axum@0.6:headers"
      "base64ct@1:std"
      "bytes@1"
      "bytesize@1:serde"
      "clap@4:derive,env"
      "headers@0.3"
      "http-body@0.4"
      "humantime-serde@1"
      "humantime@2"
      "hyper@0.14:server"
      "mime@0.3"
      "pyo3-asyncio@0.18"
      "pyo3-log@0.8"
      "pyo3-matrix-synapse-module@0.1"
      "pyo3@0.18:abi3-py37,anyhow,extension-module"
      "serde@1:derive"
      "sha2@0.10"
      "time@0.3"
      "tokio@1:macros,rt,rt-multi-thread,signal,sync,test-util,time"
      "tower-http@0.3:cors,limit,set-header"
      "tower@0.4:util"
      "tracing-subscriber@0.3"
      "tracing@0.1:log,log-always"
      "ulid@1:serde"
    ];
  };

  nativeBuildInputs = [
    setuptools-rust
  ]
  ++ (with rustPlatform; [
    cargoRegistryHook
    cargoSetupHook
    maturinBuildHook
  ]);

  buildAndTestSubdir = "synapse";

  pythonImportsCheck = [ "matrix_http_rendezvous_synapse" ];

  meta = {
    description = "Implementation of MSC3886: Simple rendezvous capability";
    homepage = "https://github.com/matrix-org/rust-http-rendezvous-server";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ SuperSandro2000 ];
  };
}
