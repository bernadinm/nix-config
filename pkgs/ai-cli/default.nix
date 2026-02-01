{ pkgs ? import <nixpkgs> {}, ... }:

let
  pkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
      packageOverrides = pkgs: {
        npmPackages = pkgs.npmPackages;
      };
    };
  };
  
  node = pkgs.nodejs-14_x;
  ai-cli = pkgs.npmPackages.callPackage ({
    inherit (pkgs) fetchgit;
    repository = "https://github.com/abhagsain/ai-cli.git";
    rev = "master";
    sha256 = "137j00kx39p7g566ja0r78gg944k3s6i7p7327zmnpqgpxn4b5yl";
    postInstall = ''
      ${node}/bin/npm link
    '';
  });
in
  pkgs.stdenv.mkDerivation {
    name = "ai-cli";
    buildInputs = [ node ai-cli ];
    meta = with pkgs; {
      description = "A command-line tool for AI and machine learning tasks";
    };
  }
