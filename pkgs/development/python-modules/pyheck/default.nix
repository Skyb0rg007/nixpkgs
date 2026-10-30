{
  lib,
  buildPythonPackage,
  cargo,
  fetchFromGitHub,
  libiconv,
  poetry-core,
  pytestCheckHook,
  rustc,
  rustPlatform,
  rustCrates,
  stdenv,
}:

buildPythonPackage rec {
  pname = "pyheck";
  version = "0.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "kevinheavey";
    repo = "pyheck";
    tag = version;
    hash = "sha256-mfXkrCbBaJ0da+taKJvfyU5NS43tYJWqtTUXiCLVoGQ=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "heck@0.4:unicode"
      "pyo3@0.15:abi3-py37,extension-module"
      "rayon@1"
    ];
  };

  nativeBuildInputs = [
    cargo
    poetry-core
    rustc
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "pyheck" ];

  meta = {
    description = "Python bindings for heck, the Rust case conversion library";
    homepage = "https://github.com/kevinheavey/pyheck";
    changelog = "https://github.com/kevinheavey/pyheck/blob/${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
}
