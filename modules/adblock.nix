{ pkgs, ... }:
let
  inherit (builtins) concatStringsSep;
  inherit (pkgs) fetchFromGitHub stdenv gnugrep;
  inherit (builtins) readFile fetchurl;

  hosts = stdenv.mkDerivation {
    name = "hosts";

    # created from nix-prefetch-git https://github.com/StevenBlack/hosts 3.9.30
    src = fetchFromGitHub {
      owner = "StevenBlack";
      repo = "hosts";
      rev = "b6fd01f620ad79dbee93f4fff42f1923e7c25a54";
      sha256 = "12vira9dhvj69b7jklxn05kjcsj5bwxlzxxk5v36j4vc014yd97s";
    };

    nativeBuildInputs = [ gnugrep ];

    installPhase = ''
      mkdir -p $out/etc
      # filter allowlist
      grep -Ev '(${whitelist})' alternates/fakenews-gambling/hosts > $out/etc/hosts
      # filter denylist
      cat << EOF >> $out/etc/hosts
      ${blacklist}
      EOF
    '';
  };

  whitelist = concatStringsSep "|" [ ".*pirate(bay|proxy).*" "fe80::1%lo0" "*ten-x.com" ];

  blacklist = concatStringsSep ''
    0.0.0.0 ''
    [
      "# auto-generated: must be first"

      # starts here
    ];

in
{ networking.extraHosts = readFile "${hosts}/etc/hosts"; }
