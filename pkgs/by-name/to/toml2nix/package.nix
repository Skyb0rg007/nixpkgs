{
  lib,
  rustPlatform,
  fetchCrate,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "toml2nix";
  version = "0.1.1";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-YhluLS4tFMibFrDzgIvNtfjM5dAqJQvygeZocKn3+Jg=";
  };

  crateDeps = [
    "toml@0.4"
  ];

  passthru.updateScript = nix-update-script { };
  meta = {
    description = "Tool to convert TOML files to Nix expressions";
    mainProgram = "toml2nix";
    homepage = "https://crates.io/crates/toml2nix";
    license = with lib.licenses; [
      mit # or
      asl20
    ];
    maintainers = [ lib.maintainers.progrm_jarvis ];
  };
})
