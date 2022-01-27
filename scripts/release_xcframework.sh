#!/bin/bash
set -e

GODOT_PLUGINS="inappstore icloud"

# Compile Plugin 
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_xcframework_tvos.sh $lib release $1
    ./scripts/generate_xcframework_tvos.sh $lib release_debug $1
    mv ./bin/tvos/${lib}.release_debug.xcframework ./bin/tvos/${lib}.debug.xcframework
done

# Move to release folder

rm -rf ./bin/tvos
mkdir ./bin/tvos
mkdir ./bin/tvos/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/tvos/release/${lib}
    mv ./bin/tvos/${lib}.{release,debug}.xcframework ./bin/tvos/release/${lib}
    cp ./plugins/${lib}/${lib}.gdip ./bin/tvos/release/${lib}/${lib}.gdatvp
done