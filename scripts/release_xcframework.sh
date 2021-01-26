#!/bin/bash

# Compile GameCenter

./scripts/generate_xcframework.sh gamecenter release $1
./scripts/generate_xcframework.sh gamecenter release_debug $1
mv ./bin/gamecenter.release_debug.xcframework ./bin/gamecenter.debug.xcframework

# Compile InAppStore

./scripts/generate_xcframework.sh inappstore release $1
./scripts/generate_xcframework.sh inappstore release_debug $1
mv ./bin/inappstore.release_debug.xcframework ./bin/inappstore.debug.xcframework

# Compile iCloud

./scripts/generate_xcframework.sh icloud release $1
./scripts/generate_xcframework.sh icloud release_debug $1
mv ./bin/icloud.release_debug.xcframework ./bin/icloud.debug.xcframework

# Compile Camera

./scripts/generate_xcframework.sh camera release $1
./scripts/generate_xcframework.sh camera release_debug $1
mv ./bin/camera.release_debug.xcframework ./bin/camera.debug.xcframework

# Compile ARKit

./scripts/generate_xcframework.sh arkit release $1
./scripts/generate_xcframework.sh arkit release_debug $1
mv ./bin/arkit.release_debug.xcframework ./bin/arkit.debug.xcframework

# Move to release folder

rm -rf ./bin/release
mkdir ./bin/release

# Move GameCenter
mkdir ./bin/release/gamecenter
mv ./bin/gamecenter.{release,debug}.xcframework ./bin/release/gamecenter

# Move InAppStore
mkdir ./bin/release/icloud
mv ./bin/icloud.{release,debug}.xcframework ./bin/release/icloud

# Move InAppStore
mkdir ./bin/release/inappstore
mv ./bin/inappstore.{release,debug}.xcframework ./bin/release/inappstore

# Move Camera
mkdir ./bin/release/camera
mv ./bin/camera.{release,debug}.xcframework ./bin/release/camera

# Move ARKit
mkdir ./bin/release/arkit
mv ./bin/arkit.{release,debug}.xcframework ./bin/release/arkit