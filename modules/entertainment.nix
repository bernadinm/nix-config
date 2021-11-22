{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # music producing software
    ardour

    # gaming

    # wineWowPackages.staging
    # (winetricks.override {
    #   wine = wineWowPackages.staging;
    # })
    wineWowPackages.full
    winetricks
    sc-controller
    steam-run
    vulkan-tools
    minecraft
    multimc
    lutris
    eidolon
    krb5
    cmatrix

    # drone configuration
    betaflight-configurator

    # multimedia
    vlc
    gimp
    libreoffice
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;
}
