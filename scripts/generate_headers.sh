#!/bin/bash
cd ./godot && \
    ./../scripts/timeout scons platform=iphone target=release_debug
