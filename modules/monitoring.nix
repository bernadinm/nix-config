{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    iperf
    htop
    gtop
    bmon
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
    glances
    bandwhich

    # crypto mon
    cointop

    # visualizer
    cava # music visualizer
    projectm # music visualizer

    lshw # hw probe
    dmidecode # hw probe
  ];
}
