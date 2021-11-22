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
{
  environment.systemPackages = with pkgs; [
    # base
    docker-compose

    # Kubernetes
    kompose
    kubectl
    kubernetes

    virt-manager
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay";
  virtualisation.libvirtd.enable = true; # qemu/kvm

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

}