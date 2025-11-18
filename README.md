# Godot iOS plugins

[`master` branch](https://github.com/godotengine/godot-ios-plugins/tree/master) is the current development branch and can introduce breaking changes to plugin's public interface.
[`3.3` branch](https://github.com/godotengine/godot-ios-plugins/tree/3.3)'s aim is to provide same public interface as it was before the switch to new iOS plugin system.

**Note:** iOS plugins are only effective on iOS (either on a physical device or
in the Xcode simulator). Their singletons will *not* be available when running
the project from the editor, so you need to export your project to test your changes.

## Instructions

- Clone this repository and its submodules:

```bash
git clone --recursive https://github.com/godotengine/godot-ios-plugins.git
```

You might have to the update `godot` submodule in case you require latest (unreleased) Godot changes. To do this, run:

```bash
cd godot
git fetch
git checkout origin/<branch you want to use>
```

- Alternatively, you can use pre-extracted Godot headers that will be provided
  with release tag on the [Releases page](https://github.com/godotengine/godot-ios-plugins/releases).
  To do this, clone this repository without submodules:

```bash
git clone https://github.com/godotengine/godot-ios-plugins.git
```

Then place the extracted Godot headers in the `godot/` directory.
If you choose this option, you can skip next the step which generates Godot headers.

- To generate Godot headers, you need to run the compilation command inside the `godot` submodule directory:

### For Godot 3.x:

```bash
scons platform=iphone target=debug
```

### For Godot 4.x:

```bash
scons platform=ios target=debug
```

You don't have to wait for full engine compilation, as header files are generated first.
Once the actual compilation starts, you can stop this command by pressing <kbd>Ctrl + C</kbd>.

- Run the command below to generate a `.dylib` dynamic library for chosen target:

**For Godot 3.x:**
```bash
scons target=<debug|release|release_debug> arch=<arch> simulator=<no|yes> plugin=<plugin_name> version=3.x
```

**For Godot 4.x:**
```bash
scons target=<template_debug|template_release> arch=<arch> simulator=<no|yes> plugin=<plugin_name> version=4.0
```

**Note:** Godot's official `debug` export templates are compiled with the `release_debug` target (Godot 3.x) or `template_debug` target (Godot 4.x), *not* the `debug` target.

## Building a `.dylib` library

- Run the scons command above to generate dynamic libraries with specific configuration.
- The result `.dylib` binary will be stored in the `bin/` folder.

## Building a `.xcframework` library

**For Godot 3.x:**
```bash
./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> 3.x
```

**For Godot 4.x:**
```bash
./scripts/generate_xcframework.sh <plugin_name> <template_debug|template_release> 4.0
```

The `xcframework` allows plugin to support both `arm64` device and `arm64` simulator.
The result `.xcframework` will be stored in the `bin/` folder as well as intermediate `.dylib` binaries.

## Documentation

Each plugin provides a `README.md` file which contains documentation and examples.
