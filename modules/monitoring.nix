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
    dool
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
    gotop
    s-tui

    # crypto mon
    cointop

    # visualizer
    cava # music visualizer
    projectm # music visualizer

    lshw # hw probe
    dmidecode # hw probe
  ];

  # High-speed web-based traffic analysis and flow collection tool
  # services.ntopng.enable = true;
}
