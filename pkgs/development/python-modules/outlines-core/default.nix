{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # nativeBuildInputs
  cargo,
  pkg-config,
  rustPlatform,
  rustCrates,
  rustc,

  # buildInputs
  openssl,

  # build-system
  setuptools-rust,
  setuptools-scm,

  # dependencies
  interegular,
  jsonschema,

  # optional-dependencies
  datasets,
  numpy,
  pydantic,
  scipy,
  torch,
  transformers,

  # tests
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "outlines-core";
  version = "0.2.14";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "dottxt-ai";
    repo = "outlines-core";
    tag = finalAttrs.version;
    hash = "sha256-XmXD2tWG2277bC318Bn9RqeEE7j9VdauvWnBmFS8Lsk=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "bincode@2"
      "hf-hub@0.4!:rustls-tls,ureq"
      "once_cell@1"
      "pyo3@0.27:extension-module,generate-import-lib"
      "regex-automata@0.4"
      "regex@1"
      "rustc-hash@2"
      "serde-pyobject@0.8"
      "serde@1:derive"
      "serde_json@1:preserve_order"
      "thiserror@2"
      "tokenizers@0.22!:http,onig,rustls-tls"
    ];
  };

  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace-fail \
        'version = "0.0.0"' \
        'version = "${finalAttrs.version}"'

  '';

  nativeBuildInputs = [
    cargo
    pkg-config
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  buildInputs = [
    openssl
  ];

  build-system = [
    setuptools-rust
    setuptools-scm
  ];

  dependencies = [
    interegular
    jsonschema
  ];

  optional-dependencies = {
    tests = [
      datasets
      numpy
      pydantic
      scipy
      torch
      transformers
    ];
  };

  pythonImportsCheck = [ "outlines_core" ];

  preCheck = ''
    rm -rf outlines_core
  '';

  nativeCheckInputs = [
    pytestCheckHook
  ]
  ++ lib.concatAttrValues finalAttrs.passthru.optional-dependencies;

  disabledTests = [
    # Tests that need to download from Hugging Face Hub.
    "test_complex_serialization"
    "test_create_fsm_index_tokenizer"
    "test_from_pretrained"
    "test_pickling_from_pretrained_with_revision"
    "test_reduced_vocabulary_with_rare_tokens"
  ];

  disabledTestPaths = [
    # Downloads from Hugging Face Hub
    "tests/test_kernels.py"
  ];

  meta = {
    description = "Structured text generation (core)";
    homepage = "https://github.com/outlines-dev/outlines-core";
    changelog = "https://github.com/dottxt-ai/outlines-core/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ danieldk ];
  };
})
