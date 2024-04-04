{ config, pkgs, ... }:

let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";
in
{
  imports =
    [
      ../modules/adblock.nix
      (import "${home-manager}/nixos")
    ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "input" "video" "i2c" "vboxusers" "libvirtd" "fuse" ]; # Enable ‘sudo’ for the user.
    description = "Miguel Bernadin";
  };
  users.users.rachelle = {
    isNormalUser = true;
    extraGroups = [ ]; # Enable ‘sudo’ for the user.
    description = "Rachelle Bernadin";
  };

  # Enable the services
  home-manager.users.miguel.home.file.".local/share/nvim/site/autoload/plug.vim".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim";
    sha256 = "sha256-4tvXyNcyrnl+UFnA3B6WS5RSmjLQfQUdXQWHJ0YqQ/0=";
  };

  home-manager.users.miguel.home.file =
    {
      ".config/navi/.navi.plugin.bash".source =
        ../dotfiles/navi/.navi.plugin.bash;
      ".config/helix/config.toml".source =
        ../dotfiles/.config/helix/config.toml;
      ".config/termite/config".source =
        ../dotfiles/.config/termite/config;
      ".config/tiny/config.yml".source =
        ../dotfiles/.config/tiny/config.yml;
      ".ssh/authorized_keys".source =
        ../dotfiles/.ssh/authorized_keys;
      ".gnupg/sshcontrol".source =
        ../dotfiles/.gnupg/sshcontrol;
      ".tmux.conf".source =
        ../dotfiles/.tmux.conf;
      ".bashrc".source =
        ../dotfiles/.bashrc;
      ".vimrc".source =
        ../dotfiles/.vimrc;
      ".launch_notion.sh".source =
        ../dotfiles/.launch_notion.sh;
      ".launch_logseq.sh".source =
        ../dotfiles/.launch_logseq.sh;
      ".launch_instagram.sh".source =
        ../dotfiles/.launch_instagram.sh;
      ".launch_youtube.sh".source =
        ../dotfiles/.launch_youtube.sh;
      ".launch_music.sh".source =
        ../dotfiles/.launch_music.sh;
      ".launch_googlefi.sh".source =
        ../dotfiles/.launch_googlefi.sh;
      ".launch_gmail.sh".source =
        ../dotfiles/.launch_gmail.sh;
      ".launch_whatsapp.sh".source =
        ../dotfiles/.launch_whatsapp.sh;
      ".launch_businessmail.sh".source =
        ../dotfiles/.launch_businessmail.sh;
      ".launch_bible.sh".source =
        ../dotfiles/.launch_bible.sh;
      ".launch_github.sh".source =
        ../dotfiles/.launch_github.sh;
      ".launch_googlekeep.sh".source =
        ../dotfiles/.launch_googlekeep.sh;
      ".launch_protonmail.sh".source =
        ../dotfiles/.launch_protonmail.sh;
      ".launch_drive.sh".source =
        ../dotfiles/.launch_drive.sh;
      ".launch_chatgpt.sh".source =
        ../dotfiles/.launch_chatgpt.sh;
      ".launch_ai.sh".source =
        ../dotfiles/.launch_ai.sh;
      ".battery_check.sh".source =
        ../dotfiles/scripts/battery_check.sh;
      ".modern_alert.wav".source =
        ../dotfiles/scripts/modern_alert.wav;
      ".config/nvim/coc-settings.json".source =
        ../dotfiles/vim/coc-settings.json;
    };

  home-manager.users.miguel.home.file.".config/base16-shell" = {
    recursive = true;
    source = pkgs.fetchFromGitHub {
      owner = "chriskempson";
      repo = "base16-shell";
      rev = "ce8e1e540367ea83cc3e01eec7b2a11783b3f9e1";
      sha256 = "sha256-OMhC6paqEOQUnxyb33u0kfKpy8plLSRgp8X8T8w0Q/o=";
    };
  };
  home-manager.users.miguel.home.stateVersion = "22.11";
  home-manager.users.rachelle.home.stateVersion = "22.11";
  home-manager.users.miguel.programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;
    extraPython3Packages = (ps: with ps; [
      black
      flake8
    ]);
    withRuby = true;
    extraConfig = builtins.readFile ../dotfiles/vim/init.vim;
    extraPackages = with pkgs; [
      pkgs.fzf
    ];
    plugins = with pkgs.vimPlugins; let
      # ap/vim-buftabline
      buftabline = pkgs.vimUtils.buildVimPlugin {
        name = "buftabline";
        src = pkgs.fetchFromGitHub {
          owner = "ap";
          repo = "vim-buftabline";
          rev = "73b9ef5dcb6cdf6488bc88adb382f20bc3e3262a";
          sha256 = "1vs4km7fb3di02p0771x42y2bsn1hi4q6iwlbrj0imacd9affv5y";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-agriculture = pkgs.vimUtils.buildVimPlugin {
        name = "vim-agriculture";
        src = pkgs.fetchFromGitHub {
          owner = "jesseleite";
          repo = "vim-agriculture";
          rev = "1095d907930fc545f88541b14e5ea9e34d63c40f";
          sha256 = "11xkiqm26y9szmh1isgvdlycblb9y651q6amws26il96a5kf346s";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      nerdtree-buffer-ops = pkgs.vimUtils.buildVimPlugin {
        name = "nerdtree-buffer-ops";
        src = pkgs.fetchFromGitHub {
          owner = "PhilRunninger";
          repo = "nerdtree-buffer-ops";
          rev = "bd0cd6bd6db38d1641d24fc5d4c65e066eb0781b";
          sha256 = "0hfs08jlwkkficlkyzscbbzqxink6qmps4ca70q9zmq121y1yzlj";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-diff-enhanced = pkgs.vimUtils.buildVimPlugin {
        name = "vim-diff-enhanced";
        src = pkgs.fetchFromGitHub {
          owner = "chrisbra";
          repo = "vim-diff-enhanced";
          rev = "c6d4404251206fbb21ef6524b8a24d859097e689";
          sha256 = "0ixhbcmih8r1sjzj3hy8jl6wz7ip0xz72q0682i2vlccgx0bm92a";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-hclfmt = pkgs.vimUtils.buildVimPlugin {
        name = "vim-hclfmt";
        src = pkgs.fetchFromGitHub {
          owner = "fatih";
          repo = "vim-hclfmt";
          rev = "1f3caf11253af6870451eb2af35b5616809cbc80";
          sha256 = "1w4naprdf2g5i7r9d200kvxcqaqs6538g45jdn45vvxfbj4sfsfl";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      Vim-Jinja2-Syntax = pkgs.vimUtils.buildVimPlugin {
        name = "Vim-Jinja2-Syntax";
        src = pkgs.fetchFromGitHub {
          owner = "Glench";
          repo = "Vim-Jinja2-Syntax";
          rev = "2c17843b074b06a835f88587e1023ceff7e2c7d1";
          sha256 = "13mfzsw3kr3r826wkpd3jhh1sy2j10hlj1bv8n8r01hpbngikfg7";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      html5.vim = pkgs.vimUtils.buildVimPlugin {
        name = "html5.vim";
        src = pkgs.fetchFromGitHub {
          owner = "othree";
          repo = "html5.vim";
          rev = "7c9f6f38ce4f9d35db7eeedb764035b6b63922c6";
          sha256 = "1hgbvdpmn3yffk5ahz7hz36a7f5zjc1k3pan5ybgncmdq9f4rzq6";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      # evanleck/vim-svelte/archive/5f88e5a0fe7dcece0008dae3453edbd99153a042
      vim-mustache-handlebars = pkgs.vimUtils.buildVimPlugin {
        name = "vim-mustache-handlebars";
        src = pkgs.fetchFromGitHub {
          owner = "mustache";
          repo = "vim-mustache-handlebars";
          rev = "fcc1401c2f783c14314ef22517a525a884c549ac";
          sha256 = "01nkd89dzjw8cqs2zv7hwwgljxs53dxqfv774kswmz5g198vxf7d";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-jsx = pkgs.vimUtils.buildVimPlugin {
        name = "vim-jsx";
        src = pkgs.fetchFromGitHub {
          owner = "mxw";
          repo = "vim-jsx";
          rev = "8879e0d9c5ba0e04ecbede1c89f63b7a0efa24af";
          sha256 = "0czjily7kjw7bwmkxd8lqn5ncrazqjsfhsy3sf2wl9ni0r45cgcd";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      yajs-vim = pkgs.vimUtils.buildVimPlugin {
        name = "yajs-vim";
        src = pkgs.fetchFromGitHub {
          owner = "othree";
          repo = "yajs.vim";
          rev = "2bebc45ce94d02875803c67033b2d294a5375064";
          sha256 = "15ky34nbv0wa9jq92hm7ya4s05zgippkcifd3m8s59n0dy5lkpc0";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-svelte = pkgs.vimUtils.buildVimPlugin {
        name = "vim-svelte";
        src = pkgs.fetchFromGitHub {
          owner = "evanleck";
          repo = "vim-svelte";
          rev = "5f88e5a0fe7dcece0008dae3453edbd99153a042";
          sha256 = "0p941kcqnv4wgcybmhnpzrvxm2y9d2fkd4n186zav7mwfzn736jq";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
      vim-glaive = pkgs.vimUtils.buildVimPlugin {
        name = "vim-glaive";
        src = pkgs.fetchFromGitHub {
          owner = "google";
          repo = "vim-glaive";
          rev = "c17bd478c1bc358dddf271a13a4a025efb30514d";
          sha256 = "0py6wqqnblr4n1xz1nwlxp0l65qmd76448gz0bf5q9a1sf0mkh5g";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out
          cp -r ./ $out
        '';
      };
    in
    [
      vim-rooter
      base16-vim
      buftabline
      fzf-vim
      fzfWrapper
      # Does not change panes windows when closing buffers
      vim-bufkill
      nerdtree
      ultisnips
      vim-surround
      splitjoin-vim
      vim-multiple-cursors
      vim-easymotion
      tcomment_vim
      delimitMate
      vim-gh-line
      vim-signify
      vim-rhubarb
      vim-fugitive
      # Highlight opened buffers in nerdtree, close buffer with 'w'
      nerdtree-buffer-ops
      vim-diff-enhanced
      committia-vim
      Jenkinsfile-vim-syntax
      vim-terraform
      vim-hclfmt
      nginx-vim
      Vim-Jinja2-Syntax
      html5.vim
      vim-json
      vim-mustache-handlebars
      vim-graphql
      vim-hcl
      vim-go
      rust-vim
      emmet-vim
      yats-vim
      vim-jsx
      yajs-vim
      vim-jsx-typescript
      vim-svelte
      vim-markdown
      # semshi
      vim-nix
      vim-maktaba
      vim-codefmt
      vim-glaive
      tokyonight-nvim
      vim-bazel
      telescope-nvim
      telescope-fzf-native-nvim
    ];
  };

  fonts.packages = with pkgs; [
    montserrat
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  environment.systemPackages = with pkgs; [
    # base
    yarn # used for home manager neovim
    xclip # clipboard history
    xsel # clipboard select
    xorg.xev # discover keybindings
    x2goclient # remote desktop client

    tor-browser-bundle-bin # browser
    chromium # browser
    google-chrome # browser
    brave # browser
    firefox # browser
    (firefox.override { nativeMessagingHosts = [ passff-host ]; })

    playerctl # music control

    font-awesome # font
    picom # window property changer

    feh # wallpaper manager

    scrot # screen capture
    screenfetch # used with scrot
    kazam # popup screen capture

    unclutter # hides mouse during inactivity

    # text file managers
    vifm # text file manager
    ranger # text file manager
    nnn # text file manager
    dolphin # gui file manager
    tree # directory list

    pavucontrol # visual sound control

    rofi # program launcher
    dmenu # program launcher
    dunst # system notification
    acpi # battery status
    libnotify # system notification

    spectacle # screenshot capture util
    (texlive.combine {
      inherit (texlive) scheme-small titling collection-langfrench cm-super;
    })

    # Plasma desktop
    kdeplasma-addons
    kdeconnect
    kdenlive
    okular # ebook epub pdf reader
    konversation
    fusuma
    kile # latex authoring tool for kde
    gwenview # gui file manager
  ];

  # San Francisco, California for Redshift for screen color changing
  location.provider = "manual";
  location.latitude = 37.773972;
  location.longitude = -122.431297;
  services.redshift = {
    enable = true;
    temperature = {
      day = 5500;
      night = 3200;
    };
  };

  # Allows services and hosts exposed on the local network via mDNS/DNS-SD
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  services.atd.enable = true;
  services.locate.enable = true;

  # TODO(bernadinm): add polybar dotfile config
  nixpkgs.config.packageOverrides = pkgs: {
    polybar = pkgs.polybar.override {
      alsaSupport = true;
      iwSupport = true;
      nlSupport = true;
      pulseSupport = true;
      mpdSupport = true;
    };
  };

  services.xserver = {
    enable = true;
    libinput.enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        rofi
        polybar
        libmpdclient # media player daemon client
        psensor # hardware temp sensor
        clipit
        xorg.xprop
        xautolock # timer to lock screen
        i3-layout-manager
        i3status # gives you the default i3 status bar
        i3lock-fancy-rapid #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
        raiseorlaunch # i3 app launcher
        xdotool # commandline automation for x11
        xorg.xwininfo # fetch window infomation

        picom # window property changer

        feh # wallpaper manager
        vifm # graphic file manager

        brightnessctl # brightness ctrl
      ];
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 60d";
  };

  # See: https://github.com/NixOS/nixpkgs/commit/224a6562a4880195afa5c184e755b8ecaba41536
  boot.loader.systemd-boot.configurationLimit = 50;

  hardware.bluetooth.enable = true; # enable bluethooth
  services.touchegg.enable = true; # enable multi touch gesture
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
