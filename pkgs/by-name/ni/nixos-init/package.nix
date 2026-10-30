{
  lib,
  rustPlatform,
  clippy,
  rustfmt,
  nixosTests,
}:

let
  cargoToml = fromTOML (builtins.readFile ./Cargo.toml);
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = cargoToml.package.name;
  inherit (cargoToml.package) version;

  __structuredAttrs = true;

  src = lib.sourceFilesBySuffices ./. [
    ".rs"
    ".toml"
    ".lock"
  ];

  crateDeps = [
    "anyhow@1"
    "bootspec@2"
    "env_logger@0.11!"
    "indoc@2"
    "log@0.4"
    "pathrs@0.2"
    "serde@1:derive"
    "serde_json@1"
    "tempfile@3"
    "xattr@1"
  ];

  stripAllList = [ "bin" ];

  passthru.tests = {
    lint-format = finalAttrs.finalPackage.overrideAttrs (
      _: previousAttrs: {
        pname = previousAttrs.pname + "-lint-format";
        nativeCheckInputs = (previousAttrs.nativeCheckInputs or [ ]) ++ [
          clippy
          rustfmt
        ];
        checkPhase = ''
          cargo clippy
          cargo fmt --check
        '';
      }
    );
    inherit (nixosTests) activation-nixos-init;
  };

  binaries = [
    "initrd-init"
    "find-etc"
    "clear-etc-opaque"
    "resolve-in-root"
    "env-generator"
  ];

  postInstall = ''
    for binary in "''${binaries[@]}"; do
      ln -s $out/bin/nixos-init $out/bin/$binary
    done
  '';

  meta = {
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ nikstur ];
    platforms = lib.platforms.linux;
  };
})
