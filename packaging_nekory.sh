#!/bin/bash

# set environment variables from sh file
source config_environment.sh

cd "$nPath/build"
cmake -GNinja -DCMAKE_BUILD_TYPE=Release -DNKR_PACKAGE_MACOS=1 ..
ninja

cd $nPath

# Deploy frameworks using macdeployqt
macdeployqt "$nApp" -verbose=3

# Download data files for both amd64 and arm64
curl -fLso $nApp/Contents/MacOS/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
curl -fLso $nApp/Contents/MacOS/geosite.dat "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
curl -fLso $nApp/Contents/MacOS/geoip.db "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db"
curl -fLso $nApp/Contents/MacOS/geosite.db "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db"

# copy fa_IR.qm and zh_CN.qm to nekoray.app/Contents/MacOS
for file in "fa_IR.qm" "zh_CN.qm"; do
  cp "$nPath/build/$file" "$nApp/Contents/MacOS"
done

# remove updater shortcut with check if exist
cd $nApp/Contents/MacOS/
if [ -f "updater" ]; then
  rm updater
fi
cd $nPath

# Build nekoray for both amd64 and arm64
for arch in "amd64" "arm64"; do
  rm -rf "$nPath/build/nekoray_$arch.app"
  cp -r $nApp "$nPath/build/nekoray_$arch.app"
done

rm -rf $nApp