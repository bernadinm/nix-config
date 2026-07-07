self: super:

{
  frappe-books = super.callPackage ../local-packages/frappe-books/frappe-books.nix { };

  # Fix Waydroid to use nftables instead of iptables-legacy (kernel 6.x doesn't have ip_tables module)
  waydroid = super.waydroid.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      # Force use of iptables-nft instead of iptables-legacy
      substituteInPlace data/scripts/waydroid-net.sh \
        --replace 'IPTABLES_BIN="$(command -v iptables-legacy)"' 'IPTABLES_BIN=""' \
        --replace 'IP6TABLES_BIN="$(command -v ip6tables-legacy)"' 'IP6TABLES_BIN=""'
    '';
  });
}

