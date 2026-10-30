{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
  _experimental-update-script-combinators,
  rustCrates,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "sus-compiler";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "pc2";
    repo = "sus-compiler";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Nt7g5vj7TUMd3ugCm/LR8zT0pytyQHxJevD/6S0/6HQ=";
    fetchSubmodules = true;
    leaveDotGit = true;

    # Manual patch phase with replacement of Git details just before they're deleted.
    # Also ensures reproducibility by removing build time.
    postFetch = ''
      cp ${./build.rs.patch} build.rs.patch
      PATCH="$(realpath build.rs.patch)"

      cd "$out"

      GIT_HASH="$(git rev-parse HEAD)"
      GIT_DATE="$(git log --pretty=format:'%ad' --date=iso-strict HEAD -1)"

      substituteInPlace "$PATCH" \
        --replace-fail "@GIT_HASH@" "$GIT_HASH" \
        --replace-fail "@GIT_DATE@" "$GIT_DATE"
      patch -p1 < "$PATCH"

      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  crateDeps = [
    "ariadne@0.6"
    "cc@1"
    "chrono@0.4"
    "circular-buffer@1"
    "clap@4:derive,wrap_help"
    "colored@3"
    "crossbeam-channel@0.5"
    "dirs@6"
    "dtoa@1"
    "env_logger@0.11!:auto-color"
    "ibig@0.3!:std"
    "log@0.4"
    "lsp-server@0.7"
    "lsp-types@0.97"
    "ordered-float@5"
    "ouroboros@0.18"
    "pulldown-cmark@0.13!:html"
    "quote@1"
    "rand@0.10"
    "regex@1"
    "replace_with@0.1"
    "same-file@1"
    "serde@1"
    "serde_json@1"
    "syn@2"
    "tree-sitter@0.26"
    "typed-arena@2"
    "unescape@0.1"
  ];

  preBuild = ''
    export INSTALL_SUS_HOME="$out/share/sus-compiler";
    mkdir -p "$INSTALL_SUS_HOME"
  '';

  # Do the install version check only on stable versions of this compiler, when the build platform
  # is able to execute the binaries. Unstable versions report a "-devel" string instead of agreeing
  # with the nixpkgs version scheme.
  doInstallCheck =
    let
      isStable = !lib.elem "unstable" (lib.versions.splitVersion finalAttrs.version);
      canExecute = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
    in
    isStable && canExecute;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/sus_compiler";

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  meta = {
    description = "New Hardware Design Language that keeps you in the driver's seat";
    homepage = "https://github.com/pc2/sus-compiler";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ pbsds ];
    mainProgram = "sus_compiler";
  };
})
