# Shared dotfiles configuration for all machines
# This module provides:
# - Shell configuration (bash, aliases, prompt)
# - GPG/SSH agent setup
# - Tmux configuration
# - Editor settings

{ config, lib, pkgs, ... }:

{
  # Common packages for shell environment
  environment.systemPackages = with pkgs; [
    starship      # Cross-shell prompt
    eza           # Modern ls replacement (exa successor)
    ripgrep       # Fast grep
    fd            # Fast find
    bat           # Better cat
    fzf           # Fuzzy finder
    helix         # Editor
    navi          # Cheatsheet tool
  ];

  # Home-manager backup setting
  home-manager.backupFileExtension = "backup";

  # Home-manager configuration for miguel
  home-manager.users.miguel = { pkgs, lib, ... }: {
    home.stateVersion = "25.05";

    # Shell aliases and environment
    programs.bash = {
      enable = true;
      shellAliases = {
        # Clipboard (works on both Wayland and X11)
        pbcopy = "wl-copy";
        pbpaste = "wl-paste";
        c = "wl-copy";
        p = "wl-paste";

        # Git shortcuts
        gpom = "git pull origin master || git pull origin main";
        gPom = "git push origin master || git push origin main";
        ga = "git add ";
        gcm = "git commit -m ";
        gca = "git commit --amend";
        gcma = "git commit --amend -m ";
        gcb = "git checkout -b ";
        gcom = "git checkout master || git checkout main";
        gc = "git checkout";
        grh = "git reset --hard";
        grhom = "git reset --hard origin/master || git reset --hard origin/main";
        grc = "git rebase --continue";
        gra = "git rebase --abort";
        gfa = "git fetch --all";
        grom = "git rebase origin/master || git rebase origin/main";
        gp = "git pull";
        gd = "git diff";
        gs = "git status";
        gsp = "git stash pop";
        gds = "git diff --staged";
        gdom = "git diff origin master || git diff origin main";
        gau = "git add -u";

        # Directory shortcuts
        g = "cd ~/git";
        b = "cd ~/git/bernadinm";
        n = "cd ~/git/bernadinm/nix-config";

        # Tool aliases
        vi = "hx";
        ll = "eza -lg";
        ls = "eza";
        rg = "rg -. -M 500";
        k = "kubectl";
        lsaltr = "eza -alg --sort=oldest --reverse";
      };

      bashrcExtra = ''
        set -o ignoreeof

        # Environment Variables
        export EDITOR='hx'
        export PATH="$PATH:$HOME/.local/bin"
        export GPG_TTY="$(tty)"

        # Symlink dotfiles from g repo if available
        if [[ -d ~/git/bernadinm/g ]]; then
          [[ ! -e ~/.ssh ]] && [[ -d ~/git/bernadinm/g/.ssh ]] && ln -s ~/git/bernadinm/g/.ssh ~/.ssh
          [[ ! -e ~/.gnupg ]] && [[ -d ~/git/bernadinm/g/.gnupg ]] && ln -s ~/git/bernadinm/g/.gnupg ~/.gnupg
          [[ ! -e ~/.gitconfig ]] && [[ -f ~/git/bernadinm/g/.gitconfig ]] && ln -s ~/git/bernadinm/g/.gitconfig ~/.gitconfig
          [[ ! -e ~/.pureline.conf ]] && [[ -f ~/git/bernadinm/g/.pureline.conf ]] && ln -s ~/git/bernadinm/g/.pureline.conf ~/.pureline.conf
        fi

        # Pureline prompt
        if [[ $- == *i* ]] && [ "$TERM" != "linux" ] && [[ -f ~/git/bernadinm/g/pureline/pureline ]]; then
          source ~/git/bernadinm/g/pureline/pureline ~/.pureline.conf
        fi

        # Navi cheatsheet
        if test -f "$HOME/.config/navi/.navi.plugin.bash"; then
          eval "$(cat $HOME/.config/navi/.navi.plugin.bash)"
        fi

        # Source system-wide settings
        [ -f /etc/profile.local ] && . /etc/profile.local
      '';
    };

    # GPG agent with SSH support (use mkDefault so hosts can override pinentry)
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = lib.mkDefault pkgs.pinentry-curses;
    };

    # Tmux configuration
    programs.tmux = {
      enable = true;
      clock24 = true;
      baseIndex = 1;
      escapeTime = 0;
      historyLimit = 999999999;
      mouse = true;
      terminal = "tmux-256color";
      plugins = with pkgs.tmuxPlugins; [
        sensible
        resurrect
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
          '';
        }
        yank
      ];
      extraConfig = ''
        # Clipboard
        set -g set-clipboard on

        # Terminal settings
        set -ag terminal-overrides ",xterm-256color:RGB"

        # Key bindings
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        # Vim-style pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Status bar
        set -g status-position bottom
        set -g status-justify centre
        set -g status-left-length 40
        set -g status-right-length 40
        set -g status-left '#[fg=green]#H #[fg=black]• #[fg=green,bright]#(uname -r | cut -c 1-6)#[default]'
        set -g status-right '#[fg=white,bg=default]%a%l:%M:%S %p#[default] #[fg=blue]%Y-%m-%d'

        # Dracula theme
        set -g status-style bg='#282a36',fg='#f8f8f2'
        set -g window-status-current-style bg='#ff79c6',fg='#282a36'
        set -g pane-border-style "fg=#444444"
        set -g pane-active-border-style "fg=#00ff00"
      '';
    };

    # Starship disabled - using pureline instead
    programs.starship = {
      enable = false;
      enableBashIntegration = false;
      settings = {
        add_newline = true;
        format = lib.concatStrings [
          "$time"
          "$battery"
          "$username"
          "@"
          "$hostname"
          " ▶ "
          "$directory"
          "$git_branch"
          "$git_status"
          "$kubernetes"
          "$nix_shell"
          "$python"
          "$nodejs"
          "$aws"
          "$gcloud"
          "$cmd_duration"
          "$status"
          "$line_break"
          "$character"
        ];
        character = {
          success_symbol = "[\\$](bold green)";
          error_symbol = "[\\$](bold red)";
        };
        time = {
          disabled = false;
          format = "[$time]($style) ▶ ";
          style = "bold cyan";
          time_format = "%H:%M:%S";
        };
        battery = {
          full_symbol = "🔋";
          charging_symbol = "⚡";
          discharging_symbol = "▬ ";
          format = "[$symbol$percentage]($style) ▶ ";
          display = [
            { threshold = 100; style = "bold green"; }
          ];
        };
        username = {
          style_user = "bold green";
          style_root = "bold red";
          format = "[$user]($style)";
          show_always = true;
        };
        hostname = {
          ssh_only = false;
          format = "[$hostname]($style)";
          style = "bold yellow";
        };
        directory = {
          truncation_length = 4;
          truncate_to_repo = false;
          format = "[$path]($style)[$read_only]($read_only_style)";
          style = "bold blue";
        };
        git_branch = {
          symbol = " ╬ ";
          format = "[$symbol$branch]($style)";
          style = "bold purple";
        };
        git_status = {
          format = "[$all_status$ahead_behind]($style) ";
          style = "bold purple";
          ahead = "↑\${count}";
          behind = "↓\${count}";
          diverged = "↑\${ahead_count}↓\${behind_count}";
          staged = "+\${count}";
          untracked = "?\${count}";
          modified = "!\${count}";
        };
        kubernetes = {
          disabled = false;
          symbol = "⎈ ";
          format = "▶ [$symbol$context]($style) ";
          style = "bold cyan";
        };
        nix_shell = {
          symbol = " ";
          format = "▶ [$symbol$state]($style) ";
        };
        status = {
          disabled = false;
          format = "▶ [x $status]($style) ";
          style = "bold red";
        };
        cmd_duration = {
          min_time = 2000;
          format = "▶ [took $duration]($style) ";
          style = "bold yellow";
        };
        aws = {
          format = "▶ [$symbol($profile)(\\($region\\))]($style) ";
          symbol = "☁️ ";
        };
        gcloud = {
          format = "▶ [$symbol$account]($style) ";
          symbol = "☁️ ";
        };
        python = {
          format = "▶ [\${symbol}\${pyenv_prefix}(\${version})]($style) ";
          symbol = "🐍 ";
        };
        nodejs = {
          format = "▶ [$symbol($version)]($style) ";
          symbol = " ";
        };
      };
    };

    # Helix editor configuration
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "catppuccin_mocha";
        editor = {
          line-number = "relative";
          mouse = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
        };
      };
    };
  };
}
