{ config, pkgs, ... }:

{
  imports = [
  <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
  #"${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
  ];
  services.openssh.enable = true;

  # Setting the hostname of NixOS
  networking.hostName = "miguel-nixos";

  #networking.firewall.allowPing = true;
  #networking.firewall.allowedTCPPorts = [ 22 ];

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "devicemapper";

  environment.systemPackages = with pkgs; [
   vimHugeX
   mkpasswd
   (vim_configurable.customize {
      name = "vimHugeX";
      vimrcConfig.customRC = ''
        syntax on
        set mouse-=a
      '';
    })
  ];
  
  # adding mb to trusted users list
  nix.extraOptions = ''
    trusted-users = root mb
  '';

  # when running un multiple environments sync them on login
  environment.etc."profile.local".text =
   ''
   # /etc/profile.local: DO NOT EDIT - this file has been generated automatically.

   wget -q https://raw.githubusercontent.com/bernadinm/nix-config/master/configuration.nix -O $PWD/configuration.nix
   diff configuration.nix /etc/nixos/configuration.nix; if [ $? -eq 1 ]; then
     sudo cp configuration.nix /etc/nixos/configuration.nix;
     sudo nixos-rebuild switch;
   fi
   rm configuration.nix;
   
   # Login to GCP if application default credentials doesn't exist
   if ! [[ ( -f ~/.config/gcloud/application_default_credentials.json ) ]]
     then 
       gcloud auth application-default login
   fi
   
   # Persist NixOS on GCP
   # Prereq: gsutil mb -c regional -l us-west1 gs://nixos-persist
   mkdir -p ~/g
   if ! pgrep -x gcsfuse &>/dev/null; then gcsfuse -file-mode=700 nixos-persist ~/g; fi 
   
   # Setting vi alias to vim
   alias vi="vim"
 
   # configurating SSH keys
   if ! [[ ( -d ~/.ssh ) ]]; then ln -s ~/g/.ssh ~/.ssh; fi
   
   # configuring gpg keys
   if ! [[ ( -d ~/.gnupg ) ]]; then ln -s ~/g/.gnupg ~/.gnupg; fi
   
   # configuring msmtp creds
   if ! [[ ( -f ~/.msmtprc ) ]]; then ln -s ~/g/.msmtprc ~/.msmtprc; fi
   
   # add ssh keys
   eval $(ssh-agent)
   grep -slR "PRIVATE" ~/.ssh/ | xargs ssh-add
   
   if test -f "$HOME/.profile"; then
     . "$HOME/.profile"
   fi
   '';
  
  # this allows nix to control user creds on entire host
  users.mutableUsers = false;
  users.extraUsers.mb =
  {
    isNormalUser = true;
    createHome = true;
    # Created https://github.com/NixOS/nixpkgs/issues/47813 (user passwords dont get removed after removing it in configuration.nix)
    hashedPassword = "$6$pl5e7mhKtY06a$PPVQmGq9dhdldzKfR0rhCVbO74UEJQmfg/zweSiHQaBF9.0o5BdXGiA.ecasgsc2Wy2Bhgjmrsm1m0TEyaZvx."; # not expected to overwrite a shadow file during nixos-rebuild
    description = "Miguel Bernadin";
    extraGroups = [ "wheel" "docker" ];
    packages = [
      pkgs.lsof
      pkgs.nmap
      pkgs.wget
      pkgs.curl
      pkgs.traceroute
      pkgs.tree
      pkgs.bc
      pkgs.git
      pkgs.lynx
      pkgs.ipfs
      pkgs.jq
      pkgs.stack
      pkgs.youtube-dl
      pkgs.fuse
      pkgs.borgbackup
      pkgs.aws
      pkgs.google-cloud-sdk
      pkgs.gcsfuse
      pkgs.pup
      pkgs.terraform
      pkgs.sup
      pkgs.offlineimap
      pkgs.msmtp
      pkgs.sqlite
    ];
    openssh.authorizedKeys.keys =
  [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCziuN8QzK0XAvmXVJ2glkVJuGySd2KwGBrQlCP4UFyGOWeh5FEXgL7/kdfx0TZKLMEXrDs8al1Ve7tL9DBnTWpVAimqjj3T+5G2S8Z/KG2eoG+ADd26KkjJOh3MhVBk6CLY3vTJzIK2jr7ljn/fZ01NS/KOTYvmzqQo6r/cIYt9NoNxS9KfzGDrAR+IA+QhbI2SojzVt6GcmJpKmKwtevANIhL/qCZ1x+Z+hZ1cPW2EwVazkpeGluMXv08zVkoivXjkxks3Pjj11EyuBD1UmuRkyE7ve24U0Cvk+jgjP2aA6ElTNf/p20QA1Wpi/84vICoAsIVt7F28n4j/4u2TgeD mbernadin@mesospheres-MacBook-Pro-2.local" ];
  };
}
