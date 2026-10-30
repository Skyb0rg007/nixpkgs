{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  libiconv,
  numpy,
  pytestCheckHook,
  rustPlatform,
  rustCrates,
  nix-update-script,
  _experimental-update-script-combinators,
}:

buildPythonPackage rec {
  pname = "blake3";
  version = "1.0.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "oconnor663";
    repo = "blake3-py";
    tag = version;
    hash = "sha256-gwPGSah9qzApDwsBNABRLPZGrpaO3WArHoK6Jj6WJzo=";
  };

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "blake3@1:mmap,neon,rayon"
      "hex@0.4"
      "pyo3@0.26:extension-module"
      "rayon@1"
    ];
  };

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  nativeBuildInputs = with rustPlatform; [
    cargoRegistryHook
    cargoSetupHook
    maturinBuildHook
  ];

  nativeCheckInputs = [
    pytestCheckHook
    numpy
  ];

  pythonImportsCheck = [ "blake3" ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "Python bindings for the BLAKE3 cryptographic hash function";
    homepage = "https://github.com/oconnor663/blake3-py";
    changelog = "https://github.com/oconnor663/blake3-py/releases/tag/${version}";
    license = with lib.licenses; [
      cc0
      asl20
    ];
    maintainers = with lib.maintainers; [ Luflosi ];
  };
}
