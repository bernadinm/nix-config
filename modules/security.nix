{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    gnupg
    pinentry

    # crypto 
    electrum
    electron-cash
    ledger-live-desktop
    monero-gui

    # VPN
    protonvpn-cli
    protonvpn-gui
    openvpn

    # password management
    pass

    # log analyzer
    goaccess

    # encryption
    openssl
    step-cli

    # port analyzer
    rustscan
    nmap

    # network probe
    tshark # terminal wshark
    wireshark # gui wshark
  ];

  # Block failed login attempts from SSH 
  services.fail2ban.enable = true;

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

  # Internal Private Mesh Network
  services.nebula.networks.hamachi = {
      enable = true;
      cert = "/home/miguel/git/slackhq/nebula/server.crt";
      key = "/home/miguel/git/slackhq/nebula/server.key";
      firewall.inbound = [ { port = "any"; proto = "any"; host = "any"; } ];
      firewall.outbound = [ { port = "any"; proto = "any"; host = "any"; } ];
  };

  services.teamviewer.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
