#!/bin/bash
set -e

GODOT_PLUGINS="gamecenter inappstore icloud camera arkit apn photo_picker"

# Compile Plugin
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_xcframework_iphone.sh $lib release $1
    ./scripts/generate_xcframework_iphone.sh $lib release_debug $1
    mv ./bin/iphone/${lib}.release_debug.xcframework ./bin/iphone/${lib}.debug.xcframework
done

# Move to release folder

rm -rf ./bin/iphone/release
mkdir ./bin/iphone/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/iphone/release/${lib}
    mv ./bin/iphone/${lib}.{release,debug}.xcframework ./bin/iphone/release/${lib}
    cp ./plugins/${lib}/${lib}.gdip ./bin/iphone/release/${lib}
done
