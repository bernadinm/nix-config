{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    blender # 3d rendering
  ];
}
