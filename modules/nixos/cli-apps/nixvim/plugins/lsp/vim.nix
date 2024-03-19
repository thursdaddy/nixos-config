{ ... }: {

  programs.nixvim = {
    plugins.lsp = {
      enable = true;

      servers = {
        nil_ls.enable = true;
        bashls.enable = true;
        terraformls.enable = true;

        lua-ls = {
          enable = true;
          settings.telemetry.enable = false;
        };

      };
    };
  };

}
