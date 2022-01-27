#!/bin/bash

if [[$1 == "tvos"]] then;
    GODOT_PLUGINS="inappstore icloud"
elif [[$1 == "iphone"]] then;
    GODOT_PLUGINS="gamecenter inappstore icloud camera arkit apn photo_picker"
fi

rm -rf ./bin/$1
mkdir ./bin/$1

# Compile Plugin 
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_static_library.sh $lib release $2
    ./scripts/generate_static_library.sh $lib release_debug $2
    mv ./bin/$1/${lib}.release_debug.a ./bin/$1/${lib}.debug.a
done

# Move to release folder


mkdir ./bin/$1/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/$1/release/${lib}
    mv ./bin/$1/${lib}.{release,debug}.a ./bin/$1/release/${lib}
done