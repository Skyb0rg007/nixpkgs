{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  withNativeTls ? true,
  stdenv,
  aws-lc,
  oniguruma,
  openssl,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "xh";
  version = "0.26.3";

  src = fetchFromGitHub {
    owner = "ducaale";
    repo = "xh";
    tag = "v${finalAttrs.version}";
    hash = "sha256-dLQEz4Uy/7+wGGqjh0hFAVj1MK+2z6m+k+ZFwqUAbxE=";
  };

  crateDeps = [
    "anyhow@1"
    "assert_cmd@2"
    "base64@0.22"
    "brotli@8!:std"
    "chardetng@0.1"
    "clap@4:derive,string,wrap_help"
    "clap_complete@4"
    "clap_complete_nushell@4"
    "cookie_store@0.22:preserve_order"
    "digest_auth@0.3"
    "dirs@6"
    "encoding_rs@0.8"
    "encoding_rs_io@0.1"
    "env_logger@0.11!:auto-color,color,humantime"
    "flate2@1"
    "form_urlencoded@1"
    "http-body-util@0.1"
    "httpsig-hyper@0.0.24!:blocking,rsa-signature"
    "humantime@2"
    "hyper-util@0.1:server"
    "hyper@1:server"
    "indicatif@0.18"
    "indoc@2"
    "jsonxf@1"
    "log@0.4"
    "memchr@2"
    "mime2ext@0.1"
    "mime@0.3"
    "mime_guess@2"
    "network-interface@1"
    "os_display@0.1"
    "pem@3"
    "percent-encoding@2"
    "predicates@3"
    "quick-xml@0.38"
    "rand@0.8"
    "regex-lite@0.1"
    "reqwest@0.13!:blocking,cookies,form,http2,http3,json,multipart,native-tls,rustls,socks,system-proxy"
    "reqwest_cookie_store@0.10"
    "roff@0.2"
    "rpassword@7"
    "rustls@0.23!:logging"
    "ruzstd@0.7!:std"
    "sanitize-filename@0.6"
    "serde-transcode@1"
    "serde@1:derive"
    "serde_json@1:preserve_order"
    "serde_urlencoded@0.7"
    "sha2@0.10!"
    "supports-hyperlinks@3"
    "syntect@5!:dump-create,dump-load,parsing,plist-load,regex-onig,yaml-load"
    "tempfile@3"
    "termcolor@1"
    "time@0.3"
    "tokio@1:rt,sync,time"
    "tracing@0.1!:log"
    "unicode-width@0.1"
    "url@2"
  ];

  buildFeatures = lib.optional withNativeTls "native-tls";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    aws-lc
    oniguruma
  ]
  ++ lib.optionals (withNativeTls && !stdenv.hostPlatform.isDarwin) [ openssl ];

  env = {
    # Get openssl-sys to use pkg-config
    OPENSSL_NO_VENDOR = 1;
  };

  postInstall = ''
    installShellCompletion \
      completions/xh.{bash,fish} \
      --zsh completions/_xh

    installManPage doc/xh.1
    ln -s $out/share/man/man1/xh.1 $out/share/man/man1/xhs.1

    install -m444 -Dt $out/share/doc/xh README.md CHANGELOG.md

    ln -s $out/bin/xh $out/bin/xhs
  '';

  # Nix build happens in sandbox without internet connectivity
  # disable tests as some of them require internet due to nature of application
  doCheck = false;
  doInstallCheck = true;
  postInstallCheck = ''
    $out/bin/xh --help > /dev/null
    $out/bin/xhs --help > /dev/null
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Friendly and fast tool for sending HTTP requests";
    homepage = "https://github.com/ducaale/xh";
    changelog = "https://github.com/ducaale/xh/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      defelo
    ];
    mainProgram = "xh";
  };
})
