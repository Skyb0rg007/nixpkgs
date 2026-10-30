{
  rustPlatform,
  lib,
}:

rustPlatform.buildRustPackage {
  pname = "make-initrd-ng";
  version = "0.1.0";

  src = ./make-initrd-ng;
  crateDeps = [
    "eyre@0.6"
    "goblin@0.5"
    "libc@0.2"
    "serde@1:derive"
    "serde_json@1"
  ];

  passthru.updateScript = ./make-initrd-ng/update.sh;

  meta = {
    description = "Tool for copying binaries and their dependencies";
    mainProgram = "make-initrd-ng";
    maintainers = with lib.maintainers; [
      elvishjerricco
      k900
    ];
    license = lib.licenses.mit;
  };
}
