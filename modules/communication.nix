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
    unstable.signal-desktop
    keybase-gui

    # email client
    unstable.pop protonmail-bridge # email cli
    aerc # email client
    himalaya # email client
    khard # caldav contacts client

    # Tools for enhanced email viewing and handling
    w3m # Text-based web browser, used for HTML email rendering
    catimg # Terminal image viewer
    catdoc # Text extractor for MS-Office files
    python312Packages.docx2txt # .docx to text converter
    zathura # Document viewer (primarily for PDFs)
    
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

  services.offlineimap.enable = true;
  services.offlineimap.install = true;
}
