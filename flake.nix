{
  description = "Tmuxinator NixOS/Home-Manager flake modules";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { ... }: {
    nixosModules.tmuxinator = import ./modules/nixos.nix;
    homeManagerModules.tmuxinator = import ./modules/home-manager.nix;
  };
}
