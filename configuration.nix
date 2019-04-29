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
   colordiff
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
     rm ~/.ssh-agent-socket &> /dev/null
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
   colordiff -u -d /etc/nixos/configuration.nix configuration.nix; if [ $? -eq 1 ]; then
     sudo cp configuration.nix /etc/nixos/configuration.nix;
     sudo nixos-rebuild switch;
   fi
   rm configuration.nix &> /dev/null;
   
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
   cat <<EOF > ~/.vimrc
set mouse -=a
set bs=2
set tabstop=4
EOF

   if test -f "$HOME/.profile"; then
     . "$HOME/.profile"
   fi

   if [ "$TERM" != "linux" ]; then
     source ~/g/pureline/pureline ~/.pureline.conf
   fi

   # lynx config
   export WWW_HOME=https://duckduckgo.com/lite/

   # Private ENV vars
   if test -f "$HOME/g/.private.env"; then
     . "$HOME/g/.private.env"
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
      pkgs.aria2
      pkgs.bind
      pkgs.python
      pkgs.python27Packages.virtualenv
      pkgs.python27Packages.pip
      pkgs.gcc # used with pip 
      pkgs.libffi # used with pip 
      pkgs.pandoc
      pkgs.shellcheck
      pkgs.atop
    ];
    openssh.authorizedKeys.keys =
  [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC36zQor41pnBqbIaww7hJRz8IQtyWEW1RGlwuSpZiQpClyjIdm5Lg3Y/irVKJF3O0bN7pw7v5B6w7nojBVjQyzW360lJGUUjcTH0r2cq7g5wJWl9YKIpzGymsTUf+f65aMin9Dq+lLHSnKpeZXrv8fPVj4dy2Um2oLGNb1vjtnGPUuApA8HL51HUTNY7wNlqkxJLjGoXKGu+siAJygB4Qn310l0QH/lFlAFdXnMNjLSC7+nEV/5/vgyKlIU2SbGr9/kj2w+iZdOMxG6PzXfcyvpLKtxvLTIFlJXFqlrr8UCfS1ghnEMUsbOu35A8EDpt2wjjgLdpMIh6n/uYJHg9VxAYFk9u3d+Szxv2iG92au9JaiCub3mUSDBzOTV6ecO3eNHiyeYL1H8hgwH/CLyMDkKqp1XKS5l27kDf8/LTbc0uvjDYuYa90NRa4GQYZhd6fUufVl0q3uPEFHQs0mvOKyuWjEVNz1Rifn304hvwuJpEzVzDNIfuLtPN46Ft4p3ridf3VbF4+etfXJ9pUdJpF2Ll2Wnrix5aS4coCxlNLUn838qbYQI9t50CL7YNC61whRU4RVx4tWLFRUAhZ0bHsfQhs0FRzbO/JzkiAuMiIFSx17UqG3aVsSCWvRD/psqN+TYqCdvO5QZj3eLMqUjH8tpcpSfro9klHQ8donDotf7w== Mesospheres-MacBook-Pro-2.local" ];
  };
}
