#!/run/current-system/sw/bin/bash

if git --no-pager diff --staged --name-only | grep -q flake.nix; then
  printf "Flake.nix contains local path for an input, please fix before committing to repo"
  exit 1
else
  exit 0
fi
