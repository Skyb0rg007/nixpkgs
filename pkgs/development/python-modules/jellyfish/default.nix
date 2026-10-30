{
  lib,
  buildPythonPackage,
  cargo,
  fetchFromGitHub,
  pytestCheckHook,
  rustc,
  rustPlatform,
  rustCrates,
  unicodecsv,
}:

buildPythonPackage rec {
  pname = "jellyfish";
  version = "1.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jamesturk";
    repo = "jellyfish";
    rev = "v${version}";
    hash = "sha256-jKz7FYzV66TUkJZfWDTy8GXmTZ6SU5jEdtkjYLDfS/8=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "ahash@0.8"
      "csv@1"
      "num-traits@0.2"
      "pyo3@0.26:generate-import-lib"
      "smallvec@1"
      "unicode-normalization@0.1"
      "unicode-segmentation@1"
    ];
  };

  build-system = [
    cargo
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  nativeCheckInputs = [
    pytestCheckHook
    unicodecsv
  ];

  pythonImportsCheck = [ "jellyfish" ];

  meta = {
    description = "Python library for doing approximate and phonetic matching of strings";
    homepage = "https://github.com/jamesturk/jellyfish";
    changelog = "https://github.com/jamesturk/jellyfish/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ koral ];
  };
}
