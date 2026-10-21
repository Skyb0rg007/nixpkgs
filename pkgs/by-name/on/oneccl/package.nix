{
  lib,
  intelLlvmStdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  hwloc,
  level-zero,
  libfabric,
  mpich,
  pmix,
  nix-update-script,
}:
intelLlvmStdenv.mkDerivation (finalAttrs: {
  pname = "oneccl";
  version = "2022.1.2";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "uxlfoundation";
    repo = "oneCCL";
    tag = finalAttrs.version;
    hash = "sha256-CYRsDj50wKUFQzw2fFViYz/bHO5zkpvZGy4QVv0Czls=";
  };

  patches = [
    # Fix matching GPUs to their sysman devices when an NPU driver is installed,
    # which made every communicator creation fail.
    ./fix-sysman-driver-lookup.patch
  ];

  postPatch = ''
    # Prebuilt Intel MPI, libfabric, hwloc and ITT binaries; use our own instead.
    rm -r deps/libccl/deps/{mpi,ofi,hwloc/lib,itt/lib64}

    substituteInPlace CMakeLists.txt \
      --replace-fail " -march=native" "" \
      --replace-fail '"-ffast-math" "-flto"' '"-ffast-math"' \
      --replace-fail "ProcessorCount(NPROC)" 'set(NPROC $ENV{NIX_BUILD_CORES})' \
      --replace-fail '"-DONECCL_ENABLE_MPI=''${ONECCL_ENABLE_MPI}"' \
                     '"-DONECCL_ENABLE_MPI=''${ONECCL_ENABLE_MPI}" ''${NIX_LIBCCL_CMAKE_ARGS}' \
      --replace-fail "add_subdirectory(examples)" "" \
      --replace-fail "add_subdirectory(tests)" ""

    # googletest is only needed for the tests
    substituteInPlace deps/CMakeLists.txt \
      --replace-fail "require_submodule(googletest CMakeLists.txt)" "" \
      --replace-fail "add_subdirectory(googletest EXCLUDE_FROM_ALL)" ""

    substituteInPlace deps/libccl/CMakeLists.txt \
      --replace-fail '"''${DEPS_DIR}/hwloc/include/"' '"${lib.getDev hwloc}/include/"' \
      --replace-fail "-Wno-unused-parameter -Werror" "-Wno-unused-parameter"

    # The SYCL backend only switches to C++17 after checking for -fsycl,
    # which intel-llvm rejects below C++17.
    substituteInPlace deps/libccl/CMakeLists.txt \
      --replace-fail "set(CMAKE_CXX_STANDARD 11)" "set(CMAKE_CXX_STANDARD 17)"

    substituteInPlace deps/libccl/src/CMakeLists.txt \
      --replace-fail "\''${HWLOC_LIB_DIR}/libhwloc.a" "hwloc" \
      --replace-fail "\''${ITT_LIB_DIR}/libittnotify.a" "" \
      --replace-fail $'if (ENABLE_MPI)\n    file(GLOB mpi_bins' $'if (FALSE)\n    file(GLOB mpi_bins'
  '';

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    hwloc
    level-zero
    libfabric
    mpich
    pmix
  ];

  cmakeFlags = [
    (lib.cmakeBool "ONECCL_BUILD_TESTS" false)
    (lib.cmakeBool "ONECCL_LIBCCL_BUILD_FT" false)
    (lib.cmakeBool "ONECCL_LIBCCL_BUILD_EXAMPLES" false)
    (lib.cmakeBool "ONECCL_LIBCCL_BUILD_REG_TESTS" false)
    # ITT (ittapi) is not packaged
    (lib.cmakeBool "ONECCL_ENABLE_ITT" false)
    # Hardening is handled by the cc-wrapper; this also drops -Werror
    (lib.cmakeFeature "ONECCL_FORTIFY_SOURCE" "0")
    # libccl is built twice (GPU and CPU-only) as CMake external projects
    (lib.cmakeFeature "NIX_LIBCCL_CMAKE_ARGS" (
      lib.concatStringsSep ";" [
        (lib.cmakeFeature "MPI_DIR" "${lib.getDev mpich}")
        (lib.cmakeFeature "LIBFABRIC_DIR" "${lib.getDev libfabric}")
        (lib.cmakeBool "ENABLE_ITT" false)
        # ENABLE_UMF=OFF doesn't compile. UMF is only dlopen()ed when CCL_UMF_ENABLE=1,
        # which won't work as unified-memory-framework doesn't build libumf.so.
      ]
    ))
  ];

  postInstall = ''
    # 200+ MiB static archive of the GPU libccl, unused by consumers
    rm $out/lib/libccl.a
    # Empty ExternalProject byproduct directories
    rmdir $out/libccl{,_cpu}/src $out/libccl{,_cpu}

    for pc in $out/lib/pkgconfig/ccl{,_cpu}.pc; do
      substituteInPlace "$pc" --replace-fail 'prefix=''${pcfiledir}/../../' "prefix=$out"
    done
  '';

  postFixup = ''
    # libccl.so.2 dlopen()s its plugins (libccl_legacy.so etc.) by name
    patchelf --add-rpath $out/lib $out/lib/libccl.so.2.0

    # libccl dlopen()s these by soname
    for lib in $out/lib/libccl.so.1.* $out/lib/ccl/cpu/lib/libccl.so.1.*; do
      patchelf --add-rpath ${
        lib.makeLibraryPath [
          level-zero
          libfabric
          mpich
          pmix
        ]
      } "$lib"
    done
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "oneAPI Collective Communications Library (oneCCL)";
    homepage = "https://github.com/uxlfoundation/oneCCL";
    changelog = "https://github.com/uxlfoundation/oneCCL/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ skyesoss ];
    platforms = [ "x86_64-linux" ];
  };
})
