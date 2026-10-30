{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  _experimental-update-script-combinators,
  rustCrates,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "termbg";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "dalance";
    repo = "termbg";
    tag = "v${finalAttrs.version}";
    hash = "sha256-JVRl0BCuU6duFcFZr3Rs8dgS+ikwCKe5/z3JgjAikiw=";
  };

  crateDeps = [
    "crossterm@0.28"
    "either@1"
    "log@0.4"
    "mockall@0.13"
    "scopeguard@1"
    "simplelog@0.12"
    "thiserror@2"
    "winapi@0.3:impl-default,processenv,winbase,wincon"
  ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "Program for terminal background color detection";
    homepage = "https://github.com/dalance/termbg";
    changelog = "https://github.com/dalance/termbg/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [ pinpox ];
    mainProgram = "termbg";
  };
})
