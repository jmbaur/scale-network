{ lib, pkgs, ... }:
{
  nixpkgs.buildPlatform = "x86_64-linux";
  hardware.openwrt-one.enable = true;

  bin = [
    pkgs.hostapd
    pkgs.iw
    pkgs.libgpiod
    pkgs.mtdutilsMinimal
    pkgs.net-tools
    pkgs.nftables
    pkgs.phytool
    pkgs.scale-network.apinger
    pkgs.traceroute
  ];

  etc."apinger.tmpl".source = ./apinger.tmpl;

  init.shell = {
    tty = "ttyS0";
    action = "askfirst";
    process = "/bin/sh";
  };

  users.root = {
    uid = 0;
    gid = 0;
  };

  groups.root.id = 0;
  groups.nogroup.id = 1;

  init.apinger = {
    action = "respawn";
    process = "${lib.getExe pkgs.scale-network.apinger}";
  };

  init.hostapd = {
    action = "respawn";
    process = "${lib.getExe' pkgs.hostapd "hostapd"} ${./hostapd.conf}";
  };

  init.create-interfaces = {
    action = "wait";
    process = pkgs.writeScript "create-interfaces.ash" ''
      #!/bin/sh

      set -x

      ip link add br-lan type bridge stp on
      ip link add scaleslow-br type bridge stp on
      ip link add scalefast-br type bridge stp on
      ip link add mgmt-br type bridge stp on
      ip link set dev eth0 master br-lan
      ip link set dev eth1 master br-lan
      ip link add link br-lan name br-lan.100 type vlan id 100
      ip link add link br-lan name br-lan.500 type vlan id 500
      ip link add link br-lan name br-lan.101 type vlan id 101
      ip link add link br-lan name br-lan.501 type vlan id 501
      ip link add link br-lan name br-lan.103 type vlan id 103
      ip link add link br-lan name br-lan.503 type vlan id 503
      ip link set dev br-lan.100 master scaleslow-br
      ip link set dev br-lan.500 master scaleslow-br
      ip link set dev br-lan.101 master scalefast-br
      ip link set dev br-lan.501 master scalefast-br
      ip link set dev br-lan.103 master mgmt-br
      ip link set dev br-lan.503 master mgmt-br
    '';
  };
}
