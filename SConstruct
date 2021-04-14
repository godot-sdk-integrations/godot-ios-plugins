#!/usr/bin/env python
import os
import sys
import subprocess

if sys.version_info < (3,):
    def decode_utf8(x):
        return x
else:
    import codecs
    def decode_utf8(x):
        return codecs.utf_8_decode(x)[0]

# Most of the settings are taken from https://github.com/BastiaanOlij/gdnative_cpp_example

opts = Variables([], ARGUMENTS)

# Gets the standard flags CC, CCX, etc.
env = DefaultEnvironment()

# Define our options
opts.Add(EnumVariable('target', "Compilation target", 'debug', ['debug', 'release', "release_debug"]))
opts.Add(EnumVariable('arch', "Compilation Architecture", '', ['', 'arm64', 'armv7', 'x86_64']))
opts.Add(BoolVariable('simulator', "Compilation platform", 'no'))
opts.Add(BoolVariable('use_llvm', "Use the LLVM / Clang compiler", 'no'))
opts.Add(PathVariable('target_path', 'The path where the lib is installed.', 'bin/'))
opts.Add(EnumVariable('plugin', 'Plugin to build', '', ['', 'apn', 'arkit', 'camera', 'icloud', 'gamecenter', 'inappstore']))
opts.Add(EnumVariable('version', 'Godot version to target', '', ['', '3.3', '4.0']))

# Updates the environment with the option variables.
opts.Update(env)

# Process some arguments
if env['use_llvm']:
    env['CC'] = 'clang'
    env['CXX'] = 'clang++'

if env['arch'] == '':
    print("No valid arch selected.")
    quit();

if env['plugin'] == '':
    print("No valid plugin selected.")
    quit();

if env['version'] == '':
    print("No valid Godot version selected.")
    quit();

# For the reference:
# - CCFLAGS are compilation flags shared between C and C++
# - CFLAGS are for C-specific compilation flags
# - CXXFLAGS are for C++-specific compilation flags
# - CPPFLAGS are for pre-processor flags
# - CPPDEFINES are for pre-processor defines
# - LINKFLAGS are for linking flags

# Enable Obj-C modules
env.Append(CCFLAGS=["-fmodules", "-fcxx-modules"])

if env['simulator']:
    sdk_name = 'iphonesimulator'
    env.Append(CCFLAGS=['-mios-simulator-version-min=10.0'])
    env.Append(LINKFLAGS=["-mios-simulator-version-min=10.0"])
else:
    sdk_name = 'iphoneos'
    env.Append(CCFLAGS=['-miphoneos-version-min=10.0'])
    env.Append(LINKFLAGS=["-miphoneos-version-min=10.0"])

try:
    sdk_path = decode_utf8(subprocess.check_output(['xcrun', '--sdk', sdk_name, '--show-sdk-path']).strip())
except (subprocess.CalledProcessError, OSError):
    raise ValueError("Failed to find SDK path while running xcrun --sdk {} --show-sdk-path.".format(sdk_name))

env.Append(CCFLAGS=[
    '-fobjc-arc', 
    '-fmessage-length=0', '-fno-strict-aliasing', '-fdiagnostics-print-source-range-info', 
    '-fdiagnostics-show-category=id', '-fdiagnostics-parseable-fixits', '-fpascal-strings', 
    '-fblocks', '-fvisibility=hidden', '-MMD', '-MT', 'dependencies', '-fno-exceptions', 
    '-Wno-ambiguous-macro', 
    '-Wall', '-Werror=return-type',
    # '-Wextra',
])

env.Append(CCFLAGS=['-arch', env['arch'], "-isysroot", "$IPHONESDK", "-stdlib=libc++", '-isysroot', sdk_path])
env.Append(CCFLAGS=['-DPTRCALL_ENABLED'])
env.Prepend(CXXFLAGS=[
    '-DNEED_LONG_INT', '-DLIBYUV_DISABLE_NEON', 
    '-DIPHONE_ENABLED', '-DUNIX_ENABLED', '-DCOREAUDIO_ENABLED'
])
env.Append(LINKFLAGS=["-arch", env['arch'], '-isysroot', sdk_path, '-F' + sdk_path])

if env['arch'] == 'armv7':
    env.Prepend(CXXFLAGS=['-fno-aligned-allocation'])

if env['version'] == '3.3':
    env.Prepend(CFLAGS=['-std=gnu11'])
    env.Prepend(CXXFLAGS=['-DGLES_ENABLED', '-std=gnu++14'])

    if env['target'] == 'debug':
        env.Prepend(CXXFLAGS=[
            '-gdwarf-2', '-O0', 
            '-DDEBUG_MEMORY_ALLOC', '-DDISABLE_FORCED_INLINE', 
            '-D_DEBUG', '-DDEBUG=1', '-DDEBUG_ENABLED',
            '-DPTRCALL_ENABLED',
        ])
    elif env['target'] == 'release_debug':
        env.Prepend(CXXFLAGS=['-O2', '-ftree-vectorize',
            '-DNDEBUG', '-DNS_BLOCK_ASSERTIONS=1', '-DDEBUG_ENABLED', 
            '-DPTRCALL_ENABLED',
        ])

        if env['arch'] != 'armv7':
            env.Prepend(CXXFLAGS=['-fomit-frame-pointer'])
    else:
        env.Prepend(CXXFLAGS=[
            '-O2', '-ftree-vectorize',
            '-DNDEBUG', '-DNS_BLOCK_ASSERTIONS=1', 
            '-DPTRCALL_ENABLED',
        ])

        if env['arch'] != 'armv7':
            env.Prepend(CXXFLAGS=['-fomit-frame-pointer'])
elif env['version'] == '4.0':
    env.Prepend(CFLAGS=['-std=gnu11'])
    env.Prepend(CXXFLAGS=['-DVULKAN_ENABLED', '-std=gnu++17'])

    if env['target'] == 'debug':
        env.Prepend(CXXFLAGS=[
            '-gdwarf-2', '-O0', 
            '-DDEBUG_MEMORY_ALLOC', '-DDISABLE_FORCED_INLINE', 
            '-D_DEBUG', '-DDEBUG=1', '-DDEBUG_ENABLED', 
        ])
    elif env['target'] == 'release_debug':
        env.Prepend(CXXFLAGS=[
            '-O2', '-ftree-vectorize',
            '-DNDEBUG', '-DNS_BLOCK_ASSERTIONS=1', '-DDEBUG_ENABLED',
        ])

        if env['arch'] != 'armv7':
            env.Prepend(CXXFLAGS=['-fomit-frame-pointer'])
    else:
        env.Prepend(CXXFLAGS=[
            '-O2', '-ftree-vectorize',
            '-DNDEBUG', '-DNS_BLOCK_ASSERTIONS=1',
        ])

        if env['arch'] != 'armv7':
            env.Prepend(CXXFLAGS=['-fomit-frame-pointer'])            
else:
    print("No valid version to set flags for.")
    quit();

# Adding header files
env.Append(CPPPATH=[
    '.', 
    'godot', 
    'godot/main', 
    'godot/core', 
    'godot/core/os', 
    'godot/core/platform',
    'godot/platform/iphone',
    'godot/modules',
    'godot/scene',
    'godot/servers',
    'godot/drivers',
    'godot/thirdparty',
])

# tweak this if you want to use different folders, or more folders, to store your source code in.
sources = Glob('plugins/' + env['plugin'] + '/*.cpp')
sources.append(Glob('plugins/' + env['plugin'] + '/*.mm'))
sources.append(Glob('plugins/' + env['plugin'] + '/*.m'))

# lib<plugin>.<arch>-<simulator|iphone>.<release|debug|release_debug>.a
library_platform = env["arch"] + "-" + ("simulator" if env["simulator"] else "iphone")
library_name = env['plugin'] + "." + library_platform + "." + env["target"] + ".a"
library = env.StaticLibrary(target=env['target_path'] + library_name, source=sources)

Default(library)

# Generates help for the -h scons option.
Help(opts.GenerateHelpText(env))
