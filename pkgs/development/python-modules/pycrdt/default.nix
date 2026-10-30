{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # nativeBuildInputs
  rustPlatform,
  rustCrates,

  # dependencies
  anyio,

  # tests
  objsize,
  pydantic,
  pytestCheckHook,
  trio,

  nix-update-script,
  _experimental-update-script-combinators,
}:

buildPythonPackage (finalAttrs: {
  pname = "pycrdt";
  version = "0.14.10";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "y-crdt";
    repo = "pycrdt";
    tag = finalAttrs.version;
    hash = "sha256-tkxjRq0hBJeP3+0/QyTn1P92HJVx9aw9KmIrzIe3T9Y=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "futures-task@0.3"
      "pyo3@0.30"
      "serde@1"
      "serde_json@1"
      "yrs@0.28:sync"
    ];
  };

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  dependencies = [ anyio ];

  pythonImportsCheck = [ "pycrdt" ];

  nativeCheckInputs = [
    anyio
    objsize
    pydantic
    pytestCheckHook
    trio
  ];

  pytestFlags = [
    "-Wignore::pytest.PytestUnknownMarkWarning" # requires unpackaged pytest-mypy-testing
  ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "CRDTs based on Yrs";
    homepage = "https://github.com/jupyter-server/pycrdt";
    changelog = "https://github.com/jupyter-server/pycrdt/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    teams = [ lib.teams.jupyter ];
  };
})
