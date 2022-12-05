{ config, pkgs, ... }:

{
  services.calibre-web = {
    enable = true;
    listen.port = 8080;
    options = {
      calibreLibrary = "${config.users.users.miguel.home}/Documents/calibre-library";
      reverseProxyAuth = {
        enable = true;
        # header = "X-User";
      };
    };
  };
}
