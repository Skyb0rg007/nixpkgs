{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  rust-jemalloc-sys,
  testers,
  fd,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "fd";
  version = "10.5.0";

  src = fetchFromGitHub {
    owner = "sharkdp";
    repo = "fd";
    rev = "v${finalAttrs.version}";
    hash = "sha256-X3yrZUBieMO5bauUu2mskfvicLRdQcjbXouFTpz+0eQ=";
  };

  crateDeps = [
    "aho-corasick@1"
    "anyhow@1"
    "argmax@0.4"
    "clap@4:cargo,color,derive,suggestions,wrap_help"
    "clap_complete@4"
    "crossbeam-channel@0.5"
    "ctrlc@3"
    "diff@0.1"
    "etcetera@0.11"
    "faccess@0.2"
    "filetime@0.2"
    "globset@0.4"
    "ignore@0.4"
    "jiff@0.2"
    "libc@0.2"
    "lscolors@0.21!:nu-ansi-term"
    "nix@0.31!:hostname,signal,user"
    "normpath@1"
    "nu-ansi-term@0.50"
    "regex-syntax@0.8"
    "regex@1"
    "tempfile@3"
    "test-case@3"
    "tikv-jemallocator@0.7"
  ];

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = [ rust-jemalloc-sys ];

  # skip flaky test
  checkFlags = [
    "--skip=test_owner_current_group"
    # Fails if the filesystem performs UTF-8 validation (such as ZFS with utf8only=on)
    "--skip=test_exec_invalid_utf8"
    "--skip=test_invalid_utf8"
  ];

  postInstall = ''
    installManPage doc/fd.1
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd fd \
      --bash <($out/bin/fd --gen-completions bash) \
      --fish <($out/bin/fd --gen-completions fish)
    installShellCompletion --zsh contrib/completion/_fd
  '';

  passthru.tests.version = testers.testVersion {
    package = fd;
  };

  meta = {
    description = "Simple, fast and user-friendly alternative to find";
    longDescription = ''
      `fd` is a simple, fast and user-friendly alternative to `find`.

      While it does not seek to mirror all of `find`'s powerful functionality,
      it provides sensible (opinionated) defaults for 80% of the use cases.
    '';
    homepage = "https://github.com/sharkdp/fd";
    changelog = "https://github.com/sharkdp/fd/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = with lib.licenses; [
      asl20 # or
      mit
    ];
    maintainers = with lib.maintainers; [
      dywedir
      ma27
      zowoq
      matthiasbeyer
    ];
    mainProgram = "fd";
  };
})
