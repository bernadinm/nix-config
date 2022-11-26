{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
in
{
  environment.systemPackages = with pkgs; [
    # base
    gnupg
    paperkey
    pinentry

    # crypto 
    electrum
    electron-cash
    ledger-live-desktop
    monero-gui

    # VPN
    porcupine.protonvpn-cli
    porcupine.protonvpn-gui
    openvpn

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

    yubikey-manager # yubikey
    yubikey-personalization # yubikey
  ];

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

  #services.nginx.enable = true;
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
  networking.firewall.allowedTCPPorts = [ 80 443 4242 ]; # http https nebula
  networking.firewall.trustedInterfaces = [ "nebula.mesh" ];
  # networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }]; # kde
  # networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }]; # kde

  # Internal Private Mesh Network
  services.nebula.networks.mesh = {
    enable = true;
    ca = "/home/miguel/git/slackhq/nebula/ca.crt";
    cert = "/home/miguel/git/slackhq/nebula/server.crt";
    key = "/home/miguel/git/slackhq/nebula/server.key";
    firewall.inbound = [{ port = "any"; proto = "any"; host = "any"; }];
    firewall.outbound = [{ port = "any"; proto = "any"; host = "any"; }];
  };

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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

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
