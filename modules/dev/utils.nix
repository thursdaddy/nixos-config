_: {
  flake.modules.generic.dev =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        glow
        jq
        just
        nixfmt-rfc-style
        nixpkgs-fmt
        shellcheck
        statix
      ];
    };
}
