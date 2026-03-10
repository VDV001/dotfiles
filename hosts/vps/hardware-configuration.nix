{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/virtualisation/openstack-config.nix") ];

  # Xen drivers for GandiCloud (Xen-based hypervisor)
  boot.initrd.kernelModules = [
    "xen-blkfront"
    "xen-tpmfront"
    "xen-kbdfront"
    "xen-fbfront"
    "xen-netfront"
    "xen-pcifront"
    "xen-scsifront"
  ];

  boot.loader.grub.device = lib.mkForce "/dev/xvda";

  boot.consoleLogLevel = 7;
  boot.kernel.sysctl = {
    "kernel.printk" = "4 4 1 7";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernelParams = [ "console=ttyS0" ];

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Restart = "always";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # Required for IPv6 on GandiCloud
  networking.tempAddresses = "disabled";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
