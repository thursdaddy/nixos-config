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
    printf "${BLUE}Rebuilding... ${GREEN}${TARGET} (local)${NC}\n"
    attic use local
    sudo nixos-rebuild --flake .\#"$TARGET" --fast switch
  elif [[ "$TARGET" == "mbp" ]]; then
    printf "${BLUE}Rebuilding... ${GREEN}${TARGET} (local)${NC}\n"
    darwin-rebuild --flake .\#mbp switch
  else
    printf "${BLUE}Rebuilding... ${ORANGE}${TARGET} (remote)${NC}\n"
    attic use local
    nixos-rebuild --flake .\#"${TARGET}" --target-host "${TARGET}" --fast --use-substitutes --use-remote-sudo switch
  fi
}

build () {
  printf "\n${ORANGE}Building: ${WHITE}${TARGET}${NC}\n"
  nix build .\#"${TARGET}" &&\
    copy_artifact_path
}

# copy result to builds/
function copy_artifact_path {
  if [ -L ./result ]; then
    ARTIFACT_PATH=$(readlink ./result)
    # vhd = ami, zst = sd-aarch64
    ARTIFACT=$(find "$ARTIFACT_PATH" -type f \( -iname '*.vhd' -o -iname '*.zst' -o -iname '*.iso' \))
    if [ ! -z "${ARTIFACT}" ]; then
      printf "\nCopy ${ARTIFACT} to builds/\n\n"
      sudo cp "$ARTIFACT" builds/
      cleanup
    fi
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
  printf "${BLUE}Setting input to local: ${WHITE}${INPUT}${NC}\n"
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

update_flake_input () {
  if [[ $INPUT == "nixos-thurs" ]]; then
    sed -i 's/      url = ".*'"${INPUT}"'.*/      url = "github:thursdaddy\/'"${INPUT}"'\/main";/g' flake.nix
  fi

  if [ "${INPUT}" == "all" ]; then
    printf "${GREEN}Updating flake.nix...${NC}\n"
    nix flake update
  else
    printf "${GREEN}Updating flake.nix input: ${WHITE}${INPUT}${NC}\n"
    nix flake update "${INPUT}"
  fi
  nix flake archive
}

print_help () {
  printf "${NC}NAME:\n\n  nix.sh\n \
\n${NC}DESCRIPTION:\n\n  Nix wrapper script to help with nixos-rebuilds, flip-flopping nixos-thurs input between local and remote urls,\n and building packages/nixos-generators targets from flake.nix${NC}\n\n\
${NC}SYNOPSIS:\n\n  ./nix.sh ${WHITE}[build|rebuild|local|update] ${GREEN}target${NC}\n\n\
${NC}OPTIONS:\n\n\
  ${WHITE}build${NC}\t\tnix build --flake #.${GREEN}<target>\n\n\
  ${WHITE}rebuild${NC}\tnixos-rebuild flake #.${GREEN}<target>\n\n\
  ${WHITE}local${NC}\t\tupdate flake.nix input url for nixos-thurs to local path (my private nixos configuration repo)\n\n\
  ${WHITE}update${NC}\tnix flake update ${GREEN}<target>${NC}\n\
\t\tif target is nixos-thurs and current url is local path it will update to github:thursdaddy\n\
\t\tif target is \`all\` it will udpate all flake.nix inputs\n
  ${GREEN}target\t${NC}nixosConfigurations, darwinConfigurations or packages (derivations/nixos-generators) found in flake.nix\n"
}

# gnu-sed fix on MBP
if [[ ${HOSTNAME:-$HOST} =~ "mbp" ]]; then
  PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# flakes are married to git
git add .

TARGET=${2:-null}
INPUT=${2:-null}

case $1 in
  help)
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
    rebuild "$TARGET"
    ;;
esac
