{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    zoom-us
    mumble
    weechat
    profanity
    discord
  ];

  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
  nixpkgs.config = baseconfig // {
    packageOverrides = pkgs: {
      #nebula = unstable.nebula;
      #  keycloak = unstable.keycloak;
    };
  };
}
