#!/bin/bash

set -e

# Clone or update repositories

clone_or_update() {
  local repo="$1"
  local url="$2"
  if [ -d "$repo" ]; then
    git -C "$repo" submodule update --init --recursive
    git -C "$repo" pull
  else
    git clone --recursive "$url" "$repo"
  fi
}

clone_or_update "nekoray" "git@github.com:MatsuriDayo/nekoray.git"
clone_or_update "v2ray-core" "git@github.com:MatsuriDayo/v2ray-core.git"

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
check_and_install "macdeployqt" "qt@5"

# Set environment variables
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"
export PKG_CONFIG_PATH="/usr/local/opt/qt@5/lib/pkgconfig"

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
  macdeployqt "$nApp" -verbose=2
done

# Download data files for both amd64 and arm64
for arch in "amd64" "arm64"; do
  for file in "geoip.dat" "geosite.dat" "geoip.db" "geosite.db"; do
    curl -Lso "$nApp/Contents/MacOS/$file" "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/$file"
  done
done

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

# Build nekobox_core and nekoray_core for both amd64 and arm64
for cmd in "nekobox_core" "nekoray_core"; do
  for arch in "amd64" "arm64"; do
    cd "$nPath/go/cmd/$cmd"
    GOARCH="$arch" go build -trimpath -ldflags "-w -s" -o "${cmd}_${arch}"
    cp "${cmd}_${arch}" "$nPath/build/nekoray_$arch.app/Contents/MacOS/$cmd"
  done
done

#zip nekoray by arch
for arch in "amd64" "arm64"; do
  zip -r "$nPath/build/nekoray_$arch.zip" "$nPath/build/nekoray_$arch.app"
done

echo "Build finished and output files are in $nPath/build"
cd "$nPath"
open "$nPath/build"
