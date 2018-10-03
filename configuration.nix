{ config, pkgs, ... }:

{
  imports = [
  <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
  "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
  ];
  services.openssh.enable = true;

  # Setting the hostname of NixOS
  networking.hostName = "miguel-nixos";

  #networking.firewall.allowPing = true;
  #networking.firewall.allowedTCPPorts = [ 22 ];

  environment.systemPackages = with pkgs; [
   vim
   mkpasswd
   (vim_configurable.customize {
      name = "vim";
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
    # Created https://github.com/NixOS/nixpkgs/issues/47813 (user passwords dont get removed after removing it in configuration.nix)
    hashedPassword = "$6$pl5e7mhKtY06a$PPVQmGq9dhdldzKfR0rhCVbO74UEJQmfg/zweSiHQaBF9.0o5BdXGiA.ecasgsc2Wy2Bhgjmrsm1m0TEyaZvx."; # not expected to overwrite a shadow file during nixos-rebuild
    description = "Miguel Bernadin";
    extraGroups = [ "wheel" ];
    packages = [
      pkgs.lsof
      pkgs.nmap
      pkgs.wget
      pkgs.curl
      pkgs.traceroute
      pkgs.tree
    ];
    openssh.authorizedKeys.keys =
  [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCziuN8QzK0XAvmXVJ2glkVJuGySd2KwGBrQlCP4UFyGOWeh5FEXgL7/kdfx0TZKLMEXrDs8al1Ve7tL9DBnTWpVAimqjj3T+5G2S8Z/KG2eoG+ADd26KkjJOh3MhVBk6CLY3vTJzIK2jr7ljn/fZ01NS/KOTYvmzqQo6r/cIYt9NoNxS9KfzGDrAR+IA+QhbI2SojzVt6GcmJpKmKwtevANIhL/qCZ1x+Z+hZ1cPW2EwVazkpeGluMXv08zVkoivXjkxks3Pjj11EyuBD1UmuRkyE7ve24U0Cvk+jgjP2aA6ElTNf/p20QA1Wpi/84vICoAsIVt7F28n4j/4u2TgeD mbernadin@mesospheres-MacBook-Pro-2.local" ];
  };
}
