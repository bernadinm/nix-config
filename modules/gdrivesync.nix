{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-cloud-sdk
    colordiff
    gcsfuse
  ];

  # when running un multiple environments sync them on login
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

      # Persist NixOS on GCP
      # Prereq: gsutil mb -c regional -l us-west1 gs://nixos-persist
      mkdir -p ~/g
      if ! pgrep -x gcsfuse &>/dev/null; then gcsfuse -file-mode=600 nixos-persist ~/g; fi
      ls -l ~/g &>/dev/null; if [ $? -eq 2 ]; then fusermount -uz ~/g && gcsfuse -file-mode=600 nixos-persist ~/g; echo Restored gcsfuse connection...; fi

      # Setting vi alias to vim
      alias vi="vim"
      alias matrix='echo -e "1"; while $t; do for i in `seq 1 40`;do r="$[($RANDOM % 2)]";h="$[($RANDOM % 4)]";if [ $h -eq 1 ]; then v="0 $r";else v="1 $r";fi;v2="$v2 $v";done;echo -e $v2 | GREP_COLOR="1;32" grep --color "[^ ]";v2=""; sleep .01;done;'

      # configurating SSH, GPG, MSMTP, IMAP, GIT keys
      if ! [[ ( -d ~/.ssh ) ]]; then ln -s ~/g/.ssh ~/.ssh; fi
      if ! [[ ( -d ~/.gnupg ) ]]; then ln -s ~/g/.gnupg ~/.gnupg; fi
      if ! [[ ( -f ~/.msmtprc ) ]]; then ln -s ~/g/.msmtprc ~/.msmtprc; fi
      if ! [[ ( -f ~/.offlineimaprc ) ]]; then ln -s ~/g/.offlineimaprc ~/.offlineimaprc; fi
      if ! [[ ( -f ~/.gitconfig ) ]]; then ln -s ~/g/.gitconfig ~/.gitconfig; fi
      if ! [[ ( -f ~/.pureline.conf ) ]]; then cp ~/g/.pureline.conf ~/.pureline.conf; fi

      export GPG_TTY="$(tty)" #TODO(bernadinm): https://github.com/keybase/keybase-issues/issues/2798
      # vimrc
      cat <<EOF > ~/.vimrc
      syntax on
      set mouse -=a
      set bs=2
      set tabstop=4
      EOF
      # bashrc
      cat <<EOF > ~/.bashrc
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
      #alias pp='ddcutil -d 1 -i 18 >/dev/null; cd - ; # hdmi-2'
      #alias ww='ddcutil -d 1 -i 27 >/dev/null; cd - ; # USB-C'
      alias docker-compose='arion'
      alias tts='xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=130 -voice slt'
      alias testtts='echo "xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=120 -voice rms"'
      alias ww='sudo ddccontrol -r 0x60 -w 27 dev:/dev/i2c-5 &> /dev/null'
      alias pp='sudo ddccontrol -r 0x60 -w 18 dev:/dev/i2c-5 &> /dev/null'
      set -o ignoreeof
      source /etc/profile.local
      alias bc='bc <<< '
      alias gpom='git pull origin master'
      alias gcb='git checkout -b '
      alias gc='git checkout'
      alias grh='git reset --hard'
      alias grhom='git reset --hard origin/master'
      alias gp='git pull'
      alias gph='git pull --hard'
      freshfetch # bash init
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
}
