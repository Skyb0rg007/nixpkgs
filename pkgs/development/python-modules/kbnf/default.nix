{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  rustCrates,
  numpy,
  triton,
  torch,
}:

buildPythonPackage rec {
  pname = "kbnf";
  version = "0.4.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Dan-wanna-M";
    repo = "kbnf";
    rev = "v${version}-python";
    hash = "sha256-reefuqS0eExky9qtxBTqwxnZgK8AWFfkrN+VL/lFLyg=";
  };

  # Manually unarchived from tarball from pypi

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "ahash@0.8:serde"
      "criterion@0.5"
      "displaydoc@0.2"
      "fixedbitset-stack@0.5"
      "general-sam@1"
      "getrandom@0.2:js"
      "insta@1"
      "jaggedarray@0.2"
      "js-sys@0.3"
      "kbnf-regex-automata@0.4"
      "kbnf-syntax@0.5"
      "log@0.4"
      "mimalloc@0.1"
      "nom@7"
      "nonmax@0.5"
      "num@0.4"
      "pyo3-log@0.12"
      "pyo3@0.24:abi3-py37,extension-module,multiple-pymethods"
      "serde-wasm-bindgen@0.6"
      "serde@1"
      "serde_json@1"
      "string-interner@0.18"
      "strum@0.26:derive"
      "thiserror@2"
      "tinyvec@1"
      "wasm-bindgen@0.2"
    ];
  };

  build-system = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  dependencies = [
    numpy
  ];

  optional-dependencies = {
    efficient_logits_mask = [
      triton
    ];
    torch = [
      torch
    ];
  };

  pythonImportsCheck = [
    "kbnf"
  ];

  meta = {
    description = "Fast constrained decoding engine based on context free grammar";
    homepage = "https://pypi.org/project/kbnf/";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = with lib.maintainers; [ BatteredBunny ];
  };
}
