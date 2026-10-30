{
  cxx-rs,
  fetchFromGitHub,
  lib,
  rustPlatform,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cxx-rs";
  version = "1.0.194";

  src = fetchFromGitHub {
    owner = "dtolnay";
    repo = "cxx";
    tag = finalAttrs.version;
    sha256 = "sha256-PIeF9VuyJOIs1x02YETKIP0+nCG3RZXLMJdFNlgAFzo=";
  };

  crateDeps = [
    "cc@1:parallel"
    "clap@4!:error-context,help,std,suggestions,usage"
    "codespan-reporting@0.13"
    "cxx-build@1"
    "cxx@1"
    "foldhash@0.2!:std"
    "indexmap@2"
    "indoc@2"
    "link-cplusplus@1"
    "pkg-config@0.3"
    "prettyplease@0.2"
    "proc-macro2@1:span-locations"
    "quote@1"
    "rustversion@1"
    "scratch@1"
    "serde@1:derive"
    "syn@2:clone-impls,full,parsing,printing"
    "target-triple@1"
    "tempfile@3"
    "trybuild@1:diff"
  ];

  cargoBuildFlags = [
    "--workspace"
    "--exclude=demo"
  ];

  postBuild = ''
    cargo doc --release
  '';

  cargoTestFlags = [ "--workspace" ];

  outputs = [
    "out"
    "doc"
    "dev"
  ];

  postInstall = ''
    mkdir -p $doc
    cp -r ./target/doc/* $doc

    mkdir -p $dev/include/rust
    install -D -m 0644 ./include/cxx.h $dev/include/rust
  '';

  passthru.tests.version = testers.testVersion {
    package = cxx-rs;
    command = "cxxbridge --version";
  };

  meta = {
    description = "Safe FFI between Rust and C++";
    mainProgram = "cxxbridge";
    homepage = "https://github.com/dtolnay/cxx";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ centromere ];
  };
})
