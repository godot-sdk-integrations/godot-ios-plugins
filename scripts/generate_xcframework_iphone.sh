#!/bin/bash
set -e

# Compile static libraries

# ARM64 Device
scons platform=iphone target=$2 arch=arm64 plugin=$1 version=$3
# ARM7 Device
scons platform=iphone target=$2 arch=armv7 plugin=$1 version=$3
# x86_64 Simulator
scons platform=iphone target=$2 arch=x86_64 simulator=yes plugin=$1 version=$3
# ARM64 Simulator
scons platform=iphone target=$2 arch=arm64 simulator=yes plugin=$1 version=$3

# Creating a fat libraries for device and simulator
# lib<plugin>.<arch>-<simulator|iphone>.<release|debug|release_debug>.a
lipo -create "./bin/iphone/lib$1.x86_64-simulator.$2.a" "./bin/iphone/lib$1.arm64-simulator.$2.a" -output "./bin/iphone/$1-simulator.$2.a"
lipo -create "./bin/iphone/lib$1.armv7-iphone.$2.a" "./bin/iphone/lib$1.arm64-iphone.$2.a" -output "./bin/iphone/$1-device.$2.a"

# Creating a xcframework 
xcodebuild -create-xcframework \
    -library "./bin/iphone/$1-device.$2.a" \
    -library "./bin/iphone/$1-simulator.$2.a" \
    -output "./bin/iphone/$1.$2.xcframework"