{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
{
  environment.systemPackages = with pkgs; [
    # base
    unstable.zoom-us
    mumble
    profanity
    discord
    slack
    signal-desktop
    keybase-gui

    # visual comm
    tigervnc

    # weechat irc
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
