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
  version = "0.1.0-beta8";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "NLnetLabs";
    repo = "cascade";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ElZsyriN/STm3zUaLA5iwi8ED5NmfEFHmvzm17I1ukA=";
  };

  nativeBuildInputs = [
    pkg-config
    git
    installShellFiles
  ];
  buildInputs = [
    openssl
  ];

  cargoHash = "sha256-aMRvvJd5m8yDoylz1vdi0746u8Jx/9vfzhl3L0VHoiQ=";

  postInstall = ''
    installManPage doc/manual/build/man/*.{1,5}
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=unstable" ];
  };

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
