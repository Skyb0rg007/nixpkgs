{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  rustPlatform,
  installShellFiles,
  pkg-config,
  withPCRE2 ? true,
  pcre2,
  writableTmpDirAsHomeHook,
}:

let
  canRunRg = stdenv.hostPlatform.emulatorAvailable buildPackages;
  rg = "${stdenv.hostPlatform.emulator buildPackages} $out/bin/rg${stdenv.hostPlatform.extensions.executable}";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ripgrep";
  version = "15.2.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    tag = finalAttrs.version;
    hash = "sha256-BsSIbZwB6s8i3dDTRYJ1EdVbJmiO0oxcLu6qiYlPkOI=";
  };

  crateDeps = [
    "aho-corasick@1"
    "anyhow@1"
    "arbitrary@1:derive"
    "bstr@1:std"
    "crossbeam-channel@0.5"
    "crossbeam-deque@0.8"
    "encoding_rs@0.8"
    "encoding_rs_io@0.1"
    "glob@0.3"
    "lexopt@0.3"
    "libc@0.2"
    "log@0.4"
    "memchr@2"
    "memmap2@0.9"
    "pcre2@0.2"
    "regex-automata@0.4:dfa-onepass,hybrid,meta,nfa,perf,std,syntax"
    "regex-syntax@0.8:std"
    "regex@1"
    "same-file@1"
    "serde@1"
    "serde_derive@1"
    "serde_json@1"
    "termcolor@1"
    "textwrap@0.16!"
    "tikv-jemallocator@0.7"
    "walkdir@2"
    "winapi-util@0.1"
  ];

  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook # required for wine when cross-compiling to Windows
  ]
  ++ lib.optional withPCRE2 pkg-config;
  buildInputs = lib.optional withPCRE2 pcre2;

  buildFeatures = lib.optional withPCRE2 "pcre2";

  postFixup = lib.optionalString canRunRg ''
    ${rg} --generate man > rg.1
    installManPage rg.1

    installShellCompletion --cmd rg \
      --bash <(${rg} --generate complete-bash) \
      --fish <(${rg} --generate complete-fish) \
      --zsh <(${rg} --generate complete-zsh)
  '';

  doInstallCheck = true;
  installCheckPhase = lib.optionalString canRunRg (
    ''
      file="$(mktemp)"
      echo "abc\nbcd\ncde" > "$file"
      ${rg} -N 'bcd' "$file"
      ${rg} -N 'cd' "$file"
    ''
    + lib.optionalString withPCRE2 ''
      echo '(a(aa)aa)' | ${rg} -P '\((a*|(?R))*\)'
    ''
  );

  meta = {
    description = "Utility that combines the usability of The Silver Searcher with the raw speed of grep";
    homepage = "https://github.com/BurntSushi/ripgrep";
    changelog = "https://github.com/BurntSushi/ripgrep/releases/tag/${finalAttrs.version}";
    license = with lib.licenses; [
      unlicense # or
      mit
    ];
    maintainers = with lib.maintainers; [
      globin
      ma27
      zowoq
    ];
    mainProgram = "rg";
    platforms = lib.platforms.all;
  };
})
