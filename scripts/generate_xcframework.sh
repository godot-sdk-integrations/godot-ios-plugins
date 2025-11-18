#!/bin/bash
set -e

# Compile static libraries

# ARM64 Device
scons target=$2 arch=arm64 plugin=$1 version=$3
# x86_64 Simulator
scons target=$2 arch=x86_64 simulator=yes plugin=$1 version=$3
# ARM64 Simulator
scons target=$2 arch=arm64 simulator=yes plugin=$1 version=$3

# Normalize target name (map Godot 4.x names to 3.x equivalents for file naming)
TARGET_NAME=$2
if [ "$TARGET_NAME" = "template_debug" ]; then
    TARGET_NAME="debug"
elif [ "$TARGET_NAME" = "template_release" ]; then
    TARGET_NAME="release"
fi

# Creating a fat libraries for device and simulator
# lib<plugin>.<arch>-<simulator|ios>.<release|debug|release_debug>.dylib
lipo -create "./bin/lib$1.x86_64-simulator.$TARGET_NAME.dylib" "./bin/lib$1.arm64-simulator.$TARGET_NAME.dylib" -output "./bin/lib$1-simulator.$TARGET_NAME.dylib"

# Creating a xcframework
xcodebuild -create-xcframework \
    -library "./bin/lib$1.arm64-ios.$TARGET_NAME.dylib" \
    -library "./bin/lib$1-simulator.$TARGET_NAME.dylib" \
    -output "./bin/$1.$TARGET_NAME.xcframework"
