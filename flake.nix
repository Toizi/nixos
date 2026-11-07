{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim.url = "github:pfassina/lazyvim-nix";
    private.url = "git+ssh://git@github.com/Toizi/nixos-private";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      llm-agents,
      sops-nix,
      lazyvim,
      private,
      ...
    }:
    {
      nixosConfigurations.mg = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          private.nixosModules.default
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.mg = { config, pkgs, ... }: {
              imports = [ ./home.nix lazyvim.homeManagerModules.default ];
              home.packages = with pkgs; [
                llm-agents.packages.x86_64-linux.opencode
                llm-agents.packages.x86_64-linux.claude-code
                llm-agents.packages.x86_64-linux.omp
              ];
            };
          }
        ];
      };
    };
}
