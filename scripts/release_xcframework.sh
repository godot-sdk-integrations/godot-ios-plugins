#!/bin/bash
set -e

#call ./scripts/releasexcframework.sh iphone 3.x
#call ./scripts/releasexcframework.sh tvos 3.x
#call ./scripts/releasexcframework.sh iphone 4.0
#call ./scripts/releasexcframework.sh tvos 4.0

if [[$1 == "tvos"]] then;
    GODOT_PLUGINS="inappstore icloud"
elif [[$1 == "iphone"]] then;
    GODOT_PLUGINS="gamecenter inappstore icloud camera arkit apn photo_picker"
fi

rm -rf ./bin/$1
mkdir ./bin/$1

# Compile Plugin 
for lib in $GODOT_PLUGINS; do
    ./scripts/generate_xcframework.sh $lib release $2 $1
    ./scripts/generate_xcframework.sh $lib release_debug $2 $1
    mv ./bin/$1/${lib}.release_debug.xcframework ./bin/$1/${lib}.debug.xcframework
done

# Move to release folder


mkdir ./bin/$1/release

# Move Plugin
for lib in $GODOT_PLUGINS; do
    mkdir ./bin/$1/release/${lib}
    mv ./bin/$1/${lib}.{release,debug}.xcframework ./bin/$1/release/${lib}
    cp ./plugins/${lib}/${lib}.gdip ./bin/$1/release/${lib}/${lib}.gdatvp
done