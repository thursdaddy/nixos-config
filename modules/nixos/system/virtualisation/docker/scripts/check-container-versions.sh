#!/usr/bin/env bash
# shellcheck disable=SC2059

# really really rough script to check currently deployed verions of containers and
# compare against the latest version in the containers gh repo
# should be refactored if script ultimately becomes useful/utilized

# ansi color codes
BLUE='\033[1;34m'
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
WHITE='\033[1;37m'
GREY='\033[4;39m'
NC='\033[0m' #no color

# get a list of running container names
CONTAINERS=$(docker ps --format '{{.Names}}')

if [[ "$#" -gt 0 && $1 == "--ignore" ]]; then
  declare -a ignore_list
  for ignore in "$@"; do
    ignore_list+=("$ignore")
  done
fi

declare -a no_container_source

# loop through each container name
printf "\n${WHITE}CONTAINER VERSIONS:${NC}"
for container in $CONTAINERS; do
  # leave the loop if container name is in the ignore list
  if [[ "${ignore_list[*]}" =~ ${container} ]]; then
    continue
  fi

  INSPECT_JSON=$(docker inspect "${container}" --format '{{json .}}')
  SOURCE=$(echo "${INSPECT_JSON}" | jq '.Config.Labels."org.opencontainers.image.source"' | sed -e 's/"//g')

  # leave the loop if container doesnt have standarized labels
  if [[ "${SOURCE}" == "" || "${SOURCE}" == "null" ]]; then
    no_container_source+=("${container} ")
    continue
  fi

  # sed result to a valid api url
  # ex: https://api.github.com/repos/$OWNER/$NAME
  GH_API_URL=$(echo "${SOURCE}" | sed -e 's/:\/\//:\/\/api./g' -e 's/.com/.com\/repos/')

  # some repos dont do releases, just tags
  RELEASE_OR_TAG="releases"
  if [[ ${container} =~ "gitlab" ]]; then
    RELEASE_OR_TAG="tags"
  fi

  # if github api token is present, authorize github api calls
  if [ -f "/run/secrets/github/TOKEN" ]; then
    # sed result to a valid api url
    # ex: https://api.github.com/repos/$OWNER/$NAME/releases/latest
    GH_TOKEN=$(cat /run/secrets/github/TOKEN)
    if [[ $RELEASE_OR_TAG =~ "tags" ]]; then
      VERSION_LATEST=$(curl -s "${GH_API_URL}/${RELEASE_OR_TAG}" --header "Authorization: Bearer ${GH_TOKEN}" --header "X-GitHub-Api-Version: 2022-11-28" | grep '"name":' | head -1 | sed 's/.* "\(.*\)",/\1/' | sed 's/v//g')
    else
    VERSION_LATEST=$(curl -s "${GH_API_URL}/${RELEASE_OR_TAG}/latest" --header "Authorization: Bearer ${GH_TOKEN}" --header "X-GitHub-Api-Version: 2022-11-28" | jq '.tag_name' | sed -e 's/"//g' -e 's/v//g')
    fi
  else
    if [[ $RELEASE_OR_TAG =~ "tags" ]]; then
      VERSION_LATEST=$(curl -s "${GH_API_URL}/${RELEASE_OR_TAG}" | grep '"name":' | head -1 | sed 's/.* "\(.*\)",/\1/' | sed 's/v//g')
    else
    VERSION_LATEST=$(curl -s "${GH_API_URL}/${RELEASE_OR_TAG}/latest" | jq '.tag_name' | sed -e 's/"//g' -e 's/v//g')
    fi
  fi

  # get current container version
  VERSION_CURRENT=$(echo "${INSPECT_JSON}" | jq '.Config.Labels."org.opencontainers.image.version"' | sed -e 's/"//g' -e 's/v//g')
  # print container versions
  # - if latest version is newer, print version number in orange and link release notes
  # - if latest version is null, print null but do not link release notes
  printf "\n\n${BLUE}${container}:${NC}\n${GREEN}(${VERSION_CURRENT})${NC} "
  if [[ "${VERSION_CURRENT}" != "${VERSION_LATEST}" ]]; then
    printf "${WHITE}latest: ${ORANGE}v${VERSION_LATEST}${NC}"
    if [[ "${VERSION_CURRENT}" != "null" ]]; then
      if [[ $RELEASE_OR_TAG =~ "tags" ]]; then
        printf " - ${GREY}${SOURCE}/releases/tag/v${VERSION_LATEST}${NC} "
      else
        printf " - ${GREY}${SOURCE}/${RELEASE_OR_TAG}/v${VERSION_LATEST}${NC} "
      fi
    fi
  fi
done

# print a list of the containers that are missing version labels
if [[ -n "${no_container_source[*]}" ]]; then
  printf "\n\n${WHITE}MISSING VERSION LABELS:\n"
  for container in "${no_container_source[@]}"; do
    printf "${BLUE}${container}\n"
  done
fi
