#!/bin/bash

# set environment variables from sh file
source config_environment.sh

# Build nekobox_core and nekoray_core for both amd64 and arm64
for cmd in "nekobox_core" "nekoray_core"; do
  for arch in "amd64" "arm64"; do
    cd "$nTemp/go/cmd/$cmd"
    GOARCH="$arch"

    if [ "$cmd" = "nekoray_core" ]; then
      go build -o "${cmd}_${arch}" -v -trimpath -ldflags "-w -s -X $neko_common.Version_v2ray=$version_v2ray -X $neko_common.Version_neko=$version_standalone"
    else
      go build -o "${cmd}_${arch}" -v -trimpath -ldflags "-w -s -X $neko_common.Version_neko=$version_standalone" -tags "with_grpc,with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api"
    fi

    cp "${cmd}_${arch}" "$nTemp/build/nekoray_$arch.app/Contents/MacOS/$cmd"
  done
done