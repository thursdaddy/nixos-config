_: {
  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      fuzzelSettings = {
        main = {
          dpi-aware = "yes";
          exit-on-keyboard-focus-loss = true;
          fields = "filename,name,generic";
          font = "Hack:size=11";
          hide-before-typing = true;
          horizontal-pad = 12;
          image-size-ratio = 0.5;
          inner-pad = 5;
          layer = "overlay";
          line-height = 16;
          lines = 5;
          placeholder = " 󰍉 ";
          show-actions = false;
          tabs = 2;
          vertical-pad = 12;
          width = 35;
        };
        colors = {
          background = "2e3440ef";
          border = "5e81acff";
          match = "81a1c1ff";
          placeholder = "4c566aff";
          selection = "4c566aff";
          selection-match = "88c0d0ff";
          selection-text = "eceff4ff";
          text = "d8dee9ff";
        };
        border = {
          width = 2;
          radius = 10;
        };
        dmenu = {
          mode = "text";
          exit-immediately-if-empty = false;
        };
      };

      fuzzelConf = pkgs.writeText "fuzzel.ini" (pkgs.lib.generators.toINI { } fuzzelSettings);
    in
    {
      config = {
        environment = {
          etc."xdg/fuzzel/fuzzel.ini".source = fuzzelConf;
          systemPackages = [
            pkgs.fuzzel
          ];
        };
      };
    };
}
