{ config, pkgs, ... }:

{
  # Note: unstable packages now available via pkgs.unstable overlay from flake.nix
  environment.systemPackages = with pkgs; [
    # base
    zoom-us
    beeper
    mumble
    profanity
    discord
    telegram-desktop
    slack
    pkgs.unstable.signal-desktop
    keybase-gui

    # email client
    pkgs.unstable.pop protonmail-bridge # email cli
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
    #pkgs.unstable.realvnc-vnc-viewer

    # weechat irc
    weechat
    weechatScripts.wee-slack
    weechatScripts.weechat-notify-send

    rustdesk # teamviewer oss
    tigervnc # vnc
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
