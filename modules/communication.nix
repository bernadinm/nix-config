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
    telegram-desktop
    slack
    signal-desktop
    keybase-gui

    # email client
    unstable.pop protonmail-bridge # email cli

    # visual comm
    #unstable.realvnc-vnc-viewer

    # weechat irc
    weechat
    weechatScripts.wee-slack
    weechatScripts.weechat-notify-send

    rustdesk # teamviewer oss
    anydesk # remote desktop sharing

    #irc clients
    tiny # rust irc client
    fractal # matrix irc client
    calcurse # cal cli integration

    # record
    simplescreenrecorder
    caffeine-ng
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
