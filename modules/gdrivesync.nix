{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-cloud-sdk
    colordiff
    gcsfuse

    git-annex # sync remote files
    rclone # sync remote files
    git-annex-remote-rclone # sync remote files
    git-annex-utils # sync remote files
  ];

  environment.etc."profile.local".text =
    ''
      # /etc/profile.local: DO NOT EDIT - this file has been generated automatically.
      #wget -q https://raw.githubusercontent.com/bernadinm/nix-config/master/configuration.nix -O $PWD/configuration.nix
      #colordiff -u -d /etc/nixos/configuration.nix configuration.nix; if [ $? -eq 1 ]; then
      #  sudo cp configuration.nix /etc/nixos/configuration.nix;
      #  sudo nixos-rebuild switch;
      #fi
      #rm configuration.nix &> /dev/null;

      # Login to GCP if application default credentials doesn't exist
      if ! [[ ( -f ~/.config/gcloud/application_default_credentials.json ) ]]
        then
          gcloud auth application-default login
      fi

      # Fetch git annex shared files
      # Prereq: gsutil mb -c regional -l us-west1 gs://nixos-persist
      gpg --list-key 915FA8A6391DDAC6 2>&1 > /dev/null || error_code=$?
      if [[ "$error_code" -eq 2 ]]; then curl -sSL gpg.miguel.engineer | gpg --import -; fi
      if ! [[ ( -d ~/git/bernadinm/g) ]]; then
         WD="~/git/bernadinm/g"
         mkdir -p $WD;
         git clone https://github.com/bernadinm/g $WD;
         cd $WD;
         git annex init
         # TODO(bernadinm): fetch IAM for GCS, source it, and run git annex enableremote; and get essentials
      fi

      alias matrix='echo -e "1"; while $t; do for i in `seq 1 40`;do r="$[($RANDOM % 2)]";h="$[($RANDOM % 4)]";if [ $h -eq 1 ]; then v="0 $r";else v="1 $r";fi;v2="$v2 $v";done;echo -e $v2 | GREP_COLOR="1;32" grep --color "[^ ]";v2=""; sleep .01;done;'

      # configurating SSH, GPG, MSMTP, IMAP, GIT keys
      if ! [[ ( -d ~/.ssh ) ]]; then ln -s ~/git/bernadinm/g/.ssh ~/.ssh; fi
      if ! [[ ( -d ~/.gnupg ) ]]; then ln -s ~/git/bernadinm/g/.gnupg ~/.gnupg; fi
      if ! [[ ( -f ~/.msmtprc ) ]]; then ln -s ~/git/bernadinm/g/.msmtprc ~/.msmtprc; fi
      if ! [[ ( -f ~/.offlineimaprc ) ]]; then ln -s ~/git/bernadinm/g/.offlineimaprc ~/.offlineimaprc; fi
      if ! [[ ( -f ~/.gitconfig ) ]]; then ln -s ~/git/bernadinm/g/.gitconfig ~/.gitconfig; fi
      if ! [[ ( -f ~/.pureline.conf ) ]]; then ln -s ~/git/bernadinm/g/.pureline.conf ~/.pureline.conf; fi

      export GPG_TTY="$(tty)" #TODO(bernadinm): https://github.com/keybase/keybase-issues/issues/2798

      if [ "$TERM" != "linux" ]; then
        source ~/git/bernadinm/g/pureline/pureline ~/.pureline.conf
      fi

      # lynx config
      export WWW_HOME=https://duckduckgo.com/lite/
      # Private ENV vars
      if test -f "$HOME/g/.private.env"; then
        . "$HOME/g/.private.env"
      fi

      # Use agent socket per terminal
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    '';
}
