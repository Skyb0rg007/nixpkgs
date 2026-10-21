{
  lib,
  addDriverRunpath,
  cmake,
  fetchFromGitHub,
  intel-compute-runtime,
  openvino,
  stdenv,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "level-zero";
  version = "1.32.0";

  src = fetchFromGitHub {
    owner = "oneapi-src";
    repo = "level-zero";
    tag = "v${finalAttrs.version}";
    hash = "sha256-u8q8VOuJKUCFNJ8aLR/BrVx9lU5vD+hwkHRmy77vFe8=";
  };

  # The loader only probes for drivers in LD_LIBRARY_PATH and a fixed list of
  # FHS directories before dlopen-ing them, ignoring its own RUNPATH.
  postPatch = ''
    substituteInPlace source/loader/linux/driver_discovery_lin.cpp \
      --replace-fail \
        '  paths.push_back("/lib");' \
        '  paths.push_back("${addDriverRunpath.driverLink}/lib");
      paths.push_back("/lib");'
  '';

  nativeBuildInputs = [
    cmake
    addDriverRunpath
  ];

  postFixup = ''
    addDriverRunpath $out/lib/libze_loader.so
  '';

  setupHook = ./setup-hook.sh;

  passthru = {
    tests = {
      inherit intel-compute-runtime openvino;
    };
    updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };
  };

  meta = {
    description = "oneAPI Level Zero Specification Headers and Loader";
    homepage = "https://github.com/oneapi-src/level-zero";
    changelog = "https://github.com/oneapi-src/level-zero/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.ziguana ];
  };
})
