{
  outputs = { self, nixpkgs }: {
    # replace 'joes-desktop' with your hostname here.
    nixosConfigurations.Luna = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./host/luna/configuration.nix ];
    };
  };
}