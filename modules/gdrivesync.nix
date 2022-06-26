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

      # Setting vi alias to vim
      # TODO(bernadinm): removing for now until nvim plugins and config is installed with nix
      # alias vi="nvim"
      alias matrix='echo -e "1"; while $t; do for i in `seq 1 40`;do r="$[($RANDOM % 2)]";h="$[($RANDOM % 4)]";if [ $h -eq 1 ]; then v="0 $r";else v="1 $r";fi;v2="$v2 $v";done;echo -e $v2 | GREP_COLOR="1;32" grep --color "[^ ]";v2=""; sleep .01;done;'

      # configurating SSH, GPG, MSMTP, IMAP, GIT keys
      if ! [[ ( -d ~/.ssh ) ]]; then ln -s ~/git/bernadinm/g/.ssh ~/.ssh; fi
      if ! [[ ( -d ~/.gnupg ) ]]; then ln -s ~/git/bernadinm/g/.gnupg ~/.gnupg; fi
      if ! [[ ( -f ~/.msmtprc ) ]]; then ln -s ~/git/bernadinm/g/.msmtprc ~/.msmtprc; fi
      if ! [[ ( -f ~/.offlineimaprc ) ]]; then ln -s ~/git/bernadinm/g/.offlineimaprc ~/.offlineimaprc; fi
      if ! [[ ( -f ~/.gitconfig ) ]]; then ln -s ~/git/bernadinm/g/.gitconfig ~/.gitconfig; fi
      if ! [[ ( -f ~/.pureline.conf ) ]]; then ln -s ~/git/bernadinm/g/.pureline.conf ~/.pureline.conf; fi

      export GPG_TTY="$(tty)" #TODO(bernadinm): https://github.com/keybase/keybase-issues/issues/2798
      # vimrc
      cat <<EOF > ~/.tmux.conf
      setw -g mode-keys vi
      EOF
      cat <<EOF > ~/.vimrc
      syntax on
      set list
      set number
      set mouse -=a
      set bs=2
      set tabstop=4
      " Easy toggle off list and number
      map <C-l> :set number! list!<CR>
      EOF
      # bashrc
      cat <<EOF > ~/.bashrc
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
      alias docker-compose='arion'
      alias tts='xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=130 -voice slt'
      alias testtts='echo "xsel | mimic --setf duration_stretch=0.6 --setf int_f0_target_mean=120 -voice rms"'
      alias ww='sudo ddcutil setvcp 60 27' # USB-C
      alias pp='sudo ddcutil setvcp 60 18' # HDMI-1
      set -o ignoreeof
      source /etc/profile.local
      alias bc='bc <<< '
      alias gpom='git pull origin master'
      alias gPom='git push origin master'
      alias ga='git add '
      alias gcm='git commit -m '
      alias gcma='git commit --amend -m '
      alias gcb='git checkout -b '
      alias gc='git checkout'
      alias grh='git reset --hard'
      alias grhom='git reset --hard origin/master'
      alias gfa='git fetch --all'
      alias grom='git rebase origin/master'
      alias gp='git pull'
      alias gph='git pull --hard'
      alias gd='git diff'
      alias gs='git status'
      alias gsp='git stash pop'
      alias gds='git diff --staged'
      alias gau='git add -u'
      freshfetch # bash init
      EOF
      if test -f "$HOME/.profile"; then
        . "$HOME/.profile"
      fi

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
