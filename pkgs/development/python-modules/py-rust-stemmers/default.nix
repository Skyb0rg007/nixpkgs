{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  rustCrates,

  # build-system
  cargo,
  rustc,
}:

buildPythonPackage rec {
  pname = "py-rust-stemmers";
  version = "0.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "qdrant";
    repo = "py-rust-stemmers";
    tag = "v${version}";
    hash = "sha256-WpTbS8XoOKhyyt1/YGagulopFKiqNI0ETkhjpiX0TL8=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "pyo3@0.18:extension-module"
      "rayon@1"
      "rust-stemmers@1"
    ];
  };

  build-system = [
    cargo
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  pythonImportsCheck = [ "py_rust_stemmers" ];

  meta = {
    description = "High-performance Python wrapper around the rust-stemmers library, utilizing the Snowball stemming algorithm";
    homepage = "https://github.com/qdrant/py-rust-stemmers";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
}
