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
    dockstarter

    # docker-compose alternative
    #(import (builtins.fetchTarball https://github.com/hercules-ci/arion/tarball/master) {}).arion

    samba

    # Kubernetes
    kompose
    kubectl
    kubernetes
    minikube

    # AI
    ollama # llm local models

    flyctl # cloud cli
    doctl # digital ocean cli
    awscli2 # aws cli
    ssm-session-manager-plugin # aws cli plugin
    railway # railway cloud cli

    anbox # android

    virt-manager

    flintlock # microvm
    # vagrant # vm cli

    # unstable.vmware-workstation # vmware virt
  ];

  nixpkgs.config = baseconfig // {
    packageOverrides = pkgs: {
      #nebula = unstable.nebula;
      #  keycloak = unstable.keycloak;
    };
  };

  # TODO(bernadinm): enable when I migrate from i3wm -> sway
  # virtualisation.waydroid.enable = true;
  # virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "overlay2";
  virtualisation.virtualbox.host.enable = false;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.extraGroups.vboxusers.members = [ "miguel" ];
  virtualisation.libvirtd.enable = true; # qemu/kvm
  services.nfs.server.enable = true; # vagrant

  # resolve master hostname
  # networking.extraHosts = "${kubeMasterIP} ${kubeMasterHostname}";
  #services.kubernetes = {
  #  roles = [ "master" "node" ];
  #  masterAddress = kubeMasterHostname;
  #  apiserverAddress = "https://${kubeMasterHostname}:${toString kubeMasterAPIServerPort}";
  #  easyCerts = true;
  #  #caFile = "/var/lib/acme/k8s-lumina-miguel-engineer/fullchain.pem";
  #  apiserver = {
  #    securePort = kubeMasterAPIServerPort;
  #    advertiseAddress = kubeMasterIP;
  #  };
  #
  #  # use coredns
  #  addons.dns.enable = true;
  #
  #  # needed if you use swap
  #  kubelet.extraOpts = "--fail-swap-on=false";
  #};

}
