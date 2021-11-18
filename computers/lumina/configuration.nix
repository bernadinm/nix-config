# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixos-unstable> { config = baseconfig; };
  kubeMasterIP = "192.168.1.24";
  #kubeMasterHostname = "api.k8s.lumina.miguel.engineer";
  kubeMasterHostname = "localhost";
  kubeMasterAPIServerPort = 8443;
  keyCloakHttpPort = 8081;
  keyCloakHttpsPort = 8445;
in
#let
  #  unstable = import
  #    (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/master)
  #    # reuse the current configuration
  #    { config = config.nixpkgs.config; };
  #in
  #{
  #  environment.systemPackages = with pkgs; [
  #    x2goserver
  #    unstable.certbot
  #  ];
  #}
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <nixos-unstable/nixos/modules/services/networking/nebula.nix>
      # <nixos-unstable/nixos/modules/services/web-apps/keycloak.nix>
    ];
  disabledModules = [
    "services/networking/nebula.nix"
    # "services/web-apps/keycloak.nix"
  ];
  nixpkgs.config = baseconfig // {
    packageOverrides = pkgs: {
      #nebula = unstable.nebula;
      #  keycloak = unstable.keycloak;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay";
  virtualisation.libvirtd.enable = true; # qemu/kvm

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  boot.initrd.luks.devices.nixos.device = "/dev/disk/by-uuid/0ec6024a-636d-4736-a299-83b3c071d9a9";
  boot.initrd.luks.devices.nixos.preLVM = true;
  services.ddclient = { enable = true; configFile = "/home/miguel/configs/ddclient/ddclient.conf"; }; # dynamicdns
  services.xserver.videoDrivers = [ "nvidia" ];
  # nixpkgs.config.allowUnfree = true;

  # Setting the hostname of NixOS
  networking.hostName = "Lumina";
  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        rofi
        clipit
        xorg.xprop
        xautolock # timer to lock screen
        i3status # gives you the default i3 status bar
        i3lock-fancy-rapid #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
        compton
        lxqt.compton-conf

        feh # wallpaper manager
        vifm # graphic file manager
      ];
    };
  };

  ## Enable the X11 windowing system.
  #services.xserver.enable = true;

  ## Enable the Plasma 5 Desktop Environment.
  ## services.xserver.displayManager.sddm.enable = true;
  #services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.pantheon.enable = true;
  #services.openvpn.servers = {
  #  protonVPNsecureUSAswissTCP  = { config = '' config /home/miguel/Creds/protonvpn/ch-us-01.protonvpn.com.tcp.ovpn '';
  #                                  updateResolvConf = true; 
  #                                  #autoStart = false;
  #              };
  #};

  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n";
  };

  services.bind = {
    enable = true;
    extraConfig = ''
      include "/var/lib/secrets/dnskeys.conf";
    '';
    zones = [
      rec {
        name = "lumina.miguel.engineer";
        file = "/var/db/bind/${name}";
        master = true;
        extraConfig = "allow-update { key rfc2136key.lumina.miguel.engineer.; };";
      }
    ];
  };

  ## Now we can configure ACME
  #security.acme.acceptTerms = true;
  #security.acme.email = "admin+acme@example.com";
  #security.acme.certs."example.com" = {
  #  domain = "*.example.com";
  #  dnsProvider = "rfc2136";
  #  credentialsFile = "/var/lib/secrets/certs.secret";
  #  # We don't need to wait for propagation since this is a local DNS server
  #  dnsPropagationCheck = false;
  #};

  # This didnt work below |
  #security.acme = {
  #  acceptTerms = true;
  #  certs."lumina.miguel.engineer" = {
  #    email = "miguel@capitalblockchain.group";
  #    domain = "*.lumina.miguel.engineer";
  #    dnsProvider = "rfc2136";
  #    credentialsFile = "/var/lib/secrets/certs.secret";
  #    # We don't need to wait for propagation since this is a local DNS server
  #    dnsPropagationCheck = false;
  #  };
  #};
  # This didnt work above |

  services.nginx.enable = true;
  #services.nginx.virtualHosts."lumina.miguel.engineer" = {
  #    forceSSL = true;
  #    enableACME = true;
  #    root = "/var/www/lumina.miguel.engineer";
  #};
  #services.nginx.virtualHosts."k8s.lumina.miguel.engineer" = {
  #    forceSSL = true;
  #    enableACME = true;
  #    #root = "/var/www/k8s.lumina.miguel.engineer";
  #    locations."/" = {
  #      proxyPass = "http://localhost:${toString kubeMasterAPIServerPort}";
  #    };
  #};
  #services.nginx.virtualHosts."key.lumina.miguel.engineer" = {
  #    forceSSL = true;
  #    enableACME = true;
  #    #root = "/var/www/key.lumina.miguel.engineer";
  #    locations."/auth" = {
  #      proxyPass = "http://localhost:${toString keyCloakHttpPort}";
  #    };
  #};
  #services.nginx.virtualHosts."nebula.lumina.miguel.engineer" = {
  #    forceSSL = true;
  #    enableACME = true;
  #    #root = "/var/www/nebula.lumina.miguel.engineer";
  #};
  #security.acme.acceptTerms = true;
  #security.acme.email = "miguel@capitalblockchain.group";
  #security.acme.certs = {
  #  lumina-miguel-engineer = {
  #    #credentialvarle = "/home/miguel/Sites/bernadinm/infra/lumina.key";
  #    email = "miguel@capitalblockchain.group";
  #    directory = "/var/lib/acme/lumina.miguel.engineer";
  #    dnsPropagationCheck = true;
  #    dnsProvider = null;
  #    domain = "key.lumina.miguel.engineer";
  #    #extraDomains = { };
  #    keyType = "ec384";
  #    #postRun = "systemctl restart lumina.service";
  #    server = null;
  #    webroot = "/var/lib/acme/acme-challenge";
  #  };
  #  key-lumina-miguel-engineer = {
  #    #credentialvarle = "/home/miguel/Sites/bernadinm/infra/lumina.key";
  #    email = "miguel@capitalblockchain.group";
  #    directory = "/var/lib/acme/key.lumina.miguel.engineer";
  #    dnsPropagationCheck = true#;
  #    dnsProvider = null;
  #    domain = "key.lumina.miguel.engineer";
  #    #extraDomains = { };
  #    keyType = "ec384";
  #    #postRun = "systemctl restart lumina.service";
  #    server = null;
  #    webroot = "/var/lib/acme/acme-challenge";
  #  };
  #  k8s-lumina-miguel-engineer = {
  #    #credentialvarle = "/home/miguel/Sites/bernadinm/infra/lumina.k8s";
  #    email = "miguel@capitalblockchain.group";
  #    directory = "/var/lib/acme/k8s.lumina.miguel.engineer";
  #    dnsPropagationCheck = true;
  #    dnsProvider = null;
  #    domain = "k8s.lumina.miguel.engineer";
  #    extraDomainNames = [ "api.k8s.lumina.miguel.engineer" ];
  #    #extraDomains = { };
  #    keyType = "ec384";
  #    #postRun = "systemctl restart lumina.service";
  #    server = null;
  #    webroot = "/var/lib/acme/acme-challenge";
  #  };
  #  nebula-lumina-miguel-engineer = {
  #    email = "miguel@capitalblockchain.group";
  #    directory = "/var/lib/acme/nebula.lumina.miguel.engineer";
  #    dnsPropagationCheck = true;
  #    domain = "nebula.lumina.miguel.engineer";
  #    keyType = "rsa2048";
  #    server = null;
  #    webroot = "/var/lib/acme/acme-challenge";
  #  };
  #};

  #services.nebula.networks = {
  #  "lumina.miguel.engineer" = {
  #    enable = true;
  #    ca = "/home/miguel/Sites/slackhq/nebula/ca.crt";
  #    cert = "/home/miguel/Sites/slackhq/nebula/lighthouse-lumina.crt";
  #    key = "/home/miguel/Sites/slackhq/nebula/lighthouse-lumina.key";
  #    firewall.inbound = [ { port = "any"; proto = "any"; host = "any"; } ];
  #    firewall.outbound = [ { port = "any"; proto = "any"; host = "any"; } ];
  #    isLighthouse = true;
  #  };
  #};

  # resolve master hostname
  # networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
  services.kubernetes = {
    roles = [ "master" "node" ];
    masterAddress = kubeMasterHostname;
    apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
    easyCerts = true;
    #caFile = "/var/lib/acme/k8s-lumina-miguel-engineer/fullchain.pem";
    apiserver = {
      securePort = kubeMasterAPIServerPort;
      advertiseAddress = kubeMasterIP;
    };

    # use coredns
    addons.dns.enable = true;

    # needed if you use swap
    kubelet.extraOpts = "--fail-swap-on=false";
  };

  #security.pki.certificateFiles = [ "/var/lib/acme/nebula-lumina-miguel-engineer/" ];

  #services.lighttpd = {
  #  enable = true;
  #  port = 80;
  #  document-root = "/var/www";
  #};

  #system.activationScripts.create-srv-dir = ''
  #  echo "ensuring ${config.services.lighttpd.document-root}" exists...
  #  mkdir -p ${config.services.lighttpd.document-root}
  #'';

  #security.acme = {
  #  certs.${config.networking.domain} = {
  #    webroot = "/var/www";
  #    email = "you@example.com";
  #  };
  #};

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  services.avahi.enable = true; # sometimes needed for finding on network
  services.avahi.nssmdns = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };

  # Long story short - after about an hour of research and 
  # trying things I added this udev rules to enable Steam 
  # to have permissions to use the device.
  # https://edofic.com/posts/2020-06-07-linux-gaming/
  #services.udev.extraRules = ''
  #  # DualShock 4 over bluetooth hidraw
  #  KERNEL=="hidraw*", KERNELS=="*054C:05C4*", MODE="0666"
  #'';

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver = {
    libinput.touchpad.naturalScrolling = true;
    libinput.enable = true;
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "i2c" ]; # Enable ‘sudo’ for the user.
    description = "Miguel Bernadin";
  };

  users.users.rachelle = {
    isNormalUser = true;
    extraGroups = [ ]; # Enable ‘sudo’ for the user.
    description = "Rachelle Bernadin";
  };

  services.teamviewer.enable = true;
  hardware.acpilight.enable = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    unzip
    python3
    python37Packages.virtualenv
    python37Packages.pip
    gcc
    libffi
    python37Packages.pillow
    python37Packages.setuptools
    git
    bash
    xclip
    google-chrome
    glib
    ddcutil
    i2c-tools
    eidolon
    terraform
    zoom-us
    fast-cli
    libinput-gestures
    docker-compose
    pcmanfm
    gspeech
    lynx
    whois
    trash-cli
    gnumake
    geekbench
    xsel
    mimic
    picotts
    discord
    bind
    ag
    ripgrep
    tigervnc
    aria
    killall
    w3m-full
    openssl
    bc
    gh
    nnn
    nixpkgs-fmt

    # Kubernetes
    kompose
    kubectl
    kubernetes

    virt-manager

    ardour

    #(import (builtins.fetchTarball https://github.com/hercules-ci/arion/tarball/master) {}).arion

    # wineWowPackages.staging
    # (winetricks.override {
    #   wine = wineWowPackages.staging;
    # })
    wineWowPackages.full
    winetricks
    sc-controller
    steam-run
    vulkan-tools
    minecraft
    multimc
    lutris
    krb5
    unstable.x2goserver
    x2goclient
    mumble
    weechat
    profanity
    ncdu

    betaflight-configurator

    electrum
    electron-cash
    ledger-live-desktop
    monero-gui
    nodejs_latest


    torbrowser
    chromium

    openvpn

    kdeplasma-addons
    kdeconnect
    kdenlive
    okular
    yakuake
    termite
    konversation
    fusuma
    gwenview
    navi
    spectacle
    kile
    (texlive.combine {
      inherit (texlive) scheme-small titling collection-langfrench cm-super;
    })

    gimp
    libreoffice
    vlc

    go
    goaccess

    pass

    protonvpn-cli
    protonvpn-gui

    # Fonts
    font-awesome

    # monitoring
    cointop
    htop

    # ML
    gpt2tc

    # base
    gcsfuse
    google-cloud-sdk
    colordiff
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  #services.ddccontrol.enable = false;
  hardware.i2c.enable = true;
  #hardware.i2c.enable = false;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "plasmashell";
  #services.xrdp.defaultWindowManager = "${pkgs.xfce4-12.xfce4-session}/bin/xfce4-session";
  # Open ports in the firewall.

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.allowedTCPPortRanges = [ 
  #  { from = 1714; to = 1764; } # KDE Connect
  # ];
  # networking.firewall.allowedUDPPortRanges = [ 
  #  { from = 1714; to = 1764; } # KDE Connect
  # ];
  # networking.firewall.enable = false;
  networking.enableIPv6 = false;
  networking.firewall.allowedTCPPorts = [ 3389 80 443 4242 ];
  networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
  networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }];

  #services.keycloak = {
  #  enable = true;
  #  #frontendUrl = "key.lumina.miguel.engineer/auth";
  #  frontendUrl = "localhost";
  #  #forceBackendUrlToFrontendUrl = true;
  #  #sslCertificate = "/var/lib/acme/key-lumina-miguel-engineer/fullchain.pem";
  #  #sslCertificateKey = "/var/lib/acme/key-lumina-miguel-engineer/key.pem";
  #  database.passwordFile = "/run/keys/db_password";
  #  httpPort = "${toString keyCloakHttpPort}";
  #  httpsPort = "${toString keyCloakHttpsPort}";
  #};

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  #  security.sudo.extraRules = [
  #    { users = [ "miguel" ];
  #      commands = [
  #        { command = "${pkgs.protonvpn-cli}/bin/protonvpn";
  #          options = [ "NOPASSWD" ];
  #        }
  #      ];
  #    }
  #  ];

  #services.openvpn.providers.protonvpn = {
  #  # The path to the file containing your credentials.
  #  credentials = /home/miguel/Creds/protonvpn/login;
  #
  #  # The list of available regions can be found in the regions.nix file
  #  countries = [
  #    { region = "fr"; }
  #    { region = "us"; autoStart = true;  }
  #    { region = "ca"; }
  #  ];
  #};


  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Install the flakes edition
  nix.package = pkgs.nixFlakes;
  # Enable the nix 2.0 CLI and flakes support feature-flags
  nix.extraOptions = ''
    experimental-features = nix-command flakes 
  '';

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
   alias ncdu="docker run -it -v /:/mount bernadinm/ncdu /mount"
   alias matrix='echo -e "1"; while $t; do for i in `seq 1 40`;do r="$[($RANDOM % 2)]";h="$[($RANDOM % 4)]";if [ $h -eq 1 ]; then v="0 $r";else v="1 $r";fi;v2="$v2 $v";done;echo -e $v2 | GREP_COLOR="1;32" grep --color "[^ ]";v2=""; sleep .01;done;'

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
  

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
  #system.stateVersion = "21.11"; # Did you read the comment?
  #system.autoUpgrade.enable = true;
  #system.autoUpgrade.allowReboot = true;
}

