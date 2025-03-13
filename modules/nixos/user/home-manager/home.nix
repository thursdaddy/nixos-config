{ user, inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  config = {
    programs.home-manager.enable = true;

    home = {
      username = "${user.name}";
      stateVersion = "24.11";
      homeDirectory = "${user.homeDir}";
    };
  };
}
