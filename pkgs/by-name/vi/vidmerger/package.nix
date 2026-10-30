{
  lib,
  ffmpeg,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  _experimental-update-script-combinators,
  rustCrates,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vidmerger";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "TGotwig";
    repo = "vidmerger";
    tag = finalAttrs.version;
    hash = "sha256-N/iX0EN5R4oG4XHhpd/VaihrEHv5uT+grAJ6/KfSORE=";
  };

  crateDeps = [
    "assert_cmd@2"
    "clap@4:derive"
    "crossterm@0.29"
    "ctor@0.4"
    "k9@0.12"
    "lazy_static@1"
    "nanoid@0.4"
    "path-slash@0.2"
    "regex@1"
    "stdext@0.3"
    "system_shutdown@4"
    "term-painter@0.4"
    "ureq@3"
    "which@7"
  ];

  # Running cargo test -- . fails because it expects to have two mp4 files so that it can test the video merging functionalities
  doCheck = false;

  buildInputs = [
    ffmpeg
  ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "Merge video & audio files via CLI";
    homepage = "https://github.com/TGotwig/vidmerger";
    license = with lib.licenses; [
      mit
      commons-clause
    ];
    maintainers = with lib.maintainers; [ ByteSudoer ];
    mainProgram = "vidmerger";
  };
})
