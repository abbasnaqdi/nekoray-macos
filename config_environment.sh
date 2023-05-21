#!/bin/bash

# first config environment variables
export MACOSX_DEPLOYMENT_TARGET="10.13"

nRoot="$(pwd)"
nTemp="$(pwd)/temp/nekoray"
nApp=$nTemp/build/nekoray.app

# create temp directory if not exist
if [ ! -d "$nTemp" ]; then
    mkdir -p "$nTemp"
fi

cd $nTemp

init_nekoray_local() {
    neko_common="github.com/matsuridayo/libneko/neko_common"
    cd $nRoot/v2ray-core
    version_v2ray=$(git log --pretty=format:'%h' -n 1)
    cd $nTemp
    version_standalone="nekoray-"$(cat $nTemp/nekoray_version.txt)
}
