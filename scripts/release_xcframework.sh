#!/bin/bash
set -e

if [[ "$1" == "3.x" ]];
then
    GODOT_PLUGINS="gamecenter inappstore icloud camera arkit apn photo_picker"
else
    GODOT_PLUGINS="gamecenter inappstore icloud camera apn photo_picker"
fi

# Compile Plugin
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_xcframework.sh $lib release $1
    ./scripts/generate_xcframework.sh $lib release_debug $1
    mv ./bin/${lib}.release_debug.xcframework ./bin/${lib}.debug.xcframework
done

# Move to release folder

rm -rf ./bin/release
mkdir ./bin/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/release/${lib}
    mv ./bin/${lib}.{release,debug}.xcframework ./bin/release/${lib}
    cp ./plugins/${lib}/${lib}.gdip ./bin/release/${lib}
done
