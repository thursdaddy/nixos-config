#!/usr/bin/env bash
# shellcheck disable=SC2059
#
set -oeu pipefail
# just a simple wrapper script for nix builds

# ansi color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

#--option eval-cache false
rebuild () {
  if [[ "${HOSTNAME:-$HOST}" == "$TARGET" ]]; then
    printf "\n${BLUE}Rebuilding... ${GREEN}${TARGET} (local)${NC}\n"
    sudo nixos-rebuild --flake .\#"$TARGET" switch
  elif [[ "$TARGET" == "mbp" ]]; then
    printf "\n${BLUE}Rebuidling... ${GREEN}${TARGET} (local)${NC}\n"
    darwin-rebuild --flake .\#mbp switch
  else
    printf "\n${BLUE}Rebuidling... ${ORANGE}${TARGET} (remote)${NC}\n"
    nixos-rebuild --flake .\#"${TARGET}" --target-host "${TARGET}" --use-remote-sudo switch
  fi
}

build () {
  printf "\n${ORANGE}Building: ${WHITE}${TARGET}${NC}\n"
  nix build .\#"${TARGET}" && copy_artifact_path && cleanup
}

# copy result to builds/
function copy_artifact_path {
  printf "${GREEN}Copying file..${NC}\n"
  if [ -L ./result ]; then
    ARTIFACT_PATH=$(readlink ./result)
    # vhd = ami, zst = sd-aarch64
    ARTIFACT=$(find "$ARTIFACT_PATH" -type f \( -iname '*.vhd' -o -iname '*.zst' -o -iname '*.iso' \))
    printf "\nCopy ${ARTIFACT} to builds/\n\n"
    sudo cp "$ARTIFACT" builds/
  else
    exit 1
  fi
}

# update perms and remove $result
function cleanup {
  printf "${GREEN}Cleaning up..${NC}\n"
  if [ -L ./result ]; then rm -v ./result; fi
  printf "\n${GREEN}Updating permissions in builds dir:${NC}\n"
  sudo chown -R "$(whoami)":users builds/
  printf "${WHITE}Builds:${NC}\n"
  ls -lah builds/
}

update_to_local_input () {
  # set path based on target
  printf "\n${BLUE}Setting input to local: ${WHITE}${INPUT}${NC}\n\n"
  if [[ ${HOSTNAME:-$HOST} =~ "mbp" ]]; then
    local NIXOS_THURS_PATH="\/Users\/thurs"
  else
    local NIXOS_THURS_PATH="\/home\/thurs"
  fi
  # if github url is set, replace it
  sed -i 's/      url = ".*'"${INPUT}"'.*/      url = "git+file:\/\/'"${NIXOS_THURS_PATH}"'\/projects\/nix\/'"${INPUT}"'\/";/g' flake.nix

  # finally update
  nix flake update "${INPUT}"
}

check_gh_token () {
  # set GH_TOKEN to pull private flake from private repo
  if [ -f "/run/secrets/github/TOKEN" ] || [ -f "$HOME/.config/sops-nix/secrets/github/TOKEN" ]; then
    if [[ ${HOSTNAME:-$HOST} =~ "mbp" ]]; then
      printf "${ORANGE}GitHub token found!${NC}"
      GH_TOKEN=$(cat ~/.config/sops-nix/secrets/github/TOKEN)
    else
      printf "${ORANGE}GitHub token found!${NC}"
      GH_TOKEN=$(cat /run/secrets/github/TOKEN)
    fi
    export NIX_CONFIG="extra-access-tokens = github.com=${GH_TOKEN}"
  else
    printf "${ORANGE}No GH token set.${NC}"
    GH_TOKEN=''
  fi
}

update_flake_input () {
  check_gh_token
  if [[ $INPUT == "nixos-thurs" ]]; then
    sed -i 's/      url = ".*'"${INPUT}"'.*/      url = "github:thursdaddy\/'"${INPUT}"'\/main";/g' flake.nix
  fi

  if [ "${INPUT}" == "all" ]; then
    printf "\n${GREEN}Updating flake.nix...${NC}\n\n"
    nix flake update
  else
    printf "\n${GREEN}Updating flake.nix input: ${WHITE}${INPUT}${NC}\n\n"
    nix flake update "${INPUT}"
  fi
}

print_help () {
  printf "${ORANGE}What did you forget..?${NC}\n"
  printf "Usage: ${NC}./build ${WHITE}[target] ${GREEN}[options]${NC}\n"
  printf "\nArguments:\n\t${WHITE}TARGET\t${NC}Target for build/rebuild, must be defined in rebuild and build function.\n"
  printf "\nOptions:\n"
  printf "\t${GREEN}-u --update-input [name|local] {name-opt}\n\t\t${NC}Update flake input by name, local as first arg will update input to local path, defaults to 'nixos-thurs'.\n"
  printf "\t\tIf input is already local, it will be updated to public github url.\n"
}

# gnu-sed fix on MBP
if [[ ${HOSTNAME:-$HOST} =~ "mbp" ]]; then
  PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# flakes are married to git
git add .

TARGET=$2
INPUT=$2

case $1 in
  --help)
    print_help
    ;;
  build)
    build "$TARGET"
    ;;
  local)
    update_to_local_input "${INPUT}"
    ;;
  update)
    update_flake_input "${INPUT}"
    ;;
  rebuild)
    # adhoc argument to check github for latest hypr* tags
    rebuild "$TARGET"
    ;;
esac
