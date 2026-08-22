{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  swig,
  testers,
  nix-update-script,
  linuxHeaders,
  python3Packages,
  withPython ? false,
  withCapAudit ? false,
  bpftools,
  audit,
  libbpf,
  clang,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libcap-ng";
  version = "0.9.5";

  src = fetchFromGitHub {
    owner = "stevegrubb";
    repo = "libcap-ng";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HYVbPoFSlkmNuL5EsEQVAekE4fwidgL+biTBBS1BdPM=";
  };

  # NEWS needs to exist or else the build fails
  postPatch = ''
    touch NEWS
    substituteInPlace utils/captest.c \
      --replace-fail /usr/bin/captest $out/bin/captest
  '';

  strictDeps = true;
  __structuredAttrs = true;
  enableParallelBuilding = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    swig
  ]
  ++ lib.optionals withPython [
    python3Packages.python # m4
  ]
  ++ lib.optionals withCapAudit [
    bpftools
    clang
  ];

  buildInputs =
    lib.optionals withPython [
      python3Packages.python
    ]
    ++ lib.optionals withCapAudit [
      audit
      libbpf
    ];

  nativeCheckInputs = lib.optionals withPython [
    python3Packages.pythonImportsCheckHook
  ];

  outputs = [
    "out"
    "dev"
    "man"
  ];

  configureFlags = [
    (lib.withFeature withPython "python")
    (lib.withFeatureAs withPython "capability_header" "${linuxHeaders}/include/linux/capability.h")
    # "--with-capability_header='${linuxHeaders}/include/linux/capability.h'" # required to link bindings
    (lib.enableFeature withCapAudit "cap-audit")
    (lib.withFeatureAs withCapAudit "vmlinux-h" "provided")
    (lib.withFeatureAs withCapAudit "vmlinux-h-path" ./vmlinux.h)
  ];

  passthru = {
    updateScript = nix-update-script { };
    tests = {
      pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
      python = python3Packages.libcap_ng;
    };
  };

  # assumption: build machine runs linux kernel 5.0 or newer
  # see https://github.com/stevegrubb/libcap-ng?tab=readme-ov-file#note-to-distributions
  doCheck = true;

  pythonImportsCheck = [
    "capng"
  ];

  preCheck = ''
    patchShebangs bindings/test bindings/python3/test
  '';

  meta = {
    broken =
      # m4 python include script fails if cpu bit depth is different across build/host architectures
      withPython && (stdenv.hostPlatform.parsed.cpu.bits != stdenv.buildPlatform.parsed.cpu.bits);
    changelog = "https://people.redhat.com/sgrubb/libcap-ng/ChangeLog";
    description = "Library for working with POSIX capabilities";
    homepage = "https://people.redhat.com/sgrubb/libcap-ng/";
    pkgConfigModules = [ "libcap-ng" ];
    platforms = lib.platforms.linux;
    license = lib.licenses.lgpl21;
    maintainers = with lib.maintainers; [ grimmauld ];
    teams = [ lib.teams.security-review ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "libcap-ng_project" finalAttrs.version;
  };
})
