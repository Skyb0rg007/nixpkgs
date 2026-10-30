{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rusty-bash";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "shellgei";
    repo = "rusty_bash";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WBV0wF7SKhOKAo+F1IImpPIgLvo9GYkqWrb2GluUtdA=";
  };

  crateDeps = [
    "faccess@0.2"
    "fluent-bundle@0.16"
    "io-streams@0.16"
    "locale_config@0.3"
    "nix@0.29:fs,hostname,process,resource,signal,term,time,user"
    "once_cell@1"
    "rand@0.9"
    "rand_chacha@0.9:os_rng"
    "regex@1"
    "rev_lines@0.3"
    "signal-hook@0.3"
    "sprintf@0.4"
    "termion@4"
    "time@0.3"
    "unic-langid@0.9"
    "unicode-width@0.1"
  ];

  passthru.shellPath = "/bin/sush";

  meta = {
    description = "Bash written with Rust, a.k.a. sushi shell";
    homepage = "https://github.com/shellgei/rusty_bash";
    license = lib.licenses.bsd3;
    mainProgram = "sush";
    maintainers = with lib.maintainers; [ aleksana ];
  };
})
