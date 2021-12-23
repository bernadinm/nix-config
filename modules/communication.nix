{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    zoom-us
    mumble
    profanity
    discord
    slack
    signal-desktop
    keybase-gui

    # visual comm
    tigervnc

    # weechat
    weechat
    weechatScripts.wee-slack 
    weechatScripts.weechat-notify-send
    weechatScripts.weechat-matrix-bridge
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
