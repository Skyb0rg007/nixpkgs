{ lib, pkgs, ... }:

let

  crasher = pkgs.writeCBin "crasher" "int main;";

  common = {
    systemd = {
      services.crasher.serviceConfig = {
        ExecStart = "${crasher}/bin/crasher";
        StateDirectory = "crasher";
        WorkingDirectory = "%S/crasher";
        Restart = "no";
      };

      coredump.settings.Coredump = {
        Storage = "journal";
        ProcessSizeMax = "0";
      };
    };
  };

in

{
  name = "systemd-coredump";
  meta = {
    maintainers = [ ];
  };

  nodes.machine = common;

  # systemd-coredumpd receives core dumps over the kernel's coredump socket,
  # which requires Linux 6.19 or newer.
  nodes.coredumpd = {
    imports = [ common ];
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };

  testScript =
    { nodes, ... }:
    let
      coredumpdSupported = lib.versionAtLeast nodes.machine.boot.kernelPackages.kernel.version "6.19";
    in
    ''
      start_all()

      with subtest("systemd-coredump enabled"):
        machine.wait_for_unit("multi-user.target")
        machine.wait_for_unit("systemd-coredump.socket")
        machine.systemctl("start crasher");
        machine.wait_until_succeeds("coredumpctl list | grep crasher", timeout=10)
        machine.fail("stat /var/lib/crasher/core*")

      ${lib.optionalString (!coredumpdSupported) ''
        with subtest("systemd-coredumpd is skipped on older kernels"):
          machine.fail("systemctl is-active systemd-coredumpd.service")
          machine.succeed("grep -q '^|' /proc/sys/kernel/core_pattern")
      ''}

      with subtest("settings.Coredump renders coredump.conf"):
        machine.succeed("grep -F '[Coredump]' /etc/systemd/coredump.conf")
        machine.succeed("grep -F 'Storage=journal' /etc/systemd/coredump.conf")
        machine.succeed("grep -F 'ProcessSizeMax=0' /etc/systemd/coredump.conf")

      with subtest("systemd-coredumpd receives core dumps over the kernel socket"):
        coredumpd.wait_for_unit("systemd-coredumpd.service")
        coredumpd.wait_for_unit("systemd-coredump-register.service")
        coredumpd.succeed("grep -qx '@@/run/systemd/coredumpd/kernel' /proc/sys/kernel/core_pattern")
        coredumpd.systemctl("start crasher");
        coredumpd.wait_until_succeeds("coredumpctl list | grep crasher", timeout=10)
        coredumpd.fail("stat /var/lib/crasher/core*")
    '';
}
