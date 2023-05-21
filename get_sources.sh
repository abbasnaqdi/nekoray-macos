#!/bin/bash

# set environment variables from sh file
source config_environment.sh

# if this script running in github action then
# remove unessary directories with check if exist (nekoray, v2ray-core, sing-box-extra, sing-box, libneko)

if [ -n "$GITHUB_ACTIONS" ]; then
  if [ -d "nekoray" ]; then
    rm -rf nekoray
  fi
  if [ -d "v2ray-core" ]; then
    rm -rf v2ray-core
  fi
  if [ -d "sing-box-extra" ]; then
    rm -rf sing-box-extra
  fi
  if [ -d "sing-box" ]; then
    rm -rf sing-box
  fi
  if [ -d "libneko" ]; then
    rm -rf libneko
  fi
fi

# Clone or update repositories

clone_last_valid_source() {
  local repo="$1"
  local url="$2"
  if [ -d "$repo" ]; then
    git -C "$repo" reset --hard
    git -C "$repo" fetch --all --tags --prune
  else
    git clone --recursive "$url" "$repo"
  fi
  if [ -n "$(git -C "$repo" tag --list)" ]; then
    git -C "$repo" checkout "$(git -C "$repo" describe --tags $(git -C "$repo" rev-list --tags --max-count=1))"
  fi
}

clone_last_valid_source "nekoray" "https://github.com/MatsuriDayo/nekoray.git"
clone_last_valid_source "v2ray-core" "https://github.com/MatsuriDayo/v2ray-core.git"
clone_last_valid_source "sing-box-extra" "https://github.com/MatsuriDayo/sing-box-extra.git"
clone_last_valid_source "sing-box" "https://github.com/MatsuriDayo/sing-box.git"
clone_last_valid_source "libneko" "https://github.com/MatsuriDayo/libneko.git"