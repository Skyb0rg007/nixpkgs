{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  rustCrates,
  libiconv,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "graspologic-native";
  version = "1.2.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "graspologic-org";
    repo = "graspologic-native";
    tag = version;
    hash = "sha256-JIFg+JIxRKXgWLAGgOyKZTe2gXa8wZW5pEubTBLqwmQ=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "clap@4"
      "pyo3@0.24:abi3-py38,extension-module"
      "rand@0.8"
      "rand_xorshift@0.3"
    ];
  };

  buildAndTestSubdir = "packages/pyo3";

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
  ];

  buildInputs = [ libiconv ];

  build-system = [ rustPlatform.maturinBuildHook ];

  pythonImportsCheck = [ "graspologic_native" ];

  nativeCheckInputs = [ pytestCheckHook ];

  preCheck = ''
    cd packages/pyo3
  '';

  meta = {
    description = "Library of rust components to add additional capability to graspologic a python library for intelligently building networks and network embeddings, and for analyzing connected data";
    homepage = "https://github.com/graspologic-org/graspologic-native";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ natsukium ];
  };
}
