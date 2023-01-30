{
  outputs = { self, nixpkgs }: {
    nixosConfigurations.Luna = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/luna/configuration.nix ];
    };
  };
}