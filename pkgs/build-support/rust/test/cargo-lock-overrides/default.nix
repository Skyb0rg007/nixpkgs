{ lib, rustPlatform }:

# Build like this from nixpkgs root:
# $ nix-build -A tests.cargoLockOverrides
let
  cargoLockOverrides = [
    {
      name = "itoa";
      version = "1.0.11";
      checksum = "49f1f14873335454500d59611f1cf4a4b0f786f9ac11f4312a78e4cf2566695b";
    }
  ];

  mkTest =
    name: args:
    rustPlatform.buildRustPackage (
      {
        pname = "cargo-lock-overrides-${name}";
        version = "0.1.0";

        inherit cargoLockOverrides;

        preBuild = ''
          grep -A1 'name = "itoa"' Cargo.lock | grep -qF 'version = "1.0.11"'
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          [ "$($out/bin/cargo-lock-overrides)" = 42 ]
        '';
      }
      // args
    );
in
{
  # Upstream Cargo.lock vendored with importCargoLock.
  cargoLock = mkTest "cargo-lock" {
    src = ./package;
    cargoLock.lockFile = ./package/Cargo.lock;
  };

  # Upstream Cargo.lock vendored with fetchCargoVendor.
  cargoHash = mkTest "cargo-hash" {
    src = ./package;
    cargoHash = "sha256-/MGgXMivBFe4iaA5W+D7yXTolCifjJpjMNZlu4/6tp4=";
  };

  # No upstream Cargo.lock: every dependency comes from the overrides.
  noLockfile = mkTest "no-lockfile" {
    src = ./package-no-lockfile;
  };
}
