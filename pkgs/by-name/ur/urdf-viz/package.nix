{
  autoPatchelfHook,
  fetchFromGitHub,
  rustPlatform,
  stdenv,
  libGL,
  libxrandr,
  libxi,
  libxinerama,
  libxcursor,
  libx11,
  lib,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "urdf-viz";
  version = "0.46.1";

  # Fetch source from github
  src = fetchFromGitHub {
    owner = "openrr";
    repo = "urdf-viz";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zn/theIULmRePz2/uEsZpeVBhOtqJ0K2xXGb/t+agK4=";
  };

  crateDeps = [
    "assimp-sys@0.3"
    "assimp@0.3"
    "axum@0.7"
    "base64@0.22"
    "console_error_panic_hook@0.1"
    "crossbeam-queue@0.3"
    "ctrlc@3:termination"
    "getrandom@0.2:js"
    "js-sys@0.3"
    "k@0.32"
    "kiss3d@0.35"
    "mesh-loader@0.1"
    "rand@0.8"
    "serde@1:derive"
    "serde_json@1"
    "serde_qs@0.13"
    "structopt@0.3"
    "tempfile@3"
    "thiserror@2"
    "tokio@1:full"
    "tower-http@0.6:trace"
    "tracing-subscriber@0.3"
    "tracing-wasm@0.2"
    "tracing@0.1"
    "urdf-rs@0.9"
    "ureq@2"
    "url@2"
    "wasm-bindgen-futures@0.4"
    "wasm-bindgen@0.2"
    "web-sys@0.3:Blob,File,FileReader,Location,Response,Url,WebGlRenderingContext,Window"
  ];

  # Add all buildtime dependencies
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  # Add all runtime dependencies
  buildInputs = [
    stdenv.cc.cc.lib
    libGL
    libx11
    libxcursor
    libxrandr
    libxinerama
    libxi
  ];

  # Tell autopatchelf about the dependency that is linked through dlopen
  runtimeDependencies = [
    libGL
    libx11
    libxcursor
    libxrandr
    libxinerama
    libxi
  ];

  meta = {
    description = "Visualizer for URDF and XACRO files";
    homepage = "https://github.com/openrr/urdf-viz";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ hrrs01 ];
  };
})
