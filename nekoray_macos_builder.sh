#!/bin/bash

set -e

# Clone or update repositories

clone_or_update_with_tag() {
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

clone_or_update_with_tag "nekoray" "https://github.com/MatsuriDayo/nekoray.git"
clone_or_update_with_tag "v2ray-core" "https://github.com/MatsuriDayo/v2ray-core.git"

# Install dependencies if they are not already installed

command -v "brew" >/dev/null 2>&1 || {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

check_and_install() {
  local cmd="$1"
  local package="$2"
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "$cmd could not be found, installing $package"
    brew install "$package"
  }
}

check_and_install "cmake" "cmake"
check_and_install "ninja" "ninja"
check_and_install "go" "go"
check_and_install "curl" "curl"
check_and_install "macdeployqt" "qt@5"

# Set environment variables
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"
export PKG_CONFIG_PATH="/usr/local/opt/qt@5/lib/pkgconfig"
export MACOSX_DEPLOYMENT_TARGET="10.9"

nRoot="$(pwd)"
nPath="$(pwd)/nekoray"

# Create or clean build directory
if [ ! -d "$nPath/build" ]; then
  mkdir -p "$nPath/build"
else

  read -p "Do you want to clean 'build' and 'libs/deps' directories ? [y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi

  rm -rf "$nPath/libs/deps"
  rm -rf "$nPath/build"
  mkdir -p "$nPath/build"
fi

# Get and Build dependencies
bash build_deps_all.sh

cd "$nPath/build"
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DNKR_PACKAGE_MACOS=1 ..
ninja

cd $nPath

nApp=$nPath/build/nekoray.app

# Deploy frameworks using macdeployqt
for arch in "amd64" "arm64"; do
  macdeployqt "$nApp" -verbose=1
done

# Download data files for both amd64 and arm64
curl -fLso $nApp/Contents/MacOS/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
curl -fLso $nApp/Contents/MacOS/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
curl -fLso $nApp/Contents/MacOS/geoip.db "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
curl -fLso $nApp/Contents/MacOS/geosite.db "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db"

# copy fa_IR.qm and zh_CN.qm to nekoray.app/Contents/MacOS
for file in "fa_IR.qm" "zh_CN.qm"; do
  cp "$nPath/build/$file" "$nApp/Contents/MacOS"
done

# Build nekoray for both amd64 and arm64
for arch in "amd64" "arm64"; do
  rm -rf "$nPath/build/nekoray_$arch.app"
  cp -r $nApp "$nPath/build/nekoray_$arch.app"
done

rm -rf $nApp

neko_common="github.com/matsuridayo/libneko/neko_common"
cd $nRoot/v2ray-core
version_v2ray=$(git log --pretty=format:'%h' -n 1)
cd $nPath
version_standalone="nekoray-"$(cat $nPath/nekoray_version.txt)


# Build nekobox_core and nekoray_core for both amd64 and arm64
for cmd in "nekobox_core" "nekoray_core"; do
  for arch in "amd64" "arm64"; do
    cd "$nPath/go/cmd/$cmd"
    GOARCH="$arch"

    if [ "$cmd" = "nekoray_core" ]; then
      go build -o "${cmd}_${arch}" -trimpath -ldflags "-w -s -X $neko_common.Version_v2ray=$version_v2ray -X $neko_common.Version_neko=$version_standalone"
    else
      go build -o "${cmd}_${arch}" -trimpath -ldflags "-w -s -X $neko_common.Version_neko=$version_standalone" -tags "with_grpc,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api"
    fi

    cp "${cmd}_${arch}" "$nPath/build/nekoray_$arch.app/Contents/MacOS/$cmd"
  done
done

#zip nekoray by arch
if [ -z "$GITHUB_ACTIONS" ]; then
  for arch in "amd64" "arm64"; do
    TEMP_PATH=$(pwd)
    cd "$nPath/build"
    zip -r "nekoray_$arch.zip" "nekoray_$arch.app"
    cd "$TEMP_PATH"
  done
else
  for arch in "amd64" "arm64"; do
    zip -r "$nPath/build/nekoray_$arch.zip" "$nPath/build/nekoray_$arch.app"
  done
fi

echo "Build finished and output files are in $nPath/build"
cd "$nPath"
open "$nPath/build"
