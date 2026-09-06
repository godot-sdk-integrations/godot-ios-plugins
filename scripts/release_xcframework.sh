#!/bin/bash
set -e

PLATFORM=${2:-ios}

if [[ "$1" == "3.x" ]];
then
    GODOT_PLUGINS="gamecenter inappstore icloud camera arkit apn photo_picker"
else
    GODOT_PLUGINS="gamecenter inappstore icloud camera apn photo_picker"
fi

if [[ "$PLATFORM" == "tvos" ]]; then
    # Only GameCenter is currently tvOS-ready; media, APN, and store plugins
    # need separate tvOS availability audits before they can be released.
    GODOT_PLUGINS="gamecenter"
fi

# Compile Plugin
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_xcframework.sh $lib release $1 $PLATFORM
    ./scripts/generate_xcframework.sh $lib release_debug $1 $PLATFORM
    SUFFIX=""
    if [[ "$PLATFORM" != "ios" ]]; then
        SUFFIX=".$PLATFORM"
    fi
    mv ./bin/${lib}.release_debug${SUFFIX}.xcframework ./bin/${lib}.debug${SUFFIX}.xcframework
done

# Move to release folder

rm -rf ./bin/release
mkdir ./bin/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/release/${lib}
    SUFFIX=""
    if [[ "$PLATFORM" != "ios" ]]; then
        SUFFIX=".$PLATFORM"
    fi
    mv ./bin/${lib}.release${SUFFIX}.xcframework ./bin/release/${lib}/${lib}.release.xcframework
    mv ./bin/${lib}.debug${SUFFIX}.xcframework ./bin/release/${lib}/${lib}.debug.xcframework
    cp ./plugins/${lib}/${lib}.gdip ./bin/release/${lib}
done
