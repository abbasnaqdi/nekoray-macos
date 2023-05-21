#!/bin/bash

set -e

# set environment variables from sh file
echo "Setting environment variables"
source config_environment.sh

# get dependencies and first configure
echo "Getting dependencies"
bash $nRoot/get_dependencies.sh

# clone or update source codes
echo "Cloning or updating source codes"
bash $nRoot/get_sources.sh

# Create or clean build directory
if [ ! -d "$nTemp/build" ]; then
  mkdir -p "$nTemp/build"
else

  read -p "Do you want to clean 'build' and 'libs/deps' directories ? [y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi

  rm -rf "$nTemp/libs/deps"
  rm -rf "$nTemp/build"
  mkdir -p "$nTemp/build"
fi

# get dependencies (official source)
echo "Getting dependencies (official source)"
bash $nRoot/build_deps_all.sh

# package nekoray
echo "Packaging nekoray"
bash $nRoot/packaging_nekoray.sh

# Build nekobox_core and nekoray_core
echo "Building nekobox_core and nekoray_core"
bash $nRoot/core_builder.sh

#zip nekoray by arch
echo "Zipping nekoray"
if [ -n "$GITHUB_ACTIONS" ]; then
  for arch in "amd64" "arm64"; do
    TEMP_PATH=$(pwd)
    cd "$nTemp/build"
    zip -r "nekoray_$arch.zip" "nekoray_$arch.app"
    cd "$TEMP_PATH"
  done
else
  for arch in "amd64" "arm64"; do
    zip -r "$nTemp/build/nekoray_$arch.zip" "$nTemp/build/nekoray_$arch.app"
  done
fi

echo "Build finished and output files are in $nTemp/build"
cd "$nTemp"
open "$nTemp/build"
