{
  description = "MacOS Nix Configuration";

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
    ...
  }: let
    username = "user";
    system = "aarch64-darwin";

    # Unstable packages (for cherry-picking)
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    darwinConfigurations.air = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # Determinate module
        determinate.darwinModules.default

        # Darwin Config
        ./darwin

        # home-manager module
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = import ./home;
            extraSpecialArgs = {inherit pkgs-unstable;};
          };
        }

        # Pass username to modules
        {_module.args = {inherit username;};}
      ];
    };

    nixosConfigurations.donk = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs username;};
      modules = [
        determinate.nixosModules.default
        ./hosts/donk

        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${username} = import ./hosts/donk/home.nix;
            extraSpecialArgs = {inherit username;};
          };
        }
      ];
    };

    # Nix formatter
    # Format all Nix files: nix fmt
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
