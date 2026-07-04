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

    # Starship prompt - Catppuccin Powerline theme
    # https://starship.rs/presets/catppuccin-powerline
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        format = lib.concatStrings [
          "[](red)"
          "$os"
          "$username"
          "[](bg:peach fg:red)"
          "$directory"
          "[](bg:yellow fg:peach)"
          "$git_branch"
          "$git_status"
          "[](fg:yellow bg:green)"
          "$c"
          "$rust"
          "$golang"
          "$nodejs"
          "$php"
          "$java"
          "$kotlin"
          "$haskell"
          "$python"
          "[](fg:green bg:sapphire)"
          "$conda"
          "[](fg:sapphire bg:lavender)"
          "$time"
          "[](fg:lavender bg:blue)"
          "$battery"
          "[ ](fg:blue)"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];
        palette = "catppuccin_mocha";
        os = {
          disabled = false;
          style = "bg:red fg:crust";
          symbols = {
            Windows = "";
            Ubuntu = "󰕈";
            Macos = "󰀵";
            Linux = "󰌽";
            Arch = "󰣇";
            Debian = "󰣚";
            Fedora = "󰣛";
            NixOS = "";
          };
        };
        username = {
          show_always = true;
          style_user = "bg:red fg:crust";
          style_root = "bg:red fg:crust";
          format = "[ $user]($style)";
        };
        directory = {
          style = "bg:peach fg:crust";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
          substitutions = {
            Documents = "󰈙 ";
            Downloads = " ";
            Music = "󰝚 ";
            Pictures = " ";
          };
        };
        git_branch = {
          symbol = "";
          style = "bg:yellow";
          format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
        };
        git_status = {
          style = "bg:yellow";
          format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
        };
        nodejs = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        c = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        rust = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        golang = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        php = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        java = {
          symbol = " ";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        kotlin = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        haskell = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        python = {
          symbol = "";
          style = "bg:green";
          format = "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
        };
        conda = {
          symbol = "  ";
          style = "fg:crust bg:sapphire";
          format = "[$symbol$environment ]($style)";
          ignore_base = false;
        };
        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:lavender";
          format = "[[  $time ](fg:crust bg:lavender)]($style)";
        };
        line_break = {
          disabled = true;
        };
        character = {
          disabled = false;
          success_symbol = "[❯](bold fg:green)";
          error_symbol = "[❯](bold fg:red)";
          vimcmd_symbol = "[❮](bold fg:green)";
        };
        cmd_duration = {
          format = " in $duration ";
          style = "bg:lavender";
          disabled = false;
        };
        battery = {
          full_symbol = "󰚥";
          charging_symbol = "󰚥";
          discharging_symbol = "󰁹";
          format = "[[ $symbol$percentage ](fg:crust bg:blue)]($style)";
          display = [
            {
              threshold = 100;
              style = "bg:blue";
            }
            {
              threshold = 30;
              style = "bg:blue fg:yellow";
            }
            {
              threshold = 15;
              style = "bg:blue bold fg:red";
            }
          ];
        };
        palettes = {
          catppuccin_mocha = {
            rosewater = "#f5e0dc";
            flamingo = "#f2cdcd";
            pink = "#f5c2e7";
            mauve = "#cba6f7";
            red = "#f38ba8";
            maroon = "#eba0ac";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            sky = "#89dceb";
            sapphire = "#74c7ec";
            blue = "#89b4fa";
            lavender = "#b4befe";
            text = "#cdd6f4";
            subtext1 = "#bac2de";
            subtext0 = "#a6adc8";
            overlay2 = "#9399b2";
            overlay1 = "#7f849c";
            overlay0 = "#6c7086";
            surface2 = "#585b70";
            surface1 = "#45475a";
            surface0 = "#313244";
            base = "#1e1e2e";
            mantle = "#181825";
            crust = "#11111b";
          };
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
