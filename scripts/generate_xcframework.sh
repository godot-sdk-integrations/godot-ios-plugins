#!/bin/bash
set -e

# Compile static libraries_

# ARM64 Device
scons platform=$4 target=$2 arch=arm64 plugin=$1 version=$3
if [[$4 == "iphone"]] then;
    # ARMv7 Device
    scons platform=$4 target=$2 arch=arm7 plugin=$1 version=$3
fi

# x86_64 Simulator
scons platform=$4 target=$2 arch=x86_64 simulator=yes plugin=$1 version=$3
# ARM64 Simulator
scons platform=$4 target=$2 arch=arm64 simulator=yes plugin=$1 version=$3

# Creating a fat libraries for device and simulator
# lib<plugin>.<arch>-<platform>.<simulator>.<release|debug|release_debug>.a
lipo -create "./bin/lib$1.x86_64-$4.simulator.$2.a" "./bin/lib$1.arm64-$4.simulator.$2.a" -output "./bin/$4/$1-simulator.$2.a"
if [[$4 == "iphone"]] then;
    lipo -create "./bin/lib$1.arm64-$4.$2.a" "./bin/lib$1.armv7-$4.$2.a" -output "./bin/$4/$1-device.$2.a"
else 
    lipo -create "./bin/lib$1.arm64-$4.$2.a" -output "./bin/$4/$1-device.$2.a"
fi
# Creating a xcframework 
xcodebuild -create-xcframework \
    -library "./bin/$4/$1-device.$2.a" \
    -library "./bin/$4/$1-simulator.$2.a" \
    -output "./bin/$4/$1.$2.xcframework" 
