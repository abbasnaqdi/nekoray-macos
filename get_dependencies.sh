#!/bin/bash

# set environment variables from sh file
source config_environment.sh

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

# Set environment variables
export PATH="/usr/local/opt/qt@5/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/qt@5/lib"
export CPPFLAGS="-I/usr/local/opt/qt@5/include"
export PKG_CONFIG_PATH="/usr/local/opt/qt@5/lib/pkgconfig"

check_and_install "macdeployqt" "qt@5"

# golang dependencies
# go get github.com/sagernet/sing-box/experimental/clashapi/trafficontrol@v1.0.0