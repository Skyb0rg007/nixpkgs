{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  python3,
  level-zero,
  spdlog,
  intel-llvm,
  nix-update-script,

  # Trace the SYCL runtime through XPTI. Only needs XPTI from intel-llvm, not
  # the SYCL compiler; without it, PTI only reports Level Zero activity.
  syclSupport ? true,
}:

let
  # PTI only uses the ITT headers. Upstream pulls them in through FetchContent.
  ittapi-src = fetchFromGitHub {
    owner = "intel";
    repo = "ittapi";
    tag = "v3.26.8";
    hash = "sha256-cxqwclXuS2LBB0Vc81fDVpfGUve/1tWKnugppBwBhGc=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "intel-pti";
  version = "1.2.0";

  __structuredAttrs = true;
  strictDeps = true;

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "intel";
    repo = "pti-gpu";
    tag = "pti-${finalAttrs.version}";
    hash = "sha256-KLbonC/ckL702QLdPdSDho8Ixl/EqF/R2cwz8oEo0pI=";
  };

  sourceRoot = "${finalAttrs.src.name}/sdk";

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
  ];

  buildInputs = [
    level-zero
    spdlog
  ]
  ++ lib.optionals syclSupport [
    intel-llvm.unwrapped
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" false)
    (lib.cmakeBool "PTI_BUILD_TESTING" false)
    (lib.cmakeBool "PTI_BUILD_SAMPLES" false)
    (lib.cmakeBool "PTI_BUILD_URGEMM" false)
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_ITTAPI" "${ittapi-src}")
    (lib.cmakeFeature "PTI_COMMIT_HASH" finalAttrs.src.tag)
    (lib.cmakeFeature "PTI_INSTALL_CMAKE_DIR" "${placeholder "dev"}/lib/cmake/pti")
    # Use the SYCL runtime API ids shipped in PTI's public headers rather than
    # regenerating them from whatever unified-runtime happens to be around.
    (lib.cmakeBool "CMAKE_DISABLE_FIND_PACKAGE_unified-runtime" true)
  ];

  # The tests need an Intel GPU.
  doCheck = false;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "pti-([0-9.]+)"
    ];
  };

  meta = {
    description = "Intel Profiling Tools Interfaces (PTI) SDK for GPU tracing and profiling";
    homepage = "https://intel.github.io/pti-gpu/";
    changelog = "https://github.com/intel/pti-gpu/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.skyesoss ];
    platforms = [ "x86_64-linux" ];
  };
})
