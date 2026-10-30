{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rot8";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "efernau";
    repo = "rot8";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9zjAi4yIpTqcJ338t0CVoOo0jlzrzRMfTH4ZRqBVAQg=";
  };

  crateDeps = [
    "clap@3"
    "glob@0.3"
    "regex@1"
    "serde@1:derive"
    "serde_json@1"
    "wayland-client@0.31"
    "wayland-protocols-wlr@0.2:client"
  ];

  meta = {
    description = "Screen rotation daemon for X11 and wlroots";
    homepage = "https://github.com/efernau/rot8";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.smona ];
    mainProgram = "rot8";
    platforms = lib.platforms.linux;
  };
})
