# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  # uncomment for enabling cross compilation
  #nixpkgs.crossSystem.system = "armv6l-linux";
  imports = [
    # This contains the default definition for the sdcard image build
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix>
  ];
  # put your own configuration here, for example ssh keys:
  #users.users.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1.... username@tld"
  #];
}
