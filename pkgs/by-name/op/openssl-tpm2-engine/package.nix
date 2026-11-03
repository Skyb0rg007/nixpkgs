{
  lib,
  fetchurl,
  stdenv,
  autoreconfHook,
  pkg-config,
  openssl,
  tpm2-tss,
  help2man,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "openssl-tpm2-engine";
  version = "4.4.3";
  src = fetchurl {
    url = "https://git.kernel.org/pub/scm/linux/kernel/git/jejb/openssl_tpm2_engine.git/snapshot/openssl_tpm2_engine-${finalAttrs.version}.tar.gz";
    hash = "sha256-HIIf3SO1e1gHUsrRM619dIgoXrgLA271cWj1lmwefpc=";
  };

  patches = [
    ./fix-tss-delete-uninitialized.patch
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-maybe-uninitialized";

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    help2man
  ];
  buildInputs = [
    openssl
    tpm2-tss
  ];

  configureFlags = [ "--with-enginesdir=${placeholder "out"}/lib/engines-3" ];
  makeFlags = [ "openssl_providerdir=$(out)/lib/ossl-modules" ];

  meta = {
    description = "OpenSSL TPM 2.0 Engine";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/jejb/openssl_tpm2_engine.git";
    license = lib.licenses.lgpl21Only;
    maintainers = [ lib.maintainers.skyesoss ];
    platforms = lib.platforms.linux;
  };
})
