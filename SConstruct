#!/usr/bin/env python

EnsureSConsVersion(0, 98, 1)

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
opts.Add(EnumVariable('platform', 'Platform build', 'iphone', ['', 'iphone', 'tvos']))
opts.Add(EnumVariable('target', "Compilation target", 'debug', ['debug', 'release', "release_debug"]))
opts.Add(EnumVariable('arch', "Compilation Architecture", '', ['', 'arm64', 'armv7', 'x86_64']))
opts.Add(BoolVariable('simulator', "Compilation platform", 'no'))
opts.Add(BoolVariable('use_llvm', "Use the LLVM / Clang compiler", 'no'))
opts.Add(PathVariable('target_path', 'The path where the lib is installed.', 'bin/'))
opts.Add(EnumVariable('plugin', 'Plugin to build', '', ['', 'apn', 'arkit', 'camera', 'icloud', 'gamecenter', 'inappstore', 'photo_picker']))
opts.Add(EnumVariable('version', 'Godot version to target', '', ['', '3.x', '4.0']))


opts.Add('sdk_version', 'SDK version ', '10.0')
# Updates the environment with the option variables.
opts.Update(env)


# Generates help for the -h scons option.
Help(opts.GenerateHelpText(env))

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

if env['platform'] == '':
    print("No valid platform selected.")
    quit();

if env['sdk_version'] == '':
    print("sdk version invalid.")
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


if env['platform'] == 'iphone':
    sdk_def_enable = '-DIPHONE_ENABLED'
    sdk_def = 'IPHONESDK'
    if env['simulator']:
        sdk_name = 'iphonesimulator'
        flag_version_min = '-mios-simulator-version-min='
    else:
        sdk_name = 'iphoneos'
        flag_version_min = '-miphoneos-version-min='
elif env['platform'] == 'tvos' :
    sdk_def_enable = '-DTVOS_ENABLED'
    sdk_def = "TVOSSDK"
	
	# tvOS requires Bitcode.
    env.Append(CCFLAGS=["-fembed-bitcode"])
    env.Append(LINKFLAGS=["-bitcode_bundle"])
	
    if env['simulator']:
        sdk_name = 'appletvsimulator'
        flag_version_min = '-mappletvsimulator-version-min='
    else:
        sdk_name = 'appletvos'
        flag_version_min = '-mappletvos-version-min='

try:
    sdk_path = decode_utf8(subprocess.check_output(['xcrun', '--sdk', sdk_name, '--show-sdk-path']).strip())
    if sdk_path :
       env[sdk_def] = sdk_path #SDK IPHONESDK=sdk_path
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



env.Append(CCFLAGS=['-isysroot', sdk_path, flag_version_min + env['sdk_version']])
env.Append(LINKFLAGS=['-isysroot', sdk_path, flag_version_min + env['sdk_version'], '-F' + sdk_path])

env.Append(CCFLAGS=['-arch', env['arch'], '-stdlib=libc++'])
env.Append(CCFLAGS=['-DPTRCALL_ENABLED'])
env.Prepend(CXXFLAGS=[
    '-DNEED_LONG_INT', '-DLIBYUV_DISABLE_NEON', 
    sdk_def_enable, '-DUNIX_ENABLED', '-DCOREAUDIO_ENABLED'
])
env.Append(LINKFLAGS=["-arch", env['arch'], '-F' + sdk_path])

if env['arch'] == 'armv7':
    env.Prepend(CXXFLAGS=['-fno-aligned-allocation'])

if env['version'] == '3.x':
    env.Prepend(CFLAGS=['-std=gnu11'])
    env.Prepend(CXXFLAGS=['-DGLES_ENABLED', '-std=gnu++14'])

    env.Prepend(
        CPPPATH=[
            sdk_path + "/usr/include",
            sdk_path + "/System/Library/Frameworks/OpenGLES.framework/Headers",
            sdk_path + "/System/Library/Frameworks/AudioUnit.framework/Headers",
        ]
    )

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

if env['platform'] == 'iphone' :

    # Adding header files
    env.Append(CPPPATH=[
        '.',
        'godot', 
        'godot/platform/iphone',
    ])

elif env['platform'] == 'tvos' :
 # Adding header files
    env.Append(CPPPATH=[
        '.', 
        'godot', 
        'godot/platform/tvos',
    ])


# tweak this if you want to use different folders, or more folders, to store your source code in.
sources = Glob('plugins/' + env['plugin'] + '/*.cpp')
sources.append(Glob('plugins/' + env['plugin'] + '/*.mm'))
sources.append(Glob('plugins/' + env['plugin'] + '/*.m'))

# lib<plugin>.<arch>-<platform>.<simulator>.<release|debug|release_debug>.a
# lib<plugin>.<arch>-<platform>.<release|debug|release_debug>.a
library_platform = env['arch'] + '-' + env['platform'] + ('.simulator' if env['simulator'] else '')
library_name = env['plugin'] + "." + library_platform + "." + env['target'] + '.a'
library = env.StaticLibrary(target=env['target_path'] + library_name, source=sources)

Default(library)

