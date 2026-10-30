{
  lib,
  buildPythonPackage,
  aiodns,
  aiohttp,
  cargo,
  cryptography,
  defusedxml,
  emoji,
  fetchFromCodeberg,
  gnupg,
  pyasn1,
  pyasn1-modules,
  pytestCheckHook,
  replaceVars,
  rustc,
  rustPlatform,
  rustCrates,
  setuptools,
  setuptools-rust,
  setuptools-scm,
}:

buildPythonPackage (finalAttrs: {
  pname = "slixmpp";
  version = "1.17.0";
  pyproject = true;

  src = fetchFromCodeberg {
    owner = "poezio";
    repo = "slixmpp";
    tag = "slix-${finalAttrs.version}";
    hash = "sha256-1jCKaUwWuIxTQGA0WkQMpB3xWW8XEAfAlyrqoTFIhVY=";
  };

  patches = [
    (replaceVars ./hardcode-gnupg-path.patch {
      inherit gnupg;
    })
  ];

  build-system = [
    setuptools
    setuptools-rust
    setuptools-scm
  ];

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
  ];

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "jid@0.12"
      "pyo3@0.29:extension-module"
    ];
  };

  dependencies = [
    aiodns
    pyasn1
    pyasn1-modules
  ];

  optional-dependencies = {
    xep-0363 = [ aiohttp ];
    xep-0444-compliance = [ emoji ];
    xep-0454 = [ cryptography ];
    safer-xml-parsing = [ defusedxml ];
  };

  nativeCheckInputs = [
    pytestCheckHook
  ]
  ++ lib.concatAttrValues finalAttrs.passthru.optional-dependencies;

  disabledTestPaths = [
    # Exclude integration tests
    "itests/"
    # Exclude live tests
    "tests/live_test.py"
  ];

  pythonImportsCheck = [ "slixmpp" ];

  meta = {
    description = "Python library for XMPP";
    homepage = "https://slixmpp.readthedocs.io/";
    changelog = "https://codeberg.org/poezio/slixmpp/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      fab
      haansn08
    ];
  };
})
