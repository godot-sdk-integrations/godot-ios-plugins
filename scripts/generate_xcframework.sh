#!/bin/bash
set -e

PLUGIN=$1
TARGET=$2
GODOT_VERSION=$3
PLATFORM=${4:-ios}
SCONS_BIN=${SCONS:-scons}

# Compile static libraries

if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "tvos" && "$PLATFORM" != "all" ]]; then
    echo "Usage: $0 <plugin_name> <debug|release|release_debug> <godot_version> [ios|tvos|all]"
    exit 1
fi

if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    # ARM64 iOS device.
    "$SCONS_BIN" target=$TARGET arch=arm64 platform=ios plugin=$PLUGIN version=$GODOT_VERSION
    # x86_64 iOS simulator.
    "$SCONS_BIN" target=$TARGET arch=x86_64 simulator=yes platform=ios plugin=$PLUGIN version=$GODOT_VERSION
    # ARM64 iOS simulator.
    "$SCONS_BIN" target=$TARGET arch=arm64 simulator=yes platform=ios plugin=$PLUGIN version=$GODOT_VERSION

    # Creating a fat library for iOS simulators.
    # lib<plugin>.<arch>-<simulator|ios>.<release|debug|release_debug>.a
    lipo -create "./bin/lib$PLUGIN.x86_64-simulator.$TARGET.a" "./bin/lib$PLUGIN.arm64-simulator.$TARGET.a" -output "./bin/lib$PLUGIN-simulator.$TARGET.a"
fi

if [[ "$PLATFORM" == "tvos" || "$PLATFORM" == "all" ]]; then
    # ARM64 tvOS device.
    "$SCONS_BIN" target=$TARGET arch=arm64 platform=tvos plugin=$PLUGIN version=$GODOT_VERSION
    # x86_64 tvOS simulator.
    "$SCONS_BIN" target=$TARGET arch=x86_64 simulator=yes platform=tvos plugin=$PLUGIN version=$GODOT_VERSION
    # ARM64 tvOS simulator.
    "$SCONS_BIN" target=$TARGET arch=arm64 simulator=yes platform=tvos plugin=$PLUGIN version=$GODOT_VERSION

    # Creating a fat library for tvOS simulators.
    # lib<plugin>.<arch>-tvos-simulator.<release|debug|release_debug>.a
    lipo -create "./bin/lib$PLUGIN.x86_64-tvos-simulator.$TARGET.a" "./bin/lib$PLUGIN.arm64-tvos-simulator.$TARGET.a" -output "./bin/lib$PLUGIN-tvos-simulator.$TARGET.a"
fi

XCFRAMEWORK_ARGS=()
OUTPUT_SUFFIX=$PLATFORM
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
    XCFRAMEWORK_ARGS+=(-library "./bin/lib$PLUGIN.arm64-ios.$TARGET.a")
    XCFRAMEWORK_ARGS+=(-library "./bin/lib$PLUGIN-simulator.$TARGET.a")
fi
if [[ "$PLATFORM" == "tvos" || "$PLATFORM" == "all" ]]; then
    XCFRAMEWORK_ARGS+=(-library "./bin/lib$PLUGIN.arm64-tvos.$TARGET.a")
    XCFRAMEWORK_ARGS+=(-library "./bin/lib$PLUGIN-tvos-simulator.$TARGET.a")
fi

if [[ "$PLATFORM" == "ios" ]]; then
    OUTPUT_SUFFIX=""
else
    OUTPUT_SUFFIX=".$PLATFORM"
fi

rm -rf "./bin/$PLUGIN.$TARGET$OUTPUT_SUFFIX.xcframework"
xcodebuild -create-xcframework "${XCFRAMEWORK_ARGS[@]}" -output "./bin/$PLUGIN.$TARGET$OUTPUT_SUFFIX.xcframework"
