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

    # email client
    unstable.pop # email cli

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
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
}
