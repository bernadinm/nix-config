{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    iperf
    htop
    gtop
    iotop
    bottom
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
    lsof

    # crypto mon
    cointop

    # visualizer
    cava # music visualizer
    projectm # music visualizer
  ];
}
