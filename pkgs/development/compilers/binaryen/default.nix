{
  lib,
  stdenv,
  cmake,
  python3,
  fetchFromGitHub,
  emscripten,
  gtest,
  lit,
  nodejs,
  filecheck,
}:
let
  testsuite = fetchFromGitHub {
    owner = "WebAssembly";
    repo = "testsuite";
    rev = "e05365077e13a1d86ffe77acfb1a835b7aa78422";
    hash = "sha256-yvZ5AZTPUA6nsD3xpFC0VLthiu2CxVto66RTXBXXeJM=";
  };
in
stdenv.mkDerivation rec {
  pname = "binaryen";
  version = "120_b";

  src = fetchFromGitHub {
    owner = "WebAssembly";
    repo = "binaryen";
    rev = "version_${version}";
    hash = "sha256-gdqjsAQp4NTHROAf6i44GjkbtNyLPQZ153k3veK7eYs=";
  };

  nativeBuildInputs = [
    cmake
    python3
  ];

  strictDeps = true;

  preConfigure = ''
    if [ $doCheck -eq 1 ]; then
      sed -i '/googletest/d' third_party/CMakeLists.txt
      rmdir test/spec/testsuite
      ln -s ${testsuite} test/spec/testsuite
    else
      cmakeFlagsArray=($cmakeFlagsArray -DBUILD_TESTS=0)
    fi
  '';

  nativeCheckInputs = [
    lit
    nodejs
    filecheck
  ];
  checkInputs = [
    gtest
  ];
  checkPhase = ''
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/lib python3 ../check.py $tests
  '';

  tests = [
    "version"
    "wasm-opt"
    "wasm-dis"
    "crash"
    "dylink"
    "ctor-eval"
    "wasm-metadce"
    "wasm-reduce"
    "spec"
    "lld"
    "wasm2js"
    "validator"
    "example"
    "unit"
    # "binaryenjs" "binaryenjs_wasm" # not building this
    "lit"
    "gtest"
  ];
  doCheck = stdenv.hostPlatform.isLinux;

  meta = with lib; {
    homepage = "https://github.com/WebAssembly/binaryen";
    description = "Compiler infrastructure and toolchain library for WebAssembly, in C++";
    platforms = platforms.all;
    maintainers = with maintainers; [
      asppsa
      willcohen
    ];
    license = licenses.asl20;
  };
  passthru.tests = {
    inherit emscripten;
  };
}
