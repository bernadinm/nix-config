{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    dream2nix.url = "github:nix-community/dream2nix";
    src.url = "https://registry.npmjs.org/eslint/-/eslint-8.4.1.tgz";
    src.flake = false;
  };

  outputs = {
    self,
    dream2nix,
    src,
  } @ inp:
    (dream2nix.lib.makeFlakeOutputs {
      systems = ["x86_64-linux"];
      config.projectRoot = ./.;
      source = src;
      projects = ./projects.toml;
    })
    // {
      # checks = self.packages;
    };
  
  #outputs = { self, nixpkgs, ... }@attrs: {
  #  nixosConfigurations.Luna = nixpkgs.lib.nixosSystem {
  #    specialArgs = attrs;
  #    system = "x86_64-linux";
  #    modules = [ ./hosts/luna/configuration.nix ];
  #  };
  #};
}
