{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.darwinGit = pkgs.symlinkJoin {
        name = "git";
        paths = [ pkgs.git ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/git \
            --set GIT_CONFIG_SYSTEM "/etc/gitconfig"
        '';
      };

      # packages.darwinGit = (pkgs.git.override).overrideAttrs (oldAttrs: {
      #   postInstall = (oldAttrs.postInstall or "") + ''
      #     mkdir -p $out/etc
      #     cat <<EOF > $out/etc/gitconfig
      #     [include]
      #       path = /etc/gitconfig
      #     EOF
      #   '';
      # });
    };
}
