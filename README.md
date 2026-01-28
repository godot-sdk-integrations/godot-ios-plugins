# Godot iOS plugins

[`master` branch](https://github.com/godotengine/godot-ios-plugins/tree/master) is the current development branch and can introduce breaking changes to plugin's public interface.
[`3.3` branch](https://github.com/godotengine/godot-ios-plugins/tree/3.3)'s aim is to provide same public interface as it was before the switch to new iOS plugin system.

**Note:** iOS plugins are only effective on iOS (either on a physical device or
in the Xcode simulator). Their singletons will *not* be available when running
the project from the editor, so you need to export your project to test your changes.

## Instructions

### Step 1: Clone repository and obtain header files

There are two ways to obtain header files:
- Option A: Use pre-extracted headers provided on the [Releases page](https://github.com/godotengine/godot-ios-plugins/releases). If the version you need is missing, you'll have to generate them yourself.
- Option B: Generate header files yourself.

#### Option A: Using pre-extracted headers

First, clone this repository without submodules.
```bash
git clone https://github.com/godotengine/godot-ios-plugins.git
```

Then place the extracted Godot headers in the `godot/` subfolder.

#### Option B: Generate headers yourself

Clone this repository and its submodules:

```bash
git clone --recursive https://github.com/godotengine/godot-ios-plugins.git
```

In the `godot` submodule, checkout the [tag](https://github.com/godotengine/godot/tags) that corresponds with the Godot version you are using (e.g., `4.6-stable`).

```bash
cd godot
git fetch --tags origin
git checkout 4.6.0-stable
```

Run the compilation command in the `godot` submodule directory.

```bash
# Godot 4.x:
scons platform=ios target=template_debug

# Godot 3.x:
scons platform=iphone target=debug
```

> [!TIP]
> You don't have to wait for full engine compilation, as header files are generated first.
> Once the actual compilation starts, you can stop it by pressing <kbd>Ctrl + C</kbd>.

From the main repository root folder, run the command below to generate an `.a` static library.

```bash
scons target=<debug|release|release_debug> arch=<arch> simulator=<no|yes> plugin=<plugin_name> version=<3.x|4.0>
```

> [!NOTE]
> Godot's official `debug` export templates are compiled with the `release_debug` target, *not* the `debug` target.
> Therefore, most users will want to use the `release_debug` target.

### Step 2: Build library file(s)

#### Building an `.a` library

- Run `./scripts/generate_static_library.sh <plugin_name> <debug|release|release_debug> <godot_version>`
  to generate `fat` static library with a specific configuration.
- The result `.a` binary will be stored in the `bin/` folder.

#### Building an `.xcframework` library

- Run `./scripts/generate_xcframework.sh <plugin_name> <debug|release|release_debug> <godot_version>`
  to generate `xcframework` with a specific configuration.
  `xcframework` allows plugin to support both `arm64` device and `arm64` simulator.
- The result `.xcframework` will be stored in the `bin/` folder as well as intermidiate `.a` binaries.

## Documentation

Each plugin provides a `README.md` file which contains documentation and examples. See also the [official docs](docs.godotengine.org/en/stable/tutorials/platform/ios/plugins_for_ios.html).

