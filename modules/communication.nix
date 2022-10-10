{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
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
    realvnc-vnc-viewer

    # weechat irc
    weechat
    weechatScripts.wee-slack
    weechatScripts.weechat-notify-send

    rustdesk # teamviewer oss

    #irc clients
    tiny # rust irc client
    fractal # matrix irc client
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
