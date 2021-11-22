{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    iperf
    htop
    iotop
    dstat
    sysstat
    procps
    coreutils
    perf-tools
    tcpdump
    atop
    pcstat
    ethtool
    tiptop
    geekbench
    pciutils
    ncdu

    # crypto mon
    cointop
  ];
}
