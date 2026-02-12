{
  description = "Tmuxinator NixOS flake module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: {
    nixosModules.tmuxinator = import ./modules/tmuxinator.nix;
    homeManagerModules.tmuxinator = import ./modules/tmuxinator.nix;
  };
}
