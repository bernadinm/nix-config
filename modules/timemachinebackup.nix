{ config, pkgs, ... }:

{
  services.netatalk = {
    enable = true;
    settings = {
      Homes = {
        # Homes are optional - don't need them for Time Machine
        "basedir regex" = "/home";
        #           path = "netatalk";
      };
      timemachine = {
        path = "/timemachine";
        "valid users" = "miguel";
        "time machine" = true;
      };
    };
  };
}
