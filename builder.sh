#!/bin/bash

set -e

# set environment variables from sh file
echo "Setting environment variables"
source config_environment.sh
init_script_variable

# get dependencies and first configure
echo "Getting dependencies"
bash get_dependencies.sh

# clone or update source codes
echo "Cloning or updating source codes"
bash get_sources.sh

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

# get dependencies (official source)
echo "Getting dependencies (official source)"
bash build_deps_all.sh

# package nekoray
echo "Packaging nekoray"
bash packaging_nekoray.sh

# Build nekobox_core and nekoray_core
echo "Building nekobox_core and nekoray_core"
bash core_builder.sh

#zip nekoray by arch
echo "Zipping nekoray"
if [ -n "$GITHUB_ACTIONS" ]; then
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
