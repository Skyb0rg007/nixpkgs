{
  lib,
  stdenv,
  buildPythonPackage,
  fetchPypi,
  rustPlatform,
  rustCrates,
  cargo,
  rustc,
  setuptools,
  setuptools-rust,
  libiconv,
  requests,
  regex,
  blobfile,
}:
let
  pname = "tiktoken";
  version = "0.12.0";
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-sYun7isJOGOXj8sU90s3B83I1NTTg2hTzn7GB3ITmTE=";
  };
in
buildPythonPackage {
  inherit
    pname
    version
    src
    ;
  pyproject = true;

  build-system = [
    setuptools
    setuptools-rust
  ];

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "bstr@1"
      "fancy-regex@0.13"
      "pyo3@0.26!:extension-module,macros"
      "regex@1"
      "rustc-hash@2"
    ];
  };

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    setuptools-rust
    cargo
    rustc
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  dependencies = [
    requests
    regex
    blobfile
  ];

  # almost all tests require network access
  doCheck = false;

  pythonImportsCheck = [ "tiktoken" ];

  meta = {
    description = "Fast BPE tokeniser for use with OpenAI's models";
    homepage = "https://github.com/openai/tiktoken";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ happysalada ];
  };
}
