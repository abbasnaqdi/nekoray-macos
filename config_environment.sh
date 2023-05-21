#!/bin/bash

# first config environment variables
export MACOSX_DEPLOYMENT_TARGET="10.13"

init_script_variable() {
    nRoot="$(pwd)"
    nPath="$(pwd)/temp/nekoray"
    nApp=$nPath/build/nekoray.app
}

init_nekoray_local() {
    neko_common="github.com/matsuridayo/libneko/neko_common"
    cd $nRoot/v2ray-core
    version_v2ray=$(git log --pretty=format:'%h' -n 1)
    cd $nPath
    version_standalone="nekoray-"$(cat $nPath/nekoray_version.txt)
}
