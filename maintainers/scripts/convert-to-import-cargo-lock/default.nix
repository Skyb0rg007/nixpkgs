with import ../../../. { };

rustPlatform.buildRustPackage {
  name = "convert-to-import-cargo-lock";

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      name: type:
      let
        name' = baseNameOf name;
      in
      name' != "default.nix" && name' != "target";
  };

  crateDeps = [
    "anyhow@1"
    "basic-toml@0.1"
    "serde@1:derive"
    "serde_json@1"
  ];
}
