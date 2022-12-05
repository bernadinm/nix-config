{ config, pkgs, ... }:

{
  services.calibre-web = {
    enable = true;
    # listen.port = port;
    options = {
      calibreLibrary = "${config.users.users.miguel.home}/Documents/calibre-library";
      reverseProxyAuth = {
        enable = true;
        # header = "X-User";
      };
    };
  };
}
