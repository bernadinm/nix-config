# Shared k3s control-plane load balancer, run identically on every
# control-plane node (orion, vega, rigel) as its own systemd service - not
# a k8s-scheduled pod, which would create a chicken-and-egg problem
# (needing API access to schedule the thing that provides API access).
#
# Binds on 0.0.0.0:16443, but this is Tailscale-only in practice: every
# host importing this module already has `tailscale0` in
# networking.firewall.trustedInterfaces (same mechanism that already keeps
# k3s's own :6443 private today) while everything else stays blocked by
# the default-deny firewall, since 16443 is deliberately NOT added to
# allowedTCPPorts. No per-host IP parameterization needed as a result -
# this file is byte-for-byte identical on all three importers.
#
# TCP mode, not HTTP mode: k3s's own mTLS handles encryption/auth
# end-to-end, HAProxy just needs to pick a healthy backend and get out of
# the way - a dumb TCP passthrough with a connect-based health check is
# the correct level of involvement here, not TLS termination.
{ ... }:

{
  services.haproxy = {
    enable = true;
    config = ''
      global
        maxconn 4096

      defaults
        mode tcp
        timeout connect 5s
        timeout client 300s
        timeout server 300s

      frontend k3s-apiserver
        bind *:16443
        default_backend k3s-servers

      backend k3s-servers
        balance leastconn
        option tcp-check
        server orion 100.127.233.30:6443 check inter 5s fall 2 rise 2
        server vega  100.108.168.27:6443 check inter 5s fall 2 rise 2
        server rigel 100.79.126.86:6443  check inter 5s fall 2 rise 2
    '';
  };
}
