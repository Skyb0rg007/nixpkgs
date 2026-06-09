{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  autoconf,
  automake,
  asciidoctor,
  installShellFiles,
}:
let
  hashes = builtins.fromJSON (builtins.readFile ./hashes.json);
  arch = if stdenv.hostPlatform.is64bit then "64" else "32";
  sys =
    if stdenv.hostPlatform.isx86_64 then
      "amd64-unix"
    else if stdenv.hostPlatform.isx86_32 then
      "x86-unix"
    else
      throw "Unsupported host platform ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "smlnj";
  version = "110.99.9";
  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "smlnj";
    repo = "legacy";
    tag = "v${finalAttrs.version}";
    hash = hashes.git;
  };

  bootFile = fetchurl {
    url = "https://smlnj.cs.uchicago.edu/dist/working/${finalAttrs.version}/boot.${sys}.tgz";
    hash = hashes."boot.${sys}.tgz";
  };

  nativeBuildInputs = [
    autoconf
    automake
    asciidoctor
    installShellFiles
  ];

  patchPhase = ''
    runHook prePatch

    ln -s $bootFile boot.${sys}.tgz

    substituteInPlace doc/configure.ac \
      --replace-warn 'AC_MSG_ERROR([documentation ' 'AC_MSG_WARN([documentation '

    runHook postPatch
  '';

  buildPhase = ''
    runHook preBuild

    substituteInPlace config/_arch-n-opsys \
      --replace-warn '6.*) ;; # 2022 --' '*.*) ;; # 2022 --'

    mkdir -pv $out
    INSTALLDIR=$out ./config/install.sh -default ${arch}

    pushd doc
    autoconf -Iconfig
    ./configure
    make -C src/man man
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    installManPage src/man/*.{1,7}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Standard ML of New Jersey, a compiler";
    homepage = "http://smlnj.org";
    license = lib.licenses.bsd3;
    platforms = [
      "x86_64-linux"
      "i686-linux"
      "x86_64-darwin"
    ];
    maintainers = with lib.maintainers; [
      skyesoss
      thoughtpolice
    ];
    mainProgram = "sml";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
})
