{ pkgs }:
pkgs.symlinkJoin {
  name = "git";
  paths = [ pkgs.git ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/git \
      --set GIT_CONFIG_SYSTEM "/etc/gitconfig"
  '';
}
