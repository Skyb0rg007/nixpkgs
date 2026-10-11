{
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
let
  version = "0.24.1";
  commitHash = "4b5790d3c013056bea48eeb94f35ff4e2263407f";
  commitDate = "2026-10-05T00:00:00+0000";
in
buildGoModule (finalAttrs: {
  pname = "pvtr";
  inherit version;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "privateerproj";
    repo = "pvtr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Nrz0/Np6J8MIp6Lt4+w8NTStBD8LSaY0N8bBpbEBRSM=";
  };

  vendorHash = "sha256-l5I3jTSxBs77PclotRMDeWFp/Ff6NBpV6eeEt0YUiyk=";

  ldflags = [
    "-s"
    "-w"
    "-X"
    "main.GitCommitHash=${commitHash}"
    "-X"
    "main.BuiltAt=${commitDate}"
    "-X"
    "main.Version=${finalAttrs.version}"
  ];

  meta = {
    description = "Framework for security & compliance evaluations";
    homepage = "https://github.com/privateerproj/pvtr";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.skyesoss ];
  };
})
