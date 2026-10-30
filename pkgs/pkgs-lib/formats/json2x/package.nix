{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "json2x";
  version = "0.1.0";
  __structuredAttrs = true;

  src = lib.sourceByRegex ./. [
    "^src(/.*)?$"
    ''^Cargo\.toml$''
  ];

  crateDeps = [
    "anyhow@1"
    "argh@0.1"
    "serde_json@1"
    "toml@1!:display,serde,std"
  ];
}
