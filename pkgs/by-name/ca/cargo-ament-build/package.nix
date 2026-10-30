{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cargo-ament-build";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "ros2-rust";
    repo = "cargo-ament-build";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5D0eB3GCQLgVYuYkHMTkboruiYSAaWy3qZjF/hVpRP0=";
  };

  crateDeps = [
    "anyhow@1"
    "cargo-manifest@0.2"
    "pico-args@0.4"
  ];

  nativeBuildInputs = [ pkg-config ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Cargo plugin for use with colcon workspaces";
    homepage = "https://github.com/ros2-rust/cargo-ament-build";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ guelakais ];
  };
})
