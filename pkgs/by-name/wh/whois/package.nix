{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  perl,
  gettext,
  pkg-config,
  libidn2,
  libiconv,
}:

stdenv.mkDerivation rec {
  version = "5.6.3";
  pname = "whois";

  src = fetchFromGitHub {
    owner = "rfc1036";
    repo = "whois";
    rev = "v${version}";
    hash = "sha256-YJAd6s1kq2IJcR7qf7ljntLb5HgsaTH0wsoPKIMxHdg=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/macports/macports-ports/raw/93de4e9fc1e5e8427bf98f48209e783a5e8fab57/net/whois/files/implicit.patch";
      extraPrefix = "";
      hash = "sha256-ogVylQz//tpXxPNIWIHkhghvToU1z1D1FfnUBdZLyRY=";
    })
  ];

  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # whois fails to link libiconv on Darwin.
    NIX_LDFLAGS = "-liconv";
  };

  nativeBuildInputs = [
    perl
    gettext
    pkg-config
  ];
  buildInputs = [
    libidn2
    libiconv
  ];

  preConfigure = ''
    for i in Makefile po/Makefile; do
      substituteInPlace $i --replace "prefix = /usr" "prefix = $out"
    done
  '';

  makeFlags = [ "HAVE_ICONV=1" ];
  buildFlags = [ "whois" ];

  installTargets = [ "install-whois" ];

  meta = with lib; {
    description = "Intelligent WHOIS client from Debian";
    longDescription = ''
      This package provides a commandline client for the WHOIS (RFC 3912)
      protocol, which queries online servers for information such as contact
      details for domains and IP address assignments. It can intelligently
      select the appropriate WHOIS server for most queries.
    '';

    homepage = "https://packages.qa.debian.org/w/whois.html";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ fpletz ];
    platforms = platforms.unix;
    mainProgram = "whois";
  };
}
