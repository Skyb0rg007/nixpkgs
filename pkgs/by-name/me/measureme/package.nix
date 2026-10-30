{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "measureme";
  version = "12.0.3";

  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = "measureme";
    rev = finalAttrs.version;
    hash = "sha256-pejgWzHtpEBylFzG1+/8zTV7qR6gf6UuTmuH9GNPoD0=";
  };

  crateDeps = [
    "clap@4:derive"
    "decodeme@10"
    "flate2@1"
    "inferno@0.11!"
    "log@0.4"
    "measureme@10"
    "memchr@2"
    "memmap2@0.2"
    "parking_lot@0.12"
    "perf-event-open-sys@3"
    "prettytable-rs@0.10"
    "rustc-hash@1"
    "serde@1:derive"
    "serde_json@1"
    "smallvec@1"
  ];

  # __cpuid is safe in newer Rust; suppress lint until upstream fixes it
  env.RUSTFLAGS = "-A unused-unsafe";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Support crate for rustc's self-profiling feature";
    homepage = "https://github.com/rust-lang/measureme";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.t4ccer ];
  };
})
