# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-22.11.tar.gz";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ../../modules/security.nix
      # ../../modules/monitoring.nix
      # ../../modules/utilities.nix
      # ../../modules/coding.nix
      # <nixos-unstable/nixos/modules/services/networking/nebula.nix>
    ];

  networking.hostName = "Meteor"; # Define your hostname.
  networking.networkmanager.enable = true; # Use networkmanager for wifi

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
  #time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  nixpkgs.config.allowUnfree = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "input" "video" "i2c" "vboxusers" "libvirtd" ]; # Enable ‘sudo’ for the user.
    description = "Miguel Bernadin";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Enable Nebula Mesh Network
  #services.nebula.networks.mesh = {
  #  staticHostMap = { "192.168.100.100" = [ "meteor.miguel.engineer:4242" ]; };
  #};

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
