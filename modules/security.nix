{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
  unstable = import <nixos-unstable> { config = baseconfig; };
  hostname = config.networking.hostName;
in
{
  environment.systemPackages = with pkgs; [
    # base
    gnupg
    paperkey
    pinentry
    pinentry-rofi

    # crypto 
    electrum
    # electron-cash
    ledger-live-desktop
    monero-gui

    # VPN
    unstable.protonvpn-cli_2
    protonvpn-gui
    openvpn
    tailscale
    wireguard-tools

    # password management
    (pass.withExtensions (ext: with ext; [
      pass-otp
      pass-tomb
      pass-audit
      pass-import
      pass-update
      pass-genphrase
    ]))
    pass

    # log analyzer
    goaccess

    # encryption
    openssl
    step-cli
    tomb

    # port analyzer
    rustscan
    nmap

    # network probe
    # tshark # terminal wshark
    wireshark # gui wshark
    cloudflared # cloudflare tunnels

    yubikey-manager # yubikey
    yubikey-personalization # yubikey

    nftables # iptable alternative
    tor torsocks # security network
    tor-browser-bundle-bin # security network browser
  ];

  # Enable tailscale vpn
  services.tailscale.enable = true;
  services.tailscale.authKeyFile = "/run/secrets/tailscale_key";

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
  services.nginx.virtualHosts."ntop" = {
      #forceSSL = true;
      # enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:3000/";
      };
  };
  networking = {
    extraHosts = ''
      127.0.0.1 ntop.luna
    '';
  };
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
  #    #credentialvarle = "/home/miguel/git/bernadinm/infra/lumina.key";
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
  #    #credentialvarle = "/home/miguel/git/bernadinm/infra/lumina.key";
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
  #    #credentialvarle = "/home/miguel/git/bernadinm/infra/lumina.k8s";
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

  #    enable = true;
  #    ca = "/home/miguel/git/slackhq/nebula/ca.crt";
  #    cert = "/home/miguel/git/slackhq/nebula/lighthouse-lumina.crt";
  #    key = "/home/miguel/git/slackhq/nebula/lighthouse-lumina.key";
  #    firewall.inbound = [ { port = "any"; proto = "any"; host = "any"; } ];
  #    firewall.outbound = [ { port = "any"; proto = "any"; host = "any"; } ];
  #    isLighthouse = true;
  #  };
  #};

  # Open ports in the firewall.
  networking.enableIPv6 = false;
  networking.firewall.allowedTCPPorts = [ 80 443 4242 548 1714 1715 1716 2049 ]; # http https nebula AFP KDE-Connect nfs
  networking.firewall.allowedUDPPorts = [ 1714 1716 ]; # KDE Connect peer-to-peer communication
  networking.firewall.trustedInterfaces = [ "nebula.mesh" "wlp1s0"];
  networking.firewall.extraCommands = ''
  iptables -A nixos-fw -p tcp --source 192.168.1.0/24 --dport 22 -j nixos-fw-accept
  iptables -A nixos-fw -p tcp --source 192.168.1.0/24 --dport 80 -j nixos-fw-accept
  iptables -A nixos-fw -p tcp --source 192.168.1.0/24 --dport 443 -j nixos-fw-accept
  ''; # allow private connnectivity
  # networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }]; # kde
  # networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }]; # kde

  # Internal Private Mesh Network
  # TODO(bernadinm): Replace Mesh Network for Zero Trust
  # services.nebula.networks.mesh = {
  #   enable = true;
  #   ca = "/home/miguel/git/slackhq/nebula/ca.crt";
  #   cert = "/home/miguel/git/slackhq/nebula/server.crt";
  #   key = "/home/miguel/git/slackhq/nebula/server.key";
  #   firewall.inbound = [{ port = "any"; proto = "any"; host = "any"; }];
  #   firewall.outbound = [{ port = "any"; proto = "any"; host = "any"; }];
  # };

  services.teamviewer.enable = true;

  # Browser passwordstore native client
  programs.browserpass.enable = true;

  # Block failed login attempts from SSH 
  services.fail2ban.enable = true;

  # Enable Yubikey Smartcard Mode
  services.pcscd.enable = true;

  # Enable OpenSSH Server
  services.openssh = {
    enable = true;
    openFirewall = false; # keep this disabled but open through nebula.mesh
  };

  # Enable the Gnugp daemon instead of SSH.
  programs = {
    ssh.startAgent = false;
    ssh.extraConfig = ''
      Host github.com
          StrictHostKeyChecking no
    '';
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    #   # TODO(bernadinm): disabled curses in favor gnome3
    #   pinentryFlavor = "gnome3";
    # };
  };

  # environment.shellInit = ''
  #   gpg-connect-agent /bye
  #   export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  # '';

  # TODO(bernadinm): enable challenge-response logins with:
  # security.pam.yubico = {
  #   enable = true;
  #   debug = true;
  #   mode = "challenge-response";
  # };

  ## Audit all programs run
  ## TODO(bernadinm): disabling auditd for free space
  # security.auditd.enable = true;
  # security.audit.enable = true;
  # security.audit.rules = [
  #   "-a exit,always -F arch=b64 -S execve"
  # ];
}
