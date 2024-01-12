#!/bin/bash
rm -rf ./bin/.*healthkit.* ./healthkit/.*.d ./healthkit/.*.o
scons target=release_debug arch=arm64 simulator=no plugin=healthkit version=4.0
./scripts/generate_static_library.sh healthkit release_debug 4.0
./scripts/generate_xcframework.sh healthkit release_debug 4.0
mv ./bin/healthkit.release_debug.xcframework ./bin/healthkit.xcframework
