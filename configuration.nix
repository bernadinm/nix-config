{ config, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/installer/virtualbox-demo.nix> ];
  services.openssh.enable = true;

  # Setting the hostname of NixOS
  networking.hostName = "miguel-nixos";

  #networking.firewall.allowPing = true;
  #networking.firewall.allowedTCPPorts = [ 22 ];

  environment.systemPackages = with pkgs; [
   lsof
   ncat
   traceroute
   vimHugeX
   mkpasswd
   (vim_configurable.customize {
      name = "vimHugeX";
      vimrcConfig.customRC = ''
        syntax on
        set mouse-=a
        set number
      '';
    })
  ];

  #environment.etc."vimrc".text = ''
  #  syntax on
  #  set mouse-=a
  #'';

  users.extraUsers.mb =
  { 
    isNormalUser = true;
    createHome = true;
    hashedPassword = "$6$pl5e7mhKtY06a$PPVQmGq9dhdldzKfR0rhCVbO74UEJQmfg/zweSiHQaBF9.0o5BdXGiA.ecasgsc2Wy2Bhgjmrsm1m0TEyaZvx.";
    description = "Miguel Bernadin";
    extraGroups = [ "wheel" ];
  };
}
