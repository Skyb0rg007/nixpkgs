{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
  nix-update-script,
  git,
  installShellFiles,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cascade";
  version = "0.1.0-beta3";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "NLnetLabs";
    repo = "cascade";
    tag = "v${finalAttrs.version}";
    hash = "sha256-G60z+Uho/IgPQ/+KEbae3aoODdG+1RopT8dFzAKhO2E=";
  };

  nativeBuildInputs = [
    pkg-config
    git
    installShellFiles
  ];
  buildInputs = [
    openssl
  ];

  cargoHash = "sha256-EqTMhWC6OLQdR0xWfOL+vksfpXdjL67xCfRlk0vf4m4=";

  postInstall = ''
    installManPage doc/manual/build/man/*.{1,5}
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Standalone DNSSEC signer";
    longDescription = ''
      Cascade is a purpose-built, standalone DNSSEC signer, shaped by the
      real-world demands of TLD operators.
      Written from the ground up in Rust for safety, stability and speed,
      Cascade will be the next generation DNSSEC signing solution.
    '';
    homepage = "https://cascade.docs.nlnetlabs.nl/";
    changelog = "https://github.com/NLnetLabs/cascade/releases";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.skyesoss ];
  };
})
