{ pkgs, ... }:
{
  services.xserver.windowManager.niri.config = {
    keybindings = [
      {
        key = "d";
        modifiers = ["Super"];
        command = "wofi";
      }
    ];
  };
}
