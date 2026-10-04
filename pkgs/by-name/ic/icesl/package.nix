{
  stdenv,
  lib,
  fetchzip,
  libglut,
  libxmu,
  libxi,
  libx11,
  libice,
  libGLU,
  libGL,
  libsm,
  libxext,
  glibc,
  openssl,
  lua5_1,
  glfw,
  libgccjit,
  dialog,
  makeWrapper,
}:
let
  lpath = lib.makeLibraryPath [
    libxmu
    libxi
    libx11
    libglut
    libice
    libGLU
    libGL
    libsm
    libxext
    glibc
    openssl
    # The binary and its bundled libluabind.so use the Lua 5.1 ABI.
    lua5_1
    glfw
    libgccjit
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation rec {
  pname = "iceSL";
  version = "2.5.3";

  # The download endpoint ignores `build` and always serves the latest
  # release, so the hashes change whenever upstream publishes a new version.
  src =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      fetchzip {
        url = "https://icesl.loria.fr/assets/other/download.php?build=${version}&os=amd64";
        extension = "zip";
        hash = "sha256-9LxHisSWFtfMXayKQtlSi2D3a6rSZjflaAhc4/oTb+U=";
      }
    else if stdenv.hostPlatform.system == "i686-linux" then
      fetchzip {
        url = "https://icesl.loria.fr/assets/other/download.php?build=${version}&os=i386";
        extension = "zip";
        hash = "sha256-n01gPYXvOwTVmf2m2YLgpsjiV0qcR+KpVDymRRXO9gc=";
      }
    else
      throw "Unsupported architecture";

  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    cp -r ./ $out
    # Use the nixpkgs Lua, but keep the bundled libluabind.so, since the
    # nixpkgs luabind only provides a static library.
    rm $out/bin/liblua.so
    mkdir $out/lib $out/oldbin
    mv $out/bin/libluabind.so $out/lib/libluabind.so
    mv $out/bin/IceSL-slicer $out/oldbin/IceSL-slicer
    runHook postInstall
  '';

  postInstall = ''
    patchelf --set-rpath "${lpath}" $out/lib/libluabind.so
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "$out/lib:${lpath}" \
      $out/oldbin/IceSL-slicer
    makeWrapper $out/oldbin/IceSL-slicer $out/bin/icesl --prefix PATH : ${dialog}/bin
  '';

  meta = {
    description = "GPU-accelerated procedural modeler and slicer for 3D printing";
    homepage = "https://icesl.loria.fr/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.inria-icesl;
    platforms = [
      "i686-linux"
      "x86_64-linux"
    ];
    maintainers = with lib.maintainers; [ mgttlinger ];
  };
}
