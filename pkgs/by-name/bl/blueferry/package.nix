{
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  systemd,
  bluez,
  gobject-introspection,
  hyprland,
  wrapGAppsHook4,
  libadwaita,
  kdePackages,
  quickshell,
  makeDesktopItem,
  copyDesktopItems,
  withGtk ? true,
  withQt ? false,
  withQuickshell ? false,
}:
let
  anyDesktopItem = withGtk || withQt || withQuickshell;
  sitePackages = "$out/${python3Packages.python.sitePackages}";
in
python3Packages.buildPythonPackage (finalAttrs: {
  pname = "blueferry";
  version = "0.7.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "erikwb";
    repo = "blueferry";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xQpqZ4exzHy0zs/XWUta18u4zqfNC0ioBfEW36GbA5w=";
  };

  build-system = [
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    gobject-introspection
  ]
  ++ lib.optional withGtk wrapGAppsHook4
  ++ lib.optional withQt kdePackages.wrapQtAppsHook
  ++ lib.optional anyDesktopItem copyDesktopItems;

  desktopItems =
    lib.optional withGtk (makeDesktopItem {
      name = "io.weirdware.BlueFerry.Gtk";
      desktopName = "BlueFerry";
      genericName = "iPhone Bluetooth Bridge";
      comment = "Your iPhone's messages and notifications on the Linux desktop";
      exec = "blueferry-gtk";
      icon = "io.weirdware.BlueFerry";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
        "GTK"
      ];
      keywords = [
        "iPhone"
        "SMS"
        "iMessage"
        "Bluetooth"
        "Notifications"
        "Messages"
      ];
      startupNotify = true;
    })
    ++ lib.optional withQt (makeDesktopItem {
      name = "io.weirdware.BlueFerry.Qt";
      desktopName = "BlueFerry";
      genericName = "iPhone Bluetooth Bridge";
      comment = "Your iPhone's messages and notifications on Plasma";
      exec = "blueferry-qt";
      icon = "io.weirdware.BlueFerry";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
        "Qt"
        "KDE"
      ];
      keywords = [
        "iPhone"
        "SMS"
        "iMessage"
        "Bluetooth"
        "Notifications"
        "Messages"
      ];
      startupNotify = true;
    })
    ++ lib.optional withQuickshell (makeDesktopItem {
      name = "io.weirdware.BlueFerry.Quickshell";
      desktopName = "BlueFerry (Quickshell)";
      genericName = "iPhone Bluetooth Bridge";
      comment = "Your iPhone's messages in a lightweight Quickshell panel";
      exec = "blueferry-quickshell";
      icon = "io.weirdware.BlueFerry";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
      ];
      keywords = [
        "iPhone"
        "SMS"
        "iMessage"
        "Bluetooth"
        "Notifications"
        "Messages"
      ];
      startupNotify = false;
    });

  buildInputs =
    lib.optionals withGtk [
      libadwaita
    ]
    ++ lib.optionals withQt [
      kdePackages.kirigami
      kdePackages.qqc2-desktop-style
      kdePackages.qtdeclarative
    ];

  dependencies = [
    python3Packages.cryptography
    python3Packages.dbus-python
    python3Packages.typer
    python3Packages.textual
    python3Packages.pygobject3
  ]
  ++ lib.optionals withQt [
    python3Packages.pyside6
  ];

  postPatch = ''
    substituteInPlace \
      src/blueferry/{bluez_setup,bluetooth_capabilities,backend_lifecycle,pair_setup}.py \
      --replace-quiet /usr/bin/systemctl ${lib.getExe' systemd "systemctl"} \
      --replace-quiet /usr/bin/btmgmt ${lib.getExe' bluez "btmgmt"}
  ''
  + lib.optionalString withQuickshell ''
    substituteInPlace data/quickshell/{shell,BackendBridge}.qml \
      --replace-fail /usr/bin/blueferry "$out/bin/blueferry"
    substituteInPlace data/quickshell/Theme.qml \
      --replace-fail /usr/bin/hyprctl ${lib.getExe' hyprland "hyprctl"}
  '';

  postInstall = ''
    # NixOS' systemd.packages only collects units from lib/systemd and
    # etc/systemd, never from share/systemd.
    mkdir -p $out/lib/systemd/{user,system} $out/libexec/blueferry $out/share/dbus-1/services
    substitute systemd/blueferry.service $out/lib/systemd/user/blueferry.service \
      --replace-fail /usr/bin/blueferry $out/bin/blueferry

    # Setting the adapter class of device needs CAP_NET_ADMIN, so the daemon
    # asks systemd to start this template unit and polkit to authorize it.
    substitute systemd/blueferry-btmgmt-set-class@.service \
      $out/lib/systemd/system/blueferry-btmgmt-set-class@.service \
      --replace-fail /usr/lib/blueferry/blueferry-set-cod \
        $out/libexec/blueferry/blueferry-set-cod
    substitute systemd/blueferry-set-cod $out/libexec/blueferry/blueferry-set-cod \
      --replace-fail /bin/sh ${stdenv.shell} \
      --replace-fail /usr/bin/btmgmt ${lib.getExe' bluez "btmgmt"}
    chmod +x $out/libexec/blueferry/blueferry-set-cod
    install -Dm644 systemd/49-blueferry-cod.rules \
      $out/share/polkit-1/rules.d/49-blueferry-cod.rules

    substitute packaging/arch/io.weirdware.BlueFerry.service \
      $out/share/dbus-1/services/io.weirdware.BlueFerry.service \
      --replace-fail /usr/bin/blueferry $out/bin/blueferry

    install -Dm644 data/io.weirdware.BlueFerry.xml \
      $out/share/dbus-1/interfaces/io.weirdware.BlueFerry.xml

    install -Dm644 data/icons/io.weirdware.BlueFerry.svg \
      $out/share/icons/hicolor/scalable/apps/io.weirdware.BlueFerry.svg
  ''
  + lib.optionalString (!withGtk) ''
    rm -r $out/bin/blueferry-gtk ${sitePackages}/blueferry/ui
  ''
  + lib.optionalString (!withQt) ''
    rm -r $out/bin/blueferry-qt ${sitePackages}/blueferry/qt
  ''
  + lib.optionalString withQuickshell ''
    install -Dm644 data/quickshell/*.qml -t $out/share/blueferry/quickshell
  '';

  dontWrapGApps = true;
  dontWrapQtApps = true;

  postFixup =
    lib.optionalString withGtk ''
      wrapGApp $out/bin/blueferry-gtk
    ''
    + lib.optionalString withQt ''
      wrapQtApp $out/bin/blueferry-qt
    ''
    # Written after the Python wrapper hooks have run: this is a plain shell
    # launcher, not a Python entry point.
    + lib.optionalString withQuickshell ''
      cat > $out/bin/blueferry-quickshell <<EOF
      #!${stdenv.shell}
      exec ${lib.getExe quickshell} -p $out/share/blueferry/quickshell "\$@"
      EOF
      chmod +x $out/bin/blueferry-quickshell
    '';

  meta = {
    description = "iPhone iMessage/SMS and notifications bridge to Linux over Bluetooth";
    homepage = "https://github.com/erikwb/blueferry";
    license = lib.licenses.gpl2Plus;
    maintainers = [ lib.maintainers.skyesoss ];
    mainProgram = "blueferry";
    platforms = lib.platforms.linux;
  };
})
