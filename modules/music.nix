{ config, pkgs, ... }:

{
  imports =
    [
      ../vendors/musnix
    ];

  musnix.enable = true;
}
