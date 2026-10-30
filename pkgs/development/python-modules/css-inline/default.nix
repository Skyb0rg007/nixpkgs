{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  rustPlatform,
  rustCrates,

  # native darwin dependencies
  libiconv,

  # tests
  pytestCheckHook,
  hypothesis,

  # updater
  cargo,
  common-updater-scripts,
  gitMinimal,
  nix-update,
  python,
  writeShellApplication,
}:

buildPythonPackage rec {
  pname = "css-inline";
  version = "0.23.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Stranger6667";
    repo = "css-inline";
    rev = "python-v${version}";
    hash = "sha256-8K3LDhuvT++m+l1sauEdMPZqbJKNquwoyJR1/RukGP4=";
  };

  postPatch = ''
    cd crates/css-inline-python

    # don't rebuild std
    rm .cargo/config.toml
  '';

  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "assert_cmd@2"
      "async-trait@0.1"
      "built@0.8:cargo-lock,chrono"
      "cbindgen@0.29"
      "codspeed-criterion-compat@5"
      "criterion@0.8!"
      "cssparser@0.38"
      "dhat@0.3"
      "ext-php-rs@0.16"
      "futures-channel@0.3"
      "futures-util@0.3!:alloc"
      "getrandom@0.4:wasm_js"
      "hashbrown@0.17!:inline-more"
      "html5ever@0.40"
      "jni@0.22"
      "lexopt@0.3"
      "libc@0.2"
      "lru@0.18"
      "magnus@0.9"
      "memchr@2"
      "mimalloc@0.1:local_dynamic_tls"
      "napi-build@2"
      "napi-derive@3"
      "napi@3:async,napi4"
      "pico-args@0.5"
      "precomputed-hash@0.1"
      "pyo3-built@0.6"
      "pyo3@0.29:abi3-py310,extension-module"
      "rayon@1"
      "reqwest@0.13!:blocking,rustls-no-provider"
      "rustc-hash@2"
      "rustls@0.23!:ring,std,tls12"
      "selectors@0.41"
      "serde-wasm-bindgen@0.6"
      "serde@1:derive"
      "serde_json@1"
      "smallvec@1"
      "test-case@3"
      "tokio@1:macros,rt"
      "url@2"
      "wasm-bindgen-futures@0.4"
      "wasm-bindgen@0.2"
      "webpki-roots@1"
    ];
  };

  nativeBuildInputs = [
    rustPlatform.cargoRegistryHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  pythonImportsCheck = [ "css_inline" ];

  nativeCheckInputs = [
    hypothesis
    pytestCheckHook
  ];

  disabledTests = [
    # fails to connect to local server
    "test_cache"
    "test_remote_stylesheet"
  ]
  ++ lib.optionals (stdenv.hostPlatform.isDarwin) [
    # pyo3_runtime.PanicException: event loop thread panicked
    "test_invalid_href"
  ];

  passthru.updateScript = lib.getExe (writeShellApplication {
    name = "css-inline-updater";
    runtimeInputs = [
      cargo
      common-updater-scripts
      gitMinimal
      nix-update
      python
    ];
    text = ''
      TAG="$(list-git-tags --url=https://github.com/Stranger6667/css-inline | \
        grep "^python" | \
        sort --version-sort | \
        tail --lines 1)"
      VERSION="''${TAG//python-v/}"
      REPO_ROOT="$(git rev-parse --show-toplevel)"

      nix-update --version="$VERSION" python3Packages.css-inline
      "$REPO_ROOT/maintainers/scripts/rust-crates/rust-crates.py" deps -A python3Packages.css-inline --write
    '';
  });

  meta = {
    description = "Inline CSS into style attributes";
    homepage = "https://github.com/Stranger6667/css-inline";
    changelog = "https://github.com/Stranger6667/css-inline/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ hexa ];
  };
}
