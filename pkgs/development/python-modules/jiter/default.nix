{
  lib,
  buildPythonPackage,
  rustPlatform,
  rustCrates,
  fetchFromGitHub,
  libiconv,
  dirty-equals,
  pytestCheckHook,
  nix-update-script,
  _experimental-update-script-combinators,
}:

buildPythonPackage rec {
  pname = "jiter";
  version = "0.12.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pydantic";
    repo = "jiter";
    tag = "v${version}";
    hash = "sha256-d87RUXKEmZXxVQZnAvjwRKSP6F3Z+kXxg/LdY2l9B+k=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "ahash@0.8"
      "bitvec@1"
      "codspeed-criterion-compat@2"
      "indexmap@2"
      "lexical-parse-float@1:format"
      "libfuzzer-sys@0.4"
      "num-bigint@0.4"
      "num-traits@0.2"
      "paste@1"
      "pyo3-build-config@0.27"
      "pyo3@0.27:auto-initialize,generate-import-lib,num-bigint"
      "serde@1"
      "serde_json@1:arbitrary_precision,float_roundtrip,preserve_order"
      "smallvec@1"
    ];
  };

  buildAndTestSubdir = "crates/jiter-python";

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
  ];

  build-system = [ rustPlatform.maturinBuildHook ];

  buildInputs = [ libiconv ];

  pythonImportsCheck = [ "jiter" ];

  nativeCheckInputs = [
    dirty-equals
    pytestCheckHook
  ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "Fast iterable JSON parser";
    homepage = "https://github.com/pydantic/jiter/";
    changelog = "https://github.com/pydantic/jiter/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ natsukium ];
  };
}
