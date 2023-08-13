# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <nixos-unstable/nixos/modules/services/networking/nebula.nix>
      # <nixos-unstable/nixos/modules/services/web-apps/keycloak.nix>
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
      ../../modules/desktop.nix
      ../../modules/utilities.nix
      ../../modules/coding.nix
      ../../modules/music.nix
      ../../modules/3d-rendering.nix
      ../../modules/pci-passthrough.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.nixos.device = "/dev/disk/by-uuid/0ec6024a-636d-4736-a299-83b3c071d9a9";
  boot.initrd.luks.devices.nixos.preLVM = true;
  # TODO(bernadinm): temporarily removing ddclient config 
  # services.ddclient = { enable = true; configFile = "/home/miguel/configs/ddclient/ddclient.conf"; }; # dynamicdns
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
  '';
  # nixpkgs.config.allowUnfree = true;

  # Setting the hostname of NixOS
  networking.hostName = "Lumina";
  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;
  networking.extraHosts =
    ''
      192.168.100.3 luna
    '';

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw

  home-manager.users.miguel.home.file =
    {
      ".config/i3/config".source =
        .config/i3/config;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };

  # Removing becuase it conflicts with protonvpn
  # environment.etc = {
  #   "resolv.conf".text = "nameserver 8.8.8.8\n";
  # };

  # TODO(bernadinm): removing as it's not needed at the moment
  # services.bind = {
  #   enable = true;
  #   extraConfig = ''
  #     include "/var/lib/secrets/dnskeys.conf";
  #   '';
  #   zones = [
  #     rec {
  #       name = "lumina.miguel.engineer";
  #       file = "/var/db/bind/${name}";
  #       master = true;
  #       extraConfig = "allow-update { key rfc2136key.lumina.miguel.engineer.; };";
  #     }
  #   ];
  # };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver = {
    libinput.touchpad.naturalScrolling = true;
  };

  # hybrid sleep when press power button
  services.logind.extraConfig = ''
    IdleActionSec=60min
  '';

  hardware.acpilight.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ddcutil
    i2c-tools
    libinput-gestures
    nvtop # nvidia gpu monitor
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "plasmashell";

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Enable Nebula Mesh Network and set as lighthouse
  services.nebula.networks.mesh = {
    isLighthouse = true;
  };

  #pciPassthrough = {
  #  enable = true;
  #  pciIDs = "10de:2204,10de:1aef";
  #  libvirtUsers = [ "miguel" ];
  #};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
