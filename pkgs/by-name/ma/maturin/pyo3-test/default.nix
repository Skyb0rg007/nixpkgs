{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  rustPlatform,
  rustCrates,

  # These are always passed as an override or as a callPackage option.
  nativeBuildInputs,
  buildAndTestSubdir,
  pyproject,
  preConfigure,
}:

buildPythonPackage (finalAttrs: {
  pname = "word-count";
  # https://github.com/PyO3/pyo3/blob/v0.28.2/examples/word-count/pyproject.toml
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "PyO3";
    repo = "pyo3";
    tag = "v0.28.2";
    hash = "sha256-Jg+eni7I0jVUFViWbgj5F094ksvyuvF4mdgGzh0PMaQ=";
  };

  cargoRoot = buildAndTestSubdir;
  cargoDeps = rustCrates.mkRegistry {
    crateDeps = [
      "anyhow@1"
      "bigdecimal@0.4"
      "bytes@1"
      "chrono-tz@0.10!"
      "chrono@0.4!:clock"
      "either@1"
      "eyre@0.6"
      "hashbrown@0.16!"
      "heck@0.5"
      "iana-time-zone@0.1:fallback"
      "indexmap@2"
      "inventory@0.3"
      "jiff@0.2"
      "libc@0.2"
      "lock_api@0.4:arc_lock"
      "num-bigint@0.4"
      "num-complex@0.4"
      "num-rational@0.4"
      "num-traits@0.2"
      "once_cell@1"
      "ordered-float@5!"
      "parking_lot@0.12:arc_lock"
      "portable-atomic@1"
      "proc-macro2@1!"
      "python3-dll-a@0.2"
      "quote@1"
      "rayon@1"
      "rust_decimal@1!"
      "serde@1"
      "smallvec@1"
      "syn@2:clone-impls,derive,extra-traits,full,parsing,printing,visit-mut"
      "target-lexicon@0.13"
      "time@0.3!"
      "uuid@1"
    ];
  };

  inherit
    buildAndTestSubdir
    pyproject
    nativeBuildInputs
    preConfigure
    ;

  pythonImportsCheck = [ "word_count" ];

  meta = {
    description = "PyO3 word count example";
    homepage = "https://github.com/PyO3/pyo3";
    license = lib.licenses.asl20;
    maintainers = [ ];
  };
})
