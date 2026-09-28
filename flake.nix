{
  description = "Nix configuration for air (macOS) and donk (NixOS)";

  inputs = {
    # Stable Nixpkgs via FlakeHub
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    # Unstable Nixpkgs via FlakeHub
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    # Stable nix-darwin via FlakeHub
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager via FlakeHub
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theming (donk)
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nix-darwin,
    determinate,
    home-manager,
    nix-index-database,
    ...
  }: let
    username = "user";

    # pkgs.unstable.<name>
    unstableOverlay = {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit (final.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        })
      ];
    };
  in {
    darwinConfigurations.air = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        unstableOverlay

        # Determinate module
        determinate.darwinModules.default

        # Darwin Config
        ./hosts/air

        # home-manager module
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${username} = import ./hosts/air/home.nix;
            sharedModules = [nix-index-database.homeModules.nix-index];
          };
        }

        # Pass username to modules
        {_module.args = {inherit username;};}
      ];
    };

    nixosConfigurations.donk = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs username;};
      modules = [
        unstableOverlay
        determinate.nixosModules.default
        ./hosts/donk

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${username} = import ./hosts/donk/home.nix;
            sharedModules = [nix-index-database.homeModules.nix-index];
            extraSpecialArgs = {inherit username;};
          };
        }
      ];
    };

    # Nix formatter
    # Format all Nix files: nix fmt
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
