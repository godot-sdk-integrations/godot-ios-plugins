# Godot iOS/tvOS plugins

> [!NOTE]
>
> iOS plugins are not editor plugins.

[`master` branch](https://github.com/godotengine/godot-ios-plugins/tree/master) is the current development branch and can introduce breaking changes to plugin's public interface.
[`3.3` branch](https://github.com/godotengine/godot-ios-plugins/tree/3.3)'s aim is to provide same public interface as it was before the switch to new iOS plugin system.

**Note:** Apple embedded plugins are only effective on exported iOS/tvOS apps
(either on a physical device or in a supported Xcode simulator). Their
singletons will *not* be available when running the project from the editor, so
you need to export your project to test your changes.

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


1. After cloning this repository, go to `godot` submodule and switch to the tag of the engine version you are working with. For example, `git checkout 4.4-stable`.

2. If the version is lower than 4.4, you will need to cherry-pick the commit from [here](https://github.com/godotengine/godot/pull/97510). Depending on the version, it might cause a conflict in the file `drivers/vulkan/rendering_context_driver_vulkan.h` which you resolve by taking the changes from the cherry-picked commit for the conflicting section only.

3. Install `scons` if it is not already installed (eg `brew install scons`).

4. [Build Godot for iOS target](https://docs.godotengine.org/en/stable/engine_details/development/compiling/compiling_for_ios.html): `scons platform=ios target=editor`

5. Run the plugin creation script. This step needs to be repeated for each of the plugins you want to use. Go to the root of this repository then run `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> 4.0`. The result will be an xcframework in bin directory.

### Extra info

- Run the command below to generate an `.a` static library for chosen target:

```bash
scons target=<debug|release|release_debug> arch=<arch> simulator=<no|yes> platform=<ios|tvos> plugin=<plugin_name> version=<3.x|4.0>
```

The default `platform` is `ios`, matching the previous behavior. For tvOS
Game Center builds, use Godot 4.x headers:

```bash
scons target=release_debug arch=arm64 platform=tvos plugin=gamecenter version=4.0
```

**Note:** Godot's official `debug` export templates are compiled with the `release_debug` target, *not* the `debug` target.

#### Building a `.a` library

- Run the `scons` command above for the platform, architecture, simulator, and
  plugin you need.
- The result `.a` binary will be stored in the `bin/` folder.

#### Building a `.xcframework` library

- Run `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> <godot_version>`
  to generate `xcframework` with specific configuration.
  `xcframework` allows plugin to support both device and simulator slices.
- The result `.xcframework` will be stored in the `bin/` folder as well as intermidiate `.a` binaries.
- Pass a fourth argument to choose the platform:

```bash
./scripts/generate_xcframework.sh gamecenter release_debug 4.0 ios
./scripts/generate_xcframework.sh gamecenter release_debug 4.0 tvos
./scripts/generate_xcframework.sh gamecenter release_debug 4.0 all
```

The default remains `ios` to preserve the previous build behavior. iOS
xcframeworks include `ios-arm64` and `ios-arm64_x86_64-simulator`; tvOS
xcframeworks include `tvos-arm64` and `tvos-arm64_x86_64-simulator`. Passing
`all` packages all four Apple embedded slices into one xcframework.

## Adding plugins to a Godot project

More detailed instructions can be found in the [official docs](https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html#loading-and-using-an-existing-plugin).

1. Build both release and debug xcframeworks of the desired plugin.

2. In your Godot project, create `res://ios/plugin` and copy there the `<plugin name>.gdip` (from the plugin source directory in this repository) and both `*.xcframework` files for the plugin (from the `bin/` directory).

3. Go to **Project > Export** and select the iOS export preset (or create one if it doesn't exist already). In the **Options** tab, scroll to **Plugins** and enable the plugin.

## C\#

It is possible to verify that the plugin's singleton is loaded using `Engine.HasSingleton("InAppStore")` and get access to it with `Engine.GetSingleton("InAppStore")`.

The return type is always `GodotObject`. The methods which the plugin expose can be called indirectly with `Variant Call(StringName method, params Variant[] @args)` metod of `GodotObject`.

## Documentation

Each plugin provides a `README.md` file which contains documentation and examples.
