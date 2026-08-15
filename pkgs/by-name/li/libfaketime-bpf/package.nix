{
  lib,
  fetchFromGitHub,
  stdenv,
  pkg-config,
  libseccomp,
  procps,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libfaketime-bpf";
  version = "0.1.0";
  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "Skyb0rg007";
    repo = "libfaketime-bpf";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cxmzQNmr0PKrHGstwJe2GkHyuDB3B9SbKsSIsJoAsKY=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libseccomp ];
  nativeCheckInputs = [ procps ];
  installFlags = [ "PREFIX=$(out)" ];
  doCheck = true;

  meta = {
    description = "faketime without LD_PRELOAD, using seccomp-bpf";
    homepage = "https://github.com/Skyb0rg007/libfaketime-bpf/";
    license = lib.license.agpl3Plus;
    mainProgram = "faketime-bpf";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
