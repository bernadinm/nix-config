{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    zoom-us
    mumble
    weechat
    profanity
    discord
    slack
    signal-desktop
    keybase-gui

    # visual comm
    tigervnc
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
