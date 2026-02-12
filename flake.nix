{
  description = "Tmuxinator NixOS flake module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
  in {
    nixosModules.tmuxinator = import ./modules/tmuxinator.nix {
      inherit pkgs;
      lib = pkgs.lib;
    };
    homeManagerModules.tmuxinator = import ./modules/tmuxinator.nix {
      inherit pkgs;
      lib = pkgs.lib;
    };
  };
}
