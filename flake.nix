{
  description = "Miguel's NixOS Configuration";

  inputs = {
    # Stable 25.11 as base
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Unstable for bleeding-edge packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager for user environment management
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Keep dream2nix and eslint for existing functionality
    dream2nix.url = "github:nix-community/dream2nix";
    src.url = "https://registry.npmjs.org/eslint/-/eslint-8.4.1.tgz";
    src.flake = false;
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@attrs:
    let
      # Shared module for all hosts to provide unstable overlay
      unstableOverlay = {
        nixpkgs.overlays = [
          (final: prev: {
            unstable = import nixpkgs-unstable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        # Luna - Framework Laptop
        luna = nixpkgs.lib.nixosSystem {
          specialArgs = attrs;
          system = "x86_64-linux";
          modules = [
            ./hosts/luna/configuration.nix
            unstableOverlay
            home-manager.nixosModules.home-manager
          ];
        };

        # Astra
        astra = nixpkgs.lib.nixosSystem {
          specialArgs = attrs;
          system = "x86_64-linux";
          modules = [
            ./hosts/astra/configuration.nix
            unstableOverlay
            home-manager.nixosModules.home-manager
          ];
        };

        # Lumina
        lumina = nixpkgs.lib.nixosSystem {
          specialArgs = attrs;
          system = "x86_64-linux";
          modules = [
            ./hosts/lumina/configuration.nix
            unstableOverlay
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
