{
  buildPackages,
  clippy,
  dbus,
  lib,
  nixosTests,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "switch-to-configuration";
  version = "0.1.0";

  src = builtins.filterSource (name: _: !(lib.hasSuffix ".nix" name)) ./.;

  crateDeps = [
    "anyhow@1"
    "dbus-codegen@0.12"
    "dbus@0.9"
    "glob@0.3"
    "libsystemd@0.7"
    "log@0.4"
    "nix@0.31:fs,signal"
    "regex@1"
    "rust-ini@0.21:inline-comment"
    "syslog@7"
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  env.SYSTEMD_DBUS_INTERFACE_DIR = "${buildPackages.systemd}/share/dbus-1/interfaces";

  nativeCheckInputs = [
    clippy
  ];

  preCheck = ''
    echo "Running clippy..."
    cargo clippy -- -Dwarnings
  '';

  passthru.tests = {
    inherit (nixosTests)
      switchTest
      switchTest-basics
      switchTest-units
      switchTest-user
      activation-template-dropin
      ;
  };

  meta = {
    description = "NixOS switch-to-configuration program";
    mainProgram = "switch-to-configuration";
    maintainers = with lib.maintainers; [ jmbaur ];
    license = lib.licenses.mit;
  };
}
