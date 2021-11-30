# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
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
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.nixos.device = "/dev/disk/by-uuid/0ec6024a-636d-4736-a299-83b3c071d9a9";
  boot.initrd.luks.devices.nixos.preLVM = true;
  services.ddclient = { enable = true; configFile = "/home/miguel/configs/ddclient/ddclient.conf"; }; # dynamicdns
  services.xserver.videoDrivers = [ "nvidia" ];
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

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 

  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n";
  };

  services.bind = {
    enable = true;
    extraConfig = ''
      include "/var/lib/secrets/dnskeys.conf";
    '';
    zones = [
      rec {
        name = "lumina.miguel.engineer";
        file = "/var/db/bind/${name}";
        master = true;
        extraConfig = "allow-update { key rfc2136key.lumina.miguel.engineer.; };";
      }
    ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  services.avahi.enable = true; # sometimes needed for finding on network
  services.avahi.nssmdns = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  hardware.bluetooth.enable = true; # enable bluethooth

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver = {
    libinput.touchpad.naturalScrolling = true;
    libinput.enable = true;
  };

  hardware.acpilight.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ddcutil
    i2c-tools
    libinput-gestures
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "plasmashell";

  # Open ports in the firewall.
  networking.enableIPv6 = false;
  networking.firewall.allowedTCPPorts = [ 3389 80 443 4242 ];
  networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
  networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Install the flakes edition
  nix.package = pkgs.nixFlakes;
  # Enable the nix 2.0 CLI and flakes support feature-flags
  nix.extraOptions = ''
    experimental-features = nix-command flakes 
  '';

  # List services that you want to enable:

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
