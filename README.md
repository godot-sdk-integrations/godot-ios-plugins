# Godot iOS plugins


## Building a `.a` library

* Use submodule to pull required Godot version into `godot` folder. (`master` branch for `4.0` and `3.2` branch for `3.2` version)  
  Alternatively you can place a Godot's header files including generated ones at `godot` folder.  
  You can extract headers from Godot's source manually or by using `extract_headers.sh` script from `scripts` folder.

* Run `scons target=<debug|release|release_debug> arch=<arch> simulator=<no|yes> plugin=<plugin_name> version=<3.2|4.0>` to compile the plugin you need for specific version of Godot.  
  You can also use `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> <godot_version>` to generate fat static library with specific configuration.

* The result `.a` binary will be stored in `bin` folder.

## Building a `.xcframework` library

* Use submodule to pull required Godot version into `godot` folder. (`master` branch for `4.0` and `3.2` branch for `3.2` version)  
  Alternatively you can place a Godot's header files including generated ones at `godot` folder.  
  You can extract headers from Godot's source manually or by using `extract_headers.sh` script from `scripts` folder.

* Run `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> <godot_version>` 

* The result `.xcframework` will be stored in `bin` folder as well as intermidiate `.a` binaries.