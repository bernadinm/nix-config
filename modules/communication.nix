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

    # visual comm
    tigervnc
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
