{
  buildPythonPackage,
  fetchFromGitHub,
  hypothesis,
  lib,
  pytestCheckHook,
  rustPlatform,
  rustCrates,
}:

buildPythonPackage rec {
  pname = "fastuuid";
  version = "0.14.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "fastuuid";
    repo = "fastuuid";
    tag = version;
    hash = "sha256-EXyd94NR4P+FLPxDCa3LmwfpIHwGduoaPL0qULqcj00=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "pyo3@0.26:extension-module"
      "rand@0.8"
      "uuid@1:v1,v3,v4,v5,v7"
    ];
  };

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  pythonImportsCheck = [ "fastuuid" ];

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  disabledTestPaths = [
    "tests/test_benchmarks.py"
  ];

  meta = {
    changelog = "https://github.com/fastuuid/fastuuid/releases/tag/${src.tag}";
    description = "CPython bindings to Rust's UUID library";
    homepage = "https://github.com/fastuuid/fastuuid";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.dotlambda ];
  };
}
