{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  libxft,
  ncurses,
  ninja,
  readline,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wordgrinder";
  version = "0.8";

  src = fetchFromGitHub {
    repo = "wordgrinder";
    owner = "davidgiven";
    rev = finalAttrs.version;
    sha256 = "124d1bnn2aqs6ik8pdazzni6a0583prz9lfdjrbwyb97ipqga9pm";
  };

  makeFlags = [
    "PREFIX=$(out)"
    "OBJDIR=$TMP/wg-build"
  ];

  preBuild = lib.optionalString stdenv.hostPlatform.isLinux ''
    makeFlagsArray+=('XFT_PACKAGE=--cflags={} --libs={-lX11 -lXft}')
  '';

  dontUseNinjaBuild = true;
  dontUseNinjaInstall = true;
  dontConfigure = true;

  nativeBuildInputs = [
    pkg-config
    ninja
  ];

  buildInputs = [
    ncurses
    readline
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libxft
  ];

  # To be able to find <Xft.h>
  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isLinux "-I${libxft.dev}/include/X11";

  meta = {
    description = "Text-based word processor";
    homepage = "https://cowlark.com/wordgrinder";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ matthiasbeyer ];
    platforms = with lib.platforms; linux ++ darwin;
  };
})
