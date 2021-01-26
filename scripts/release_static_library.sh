#!/bin/bash

# Compile GameCenter

./scripts/generate_static_library.sh gamecenter release $1
./scripts/generate_static_library.sh gamecenter release_debug $1
mv ./bin/gamecenter.release_debug.a ./bin/gamecenter.debug.a

# Compile InAppStore

./scripts/generate_static_library.sh inappstore release $1
./scripts/generate_static_library.sh inappstore release_debug $1
mv ./bin/inappstore.release_debug.a ./bin/inappstore.debug.a

# Compile iCloud

./scripts/generate_static_library.sh icloud release $1
./scripts/generate_static_library.sh icloud release_debug $1
mv ./bin/icloud.release_debug.a ./bin/icloud.debug.a

# Compile Camera

./scripts/generate_static_library.sh camera release $1
./scripts/generate_static_library.sh camera release_debug $1
mv ./bin/camera.release_debug.a ./bin/camera.debug.a

# Compile ARKit

./scripts/generate_static_library.sh arkit release $1
./scripts/generate_static_library.sh arkit release_debug $1
mv ./bin/arkit.release_debug.a ./bin/arkit.debug.a

# Move to release folder

rm -rf ./bin/release
mkdir ./bin/release

# Move GameCenter
mkdir ./bin/release/gamecenter
mv ./bin/gamecenter.{release,debug}.a ./bin/release/gamecenter

# Move InAppStore
mkdir ./bin/release/inappstore
mv ./bin/inappstore.{release,debug}.a ./bin/release/inappstore

# Move InAppStore
mkdir ./bin/release/icloud
mv ./bin/icloud.{release,debug}.a ./bin/release/icloud

# Move Camera
mkdir ./bin/release/camera
mv ./bin/camera.{release,debug}.a ./bin/release/camera

# Move ARKit
mkdir ./bin/release/arkit
mv ./bin/arkit.{release,debug}.a ./bin/release/arkit