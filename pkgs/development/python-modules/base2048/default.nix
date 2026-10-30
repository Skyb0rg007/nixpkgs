{
  lib,
  stdenv,
  buildPythonPackage,
  cargo,
  fetchFromGitHub,
  frelatage,
  libiconv,
  pytestCheckHook,
  rustc,
  rustPlatform,
  rustCrates,
}:

buildPythonPackage rec {
  pname = "base2048";
  version = "0.1.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ionite34";
    repo = "base2048";
    tag = "v${version}";
    hash = "sha256-OXlfycJB1IrW2Zq0xPDGjjwCdRTWtX/ixPGWcd+YjAg=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "hashbrown@0.12"
      "lazy_static@1"
      "pyo3@0.17:abi3-py37,extension-module"
      "rstest@0.15"
    ];
  };

  nativeBuildInputs = [
    cargo
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
    rustc
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ libiconv ];

  optional-dependencies = {
    fuzz = [ frelatage ];
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "base2048" ];

  meta = {
    description = "Binary encoding with base-2048 in Python with Rust";
    homepage = "https://github.com/ionite34/base2048";
    changelog = "https://github.com/ionite34/base2048/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ fab ];
  };
}
