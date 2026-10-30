{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "runiq";
  version = "2.0.0-unstable-2024-08-19";

  src = fetchFromGitHub {
    owner = "whitfin";
    repo = "runiq";
    rev = "a642926f6ec09d4faeebebb563d4aed89e0d36fb";
    hash = "sha256-DWP0kbTjXlyUI/+bHgom9/XJ2XW/BJEU4xvIisPVug0=";
  };

  crateDeps = [
    "bytelines@2!"
    "bytesize@1"
    "clap@4:derive"
    "cli-table@0.4"
    "format_num@0.1"
    "growable-bloom-filter@2"
    "identity-hash@0.1"
    "jen@1"
    "strum@0.25"
    "strum_macros@0.25"
    "xxhash-rust@0.8:xxh64"
  ];

  meta = {
    description = "Efficient way to filter duplicate lines from input, à la uniq";
    mainProgram = "runiq";
    homepage = "https://github.com/whitfin/runiq";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
