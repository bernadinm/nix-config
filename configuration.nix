{ config, pkgs, ... }:

{
  imports = [
  <nixpkgs/nixos/modules/installer/virtualbox-demo.nix>
  #"${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
  ];

  # Setting the hostname of NixOS
  networking.hostName = "miguel-nixos";
  time.timeZone = "America/Los_Angeles";

  #networking.firewall.allowPing = true;
  #networking.firewall.allowedTCPPorts = [ 22 ];

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay";

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

 services = {
    nixosManual.showManual = true;
    openssh.enable = true;
    keybase.enable = true;
    locate.enable = true;
    ntp.enable = true;
  };

  environment.variables = { GOROOT = [ "${pkgs.go.out}/share/go" ]; };
  
  # adding mb to trusted users list
  nix.extraOptions = ''
    trusted-users = root mb
  '';

  # bash profil env
  environment.interactiveShellInit = ''
   # add ssh keys
   if [[ "$(ps -ef | grep ssh-agent | grep mb | grep -v grep | tail -1)" = "" ]]; then
     eval $(ssh-agent -s -a ~/.ssh-agent-socket);
   else
     SSH_AGENT_PID="$(ps -ef | grep ssh-agent | grep mb | awk '{print $2}' | head -1)";
     SSH_AUTH_SOCK="$HOME/.ssh-agent-socket";
     export SSH_AGENT_PID="$(ps -ef | grep ssh-agent | grep mb | grep -v grep | awk '{print $2}' | head -1)";
     export SSH_AUTH_SOCK="$HOME/.ssh-agent-socket";
   fi
   grep -slR "PRIVATE" ~/.ssh/ | xargs ssh-add
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
   if ! pgrep -x gcsfuse &>/dev/null; then gcsfuse -file-mode=600 nixos-persist ~/g; fi 
   
   # Setting vi alias to vim
   alias vi="vim"
   alias ncdu="docker run -it -v /:/mount bernadinm/ncdu /mount"
 
   # configurating SSH, GPG, MSMTP, IMAP, GIT keys
   if ! [[ ( -d ~/.ssh ) ]]; then ln -s ~/g/.ssh ~/.ssh; fi
   if ! [[ ( -d ~/.gnupg ) ]]; then ln -s ~/g/.gnupg ~/.gnupg; fi
   if ! [[ ( -f ~/.msmtprc ) ]]; then ln -s ~/g/.msmtprc ~/.msmtprc; fi
   if ! [[ ( -f ~/.offlineimaprc ) ]]; then ln -s ~/g/.offlineimaprc ~/.offlineimaprc; fi
   if ! [[ ( -f ~/.gitconfig ) ]]; then ln -s ~/g/.gitconfig ~/.gitconfig; fi
   if ! [[ ( -f ~/.pureline.conf ) ]]; then ln -s ~/g/.pureline.conf ~/.pureline.conf; fi
   
   export GPG_TTY="$(tty)" #TODO(bernadinm): https://github.com/keybase/keybase-issues/issues/2798

   # vimrc
   echo "set mouse -=a" > ~/.vimrc
   echo "set bs=2" > ~/.vimrc

   if test -f "$HOME/.profile"; then
     . "$HOME/.profile"
   fi

   if [ "$TERM" != "linux" ]; then
     source ~/g/pureline/pureline ~/.pureline.conf
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
      # pkgs.azure-cli # https://github.com/NixOS/nixpkgs/issues/40073
      pkgs.gcsfuse
      pkgs.pup
      pkgs.terraform
      pkgs.sup
      pkgs.offlineimap
      pkgs.msmtp
      pkgs.reptyr
      pkgs.gnupg
      pkgs.gitAndTools.hub
      pkgs.openssl
      pkgs.gnumake
      pkgs.go
      pkgs.keybase
    ];
    openssh.authorizedKeys.keys =
  [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAOWoNpiBAo2/fAodKOKnWRRFDhMKIYJ2OxOVw3haLOROoST2SyNW0XAxQ9eWTPB3DseRBCkYVkNNDmwkl/vHLVhUW8cn2pEg8Rgf38Yn5HL/rU4kMPpxTHI+30Y0F6cQabRkHosP91TE5vQVXdxDcwu2wxkrlipJaa+Ra5PyzMXfGXRygFrehBDvPicABTO54uJ0f0uE2NadoTc1+fiOsxLSSXSttyS/XQhsdC9w/tV6ZRLN0ZevpQTQG3506Lg6KOp0csODbXtI32rcXwJ7YrtIUJxwL8VbO7MUB4P73kL1iHwNdHAAf4WoBOwV/PlvwbBgvXKWNS7ybyobPjjCWuwAi6sWaIuaJwtBbCm47uVyVDMkJ1/N2qO6ZzfnR1QbpI7y2GGEli0C0BSlJrwNRRVXwJZjcf/hbBt4VNffGk2OwqkESjPrvNt8hBUwKfxNXwJ0gz9P6UX6FOxdlLNWLARn3R3etP8CkEciUwNBgRJDziDHP3xCHZUqDN6wfcMyk7P5lFe2opSPkqoELAoc3IvgObORmKYqujODiITYCbidDQ3W57jN5GziGJ+nWliBFMOR3PSanF3nximwVk1jO6Aq8YYuiEksYq8H65O+FPQ6If4pONQpm0Gn5FXBaMwvET6gpqrTKrT+cb3/hmezLlG0xNVYkicgxhREW06ikrQ== loaner" ];
  };
}
