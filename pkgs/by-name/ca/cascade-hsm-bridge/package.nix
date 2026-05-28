{
  lib,
  pkg-config,
  openssl,
  fetchFromGitHub,
  rustPlatform,
  installShellFiles,
  nix-update-script,
  softhsm,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cascade-hsm-bridge";
  version = "0.2.0-beta2";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "NLnetLabs";
    repo = "cascade-hsm-bridge";
    tag = "v${finalAttrs.version}";
    hash = "sha256-tGin5XJBITtONVR3iSoGp/lZC4adBr+GzXPiO7AIICA=";
  };

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  doCheck = false;

  cargoHash = "sha256-PXp8D10hIhU9qPfY6UZizKhBa6mxRy5JCnETaiJ9A2Y=";

  postInstall = ''
    installManPage doc/manual/build/man/*.{1,5}
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=unstable" ];
  };

  meta = {
    description = "KMIP to PKCS#11 translator used by the Cascade project";
    longDescription = ''
      cascade-hsm-bridge is a Rust application that accepts KMIP requests,
      converts them to PKCS#11 format and executes them against a loaded
      PKCS#11 library. It was created for use with the Cascade project.

      The use case for which this application is primarily being developed is
      to enable Cascade to make use of a Hardware Security Module (HSM) via a
      PKCS#11 interface without having to load an untrusted 3rd party PKCS#11
      library into its process.

      This is particularly important for a Rust application as the PKCS#11
      interface exposes the application to code that is likely not protected by
      the guarantees provided by the Rust compiler, as the PKCS#11 is a foreign
      function interface beyond which the Rust compiler cannot see.
    '';
    homepage = "https://cascade.docs.nlnetlabs.nl/";
    changelog = "https://github.com/NLnetLabs/cascade-hsm-bridge/releases";
    mainProgram = "cascade-hsm-bridge";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.skyesoss ];
  };
})
