# This file imports modules shared across all hosts
{ inputs, outputs, ... }: {
  imports = [
    ./openssh.nix
  ];
}
