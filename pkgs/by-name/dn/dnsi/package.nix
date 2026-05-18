{
  lib,
  fetchCrate,
  rustPlatform,
  installShellFiles,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dnsi";
  version = "0.2.0";
  __structuredAttrs = true;

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-t/i+pRRUH2wjVzol2ghZHZ9b4R2YB9qsW/l2Q+itoVE=";
  };

  nativeBuildInputs = [ installShellFiles ];

  cargoHash = "sha256-uIW7EDL2ulg6qDizjw5iHtc5HqyEZDBoXJxWHZOmoqo=";

  postInstall = ''
    installManPage doc/*.1
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Command line tool to investigate the Domain Name System";
    mainProgram = "dnsi";
    homepage = "https://nlnetlabs.nl/projects/domain/dnsi/";
    license = lib.licenses.bsd3;
    maintainers = [ lib.maintainers.skyesoss ];
  };
})
