#!/bin/bash
if [[ "$1" == "3.x" ]];
then
    cd ./godot && \
        ./../scripts/timeout scons platform=iphone target=release_debug
else
    cd ./godot && \
        ./../scripts/timeout scons platform=ios target=release_debug  
fi
