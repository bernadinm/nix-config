{ pkgs, ... }:
{
  programs.niri.config = {
    keybindings = [
      {
        key = "d";
        modifiers = ["Super"];
        command = "wofi";
      }
    ];
  };
}
