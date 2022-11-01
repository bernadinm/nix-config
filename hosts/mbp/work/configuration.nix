# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      #../../modules/gdrivesync.nix
      #../../modules/entertainment.nix
      #../../modules/security.nix
      #../../modules/virtualization.nix
      #../../modules/communication.nix
      #../../modules/monitoring.nix
      #../../modules/desktop.nix
      #../../modules/utilities.nix
      #../../modules/coding.nix
      #<nixos-unstable/nixos/modules/services/networking/nebula.nix>
    ];

  nixpkgs.config.allowUnfree = true;

  home-manager.users.miguel.home.file =
    {
      ".config/i3/config".source =
        .config/i3/config;
    };

  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
