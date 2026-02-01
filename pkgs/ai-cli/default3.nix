let
  dream2nix = (builtins.getFlake "github:davhau/dream2nix").lib.dream2nix.x86_64-linux;
in

dream2nix.justBuild {
  source = builtins.fetchtarball "https://github.com/prettier/prettier/tarball/main";
}
