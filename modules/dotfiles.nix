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

    # k9s configuration with Dracula theme
    xdg.configFile."k9s/skins/dracula.yaml".source = ../dotfiles/.config/k9s/skins/dracula.yaml;
    xdg.configFile."k9s/config.yaml".text = ''
      k9s:
        liveViewAutoRefresh: false
        screenDumpDir: /home/miguel/.local/state/k9s/screen-dumps
        refreshRate: 2
        maxConnRetry: 5
        readOnly: false
        noExitOnCtrlC: false
        ui:
          skin: dracula
          enableMouse: false
          headless: false
          logoless: false
          crumbsless: false
          reactive: false
          noIcons: false
        logger:
          tail: 100
          buffer: 5000
          sinceSeconds: -1
          textWrap: false
          showTime: false
        thresholds:
          cpu:
            critical: 90
            warn: 70
          memory:
            critical: 90
            warn: 70
    '';

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
        ktx = "kubectx";
        kns = "kubens";
        lsaltr = "eza -alg --sort=oldest --reverse";
      };

      bashrcExtra = ''
        set -o ignoreeof

        # Environment Variables
        export EDITOR='hx'
        export PATH="$PATH:$HOME/.local/bin"
        export GPG_TTY="$(tty)"

        # Auto-detect WAYLAND_DISPLAY if not set (for tmux/SSH sessions)
        if [[ -z "$WAYLAND_DISPLAY" ]] && [[ -d /run/user/$UID ]]; then
          for sock in /run/user/$UID/wayland-*; do
            if [[ -S "$sock" ]]; then
              export WAYLAND_DISPLAY=$(basename "$sock")
              break
            fi
          done
        fi

        # Symlink dotfiles from g repo if available
        if [[ -d ~/git/bernadinm/g ]]; then
          [[ ! -e ~/.ssh ]] && [[ -d ~/git/bernadinm/g/.ssh ]] && ln -s ~/git/bernadinm/g/.ssh ~/.ssh
          [[ ! -e ~/.gnupg ]] && [[ -d ~/git/bernadinm/g/.gnupg ]] && ln -s ~/git/bernadinm/g/.gnupg ~/.gnupg
          [[ ! -e ~/.gitconfig ]] && [[ -f ~/git/bernadinm/g/.gitconfig ]] && ln -s ~/git/bernadinm/g/.gitconfig ~/.gitconfig
          [[ ! -e ~/.pureline.conf ]] && [[ -f ~/git/bernadinm/g/.pureline.conf ]] && ln -s ~/git/bernadinm/g/.pureline.conf ~/.pureline.conf
        fi

        # Starship prompt is enabled via home-manager programs.starship

        # Navi cheatsheet (only in interactive shells - has bind commands)
        if [[ $- == *i* ]] && test -f "$HOME/.config/navi/.navi.plugin.bash"; then
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
        {
          plugin = sensible;
          # Set PATH before any plugins run - NixOS needs this for run-shell commands
          extraConfig = ''
            set-environment -g PATH "/run/wrappers/bin:/home/miguel/.nix-profile/bin:/nix/profile/bin:/home/miguel/.local/state/nix/profile/bin:/etc/profiles/per-user/miguel/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/home/miguel/.local/bin"
          '';
        }
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-strategy-vim 'session'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
            set -g @continuum-boot 'on'
            # Set status-right here so continuum can hook into it (must be before run-shell)
            set -g status-right '#{continuum_status} #[fg=white,bg=default]%a%l:%M:%S %p#[default] #[fg=blue]%Y-%m-%d'
          '';
        }
        yank
      ];
      extraConfig = builtins.readFile ../dotfiles/.tmux.conf;
    };

    # Starship prompt - Tokyo Night theme
    # https://starship.rs/presets/tokyo-night
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        format = lib.concatStrings [
          "[░▒▓](#a3aed2)"
          "[  ](bg:#a3aed2 fg:#090c0c)"
          "[](bg:#769ff0 fg:#a3aed2)"
          "$directory"
          "[](fg:#769ff0 bg:#394260)"
          "$git_branch"
          "$git_status"
          "[](fg:#394260 bg:#212736)"
          "$nodejs"
          "$rust"
          "$golang"
          "$python"
          "[](fg:#212736 bg:#1d2230)"
          "$time"
          "[ ](fg:#1d2230)"
          "\n$character"
        ];
        directory = {
          style = "fg:#e3e5e5 bg:#769ff0";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };
        "directory.substitutions" = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
        git_branch = {
          symbol = "";
          style = "bg:#394260";
          format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
        };
        git_status = {
          style = "bg:#394260";
          format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
        };
        nodejs = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };
        rust = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };
        golang = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };
        python = {
          symbol = "";
          style = "bg:#212736";
          format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
        };
        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:#1d2230";
          format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
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
