{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libpulseaudio,
  openssl,
  stdenv,
  alsa-lib,
  nix-update-script,
  _experimental-update-script-combinators,
  rustCrates,
  versionCheckHook,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "camilladsp";
  version = "4.1.3";

  src = fetchFromGitHub {
    owner = "HEnquist";
    repo = "camilladsp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/OnD607xSPXM4AjVOZjaZQJpo7Q847Z8mq6elHmEwAU=";
  };

  crateDeps = [
    "alsa-sys@0.3"
    "alsa@0.9"
    "asio-sys@0.2"
    "audio_thread_priority@0.33!"
    "audioadapter-buffers@2"
    "audioadapter-sample@2!"
    "audioadapter@2!"
    "chrono@0.4"
    "clap@4:cargo"
    "coreaudio-rs@0.13"
    "cpal@0.16:jack"
    "criterion@0.6"
    "crossbeam-channel@0.5"
    "dispatch@0.2"
    "flexi_logger@0.30:async,colors"
    "git-version@0.3"
    "json-patch@4"
    "libc@0.2"
    "libpulse-binding@2"
    "libpulse-simple-binding@2"
    "log@0.4"
    "native-tls@0.2"
    "nix@0.30:poll,signal"
    "num-complex@0.4"
    "num-traits@0.2"
    "objc2-audio-toolbox@0.3"
    "objc2-core-audio-types@0.3"
    "objc2-core-audio@0.3"
    "objc2-core-foundation@0.3"
    "parking_lot@0.12:hardware-lock-elision"
    "pipewire@0.9"
    "rand@0.9!:os_rng,small_rng,std"
    "rand_distr@0.5"
    "rayon@1"
    "realfft@3"
    "ringbuf@0.4"
    "rubato@1"
    "serde@1:derive"
    "serde_json@1"
    "serde_with@3"
    "signal-hook@0.3"
    "tungstenite@0.26:native-tls"
    "wasapi@0.22"
    "windows@0.62:Win32_Foundation,Win32_System_Threading"
    "yaml_serde@0.10"
    "zbus@5"
  ];

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    libpulseaudio
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ alsa-lib ];

  passthru.updateScript = _experimental-update-script-combinators.sequence [
    (nix-update-script { })
    (rustCrates.updateScript { })
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Flexible cross-platform IIR and FIR engine for crossovers, room correction etc";
    homepage = "https://github.com/HEnquist/camilladsp";
    changelog = "https://github.com/HEnquist/camilladsp/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [
      paepcke
      stepbrobd
    ];
    mainProgram = "camilladsp";
  };
})
