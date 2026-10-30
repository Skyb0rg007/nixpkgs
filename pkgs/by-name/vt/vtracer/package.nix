{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vtracer";
  version = "0.6.15";

  src = fetchFromGitHub {
    owner = "visioncortex";
    repo = "vtracer";
    tag = finalAttrs.version;
    hash = "sha256-A575QnbituecxIX0mm7bOMC+V8jeWB4j3A2iWgDKBts=";
  };

  crateDeps = [
    "cfg-if@0.1"
    "clap@2"
    "console_error_panic_hook@0.1"
    "console_log@0.2:color"
    "fastrand@2:js"
    "image@0.23"
    "pyo3@0.19"
    "serde@1:derive"
    "serde_json@1"
    "visioncortex@0.8"
    "wasm-bindgen@0.2:serde-serialize"
    "web-sys@0.3:CanvasRenderingContext2d,Document,HtmlCanvasElement,HtmlElement,ImageData,Window,console"
  ];

  meta = {
    description = "Raster to Vector Graphics Converter";
    homepage = "https://github.com/visioncortex/vtracer";
    changelog = "https://github.com/visioncortex/vtracer/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ sandptel ];
    mainProgram = "vtracer";
  };
})
