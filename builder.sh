#!/bin/bash

set -e

# Initialize and configure
export MACOSX_DEPLOYMENT_TARGET="10.15"

# Remove unnecessary directories if running in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
  for dir in "nekoray" "v2ray-core" "sing-box-extra" "sing-box" "libneko" "Xray-core" "sing-quic" ; do
    [ -d "$dir" ] && rm -rf "$dir"
  done
else
  if ! rmdir nekoray v2ray-core sing-box-extra sing-box libneko Xray-core sing-quic 2> /dev/null; then
    echo "clean and ready..."
  fi
fi

# Clone or update repositories with a function
clone_or_update_repo() {
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

# Array to store repository URLs
repos=("nekoray=https://github.com/MatsuriDayo/nekoray.git"
       "v2ray-core=https://github.com/MatsuriDayo/v2ray-core.git")

# Clone or update repositories using the function
for repo_info in "${repos[@]}"; do
  repo=${repo_info%%=*}
  url=${repo_info#*=}
  clone_or_update_repo "$repo" "$url"
done


# Check and install dependencies if not already installed

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

# Array to store dependencies
dependencies=("golang" "cmake" "ninja" "curl")

# Check and install dependencies using the function
for dep in "${dependencies[@]}"; do
  check_and_install "$dep" "$dep"
done

# Set environment variables for Qt5
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"
export QT_QPA_PLATFORM_PLUGIN_PATH="/usr/local/opt/qt@5/plugins"
# export PKG_CONFIG_PATH="/usr/local/opt/qt@5/lib/pkgconfig"

# Install macdeployqt for macOS
check_and_install "macdeployqt" "qt@5"

nRoot=$(pwd)
nPath=$(pwd)/nekoray

# Clean build directory or create it if it does not exist
if [ -d "$nPath/build" ]; then
  read -p "Do you want to clean 'build' and 'libs/deps' directories? [y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
  rm -rf "$nPath/libs/deps" "$nPath/build"
fi

mkdir -p "$nPath/build"

# Get and build dependencies
cd $nPath
bash libs/get_source.sh
bash libs/build_deps_all.sh

# Build nekoray using CMake and Ninja
cd "$nPath/build"
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DNKR_PACKAGE_MACOS=1 ..
ninja

cd "$nPath"

nApp="$nPath/build/nekoray.app"

# Deploy frameworks using macdeployqt
macdeployqt "$nApp" -verbose=3

# Download data files for both amd64 and arm64
curl -fLso "$nApp/Contents/MacOS/geoip.dat" "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
curl -fLso "$nApp/Contents/MacOS/geosite.dat" "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
curl -fLso "$nApp/Contents/MacOS/geoip.db" "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
curl -fLso "$nApp/Contents/MacOS/geosite.db" "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db"

# Copy fa_IR.qm and zh_CN.qm to nekoray.app/Contents/MacOS
for file in "fa_IR.qm" "zh_CN.qm" "ru_RU.qm"; do
  cp "$nPath/build/$file" "$nApp/Contents/MacOS"
done

# Remove updater shortcut if exists
cd "$nApp/Contents/MacOS/"
[ -f "updater" ] && rm updater
cd "$nPath"

# Build nekoray for both amd64 and arm64
for arch in "amd64" "arm64"; do
  rm -rf "$nPath/build/nekoray_$arch.app"
  cp -r "$nApp" "$nPath/build/nekoray_$arch.app"
done

rm -rf "$nApp"

neko_common="github.com/matsuridayo/libneko/neko_common"
cd "$nRoot/v2ray-core"
version_v2ray=$(git log --pretty=format:'%h' -n 1)
cd "$nPath"
version_standalone="nekoray-"$(cat "$nPath/nekoray_version.txt")


# Build nekobox_core and nekoray_core for both amd64 and arm64
for arch in "amd64" "arm64"; do
  GOOS="darwin" GOARCH=$arch bash libs/build_go.sh
  cp -a "$nPath/deployment/macos-$arch/." "$nPath/build/nekoray_$arch.app/Contents/MacOS/"
done

# Zip nekoray by arch
for arch in "amd64" "arm64"; do
  TEMP_PATH=$(pwd)
  cd "$nPath/build"
  zip -r "nekoray_$arch.zip" "nekoray_$arch.app"
  cd "$TEMP_PATH"
done

echo "Build finished and output files are in $nPath/build"
cd "$nPath"
open "$nPath/build"
