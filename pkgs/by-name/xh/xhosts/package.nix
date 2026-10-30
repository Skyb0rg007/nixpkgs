{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "nss-xhosts";
  version = "0-unstable-2023-12-30";

  src = fetchFromGitHub {
    owner = "dvob";
    repo = "nss-xhosts";
    rev = "78658cc24abb2546936f2b298a27d4abdf629186";
    hash = "sha256-saK9CxN4Ek1QBlPOydzEFei1217gPe5MZrUaUHh80hI=";
  };

  crateDeps = [
    "lazy_static@1"
    "libc@0.2"
    "libnss@0.4"
    "paste@1"
  ];

  postFixup = "mv $out/lib/*.so $out/lib/libnss_xhosts.so.2";

  meta = {
    description = "NSS Module which supports wildcards";
    homepage = "https://github.com/dvob/nss-xhosts";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ matthewcroughan ];
    mainProgram = "nss-xhosts";
    platforms = lib.platforms.linux;
  };
}
