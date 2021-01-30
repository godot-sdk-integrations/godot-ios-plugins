# Godot iOS plugins

`master` branch is current development branch and can introduce breaking changes to plugin's public interface. 
`3.2` branch aim is to provide same public interface as it was before switch to new iOS plugin system. 

## Instructions

* Clone this repository and it's submodules:
  ```
  git clone --recurse-submodules https://github.com/godotengine/godot-ios-plugins
  ```
  You might require to update `godot` submodule in case you require latest (unreleased) Godot changes. To do this run:
  ```
  cd godot
  git fetch
  git checkout origin/<branch you want to use>
  ```

* Alternatively you can use pre-extracted Godot headers that will be provided with release tag at [Releases page](https://github.com/godotengine/godot-ios-plugins/releases).  
  To do this clone this repo without submodules:
  ```
  git clone https://github.com/godotengine/godot-ios-plugins
  ```
  Then place extracted Godot headers in `godot` directory.  
  If you choose this option you can skip next step to genarate of Godot headers.

* To generate Godot headers you need to run compilation command inside `godot` submodule directory. 
  Example:
  ```
  scons platform=iphone target=debug
  ```
  You don't have to wait for full engine compilation as header files are generated first, so once an actual compilation starts you can stop this command.

* Running
  ```
  scons target=<debug|release|release_debug> arch=<arch> simulator=<no|yes> plugin=<plugin_name> version=<3.2|4.0>
  ```
  will generate `.a` static library for chosen target.  
  Do note, that Godot's default `debug` export template is compiled with `release_debug` target.

## Building a `.a` library

* Run `./scripts/generate_static_library.sh <plugin_name> <debug|release|release_debug> <godot_version>` to generate `fat` static library with specific configuration.

* The result `.a` binary will be stored in `bin` folder.

## Building a `.xcframework` library

* Run `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> <godot_version>`  to generate `xcframework` with specific configuration. `xcframework` allows plugin to support both `arm64` device and `arm64` simulator.

* The result `.xcframework` will be stored in `bin` folder as well as intermidiate `.a` binaries.
