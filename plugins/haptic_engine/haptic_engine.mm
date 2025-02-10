/*************************************************************************/
/*  haptic_engine.mm                                                     */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2021 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "haptic_engine.h"

#if VERSION_MAJOR == 4
#import "platform/ios/app_delegate.h"
#else
#import "platform/iphone/app_delegate.h"
#endif

#import <CoreHaptics/CoreHaptics.h>

HapticEngine *HapticEngine::instance = NULL;

void HapticEngine::_bind_methods() {
	ClassDB::bind_method(D_METHOD("vibrate"), &HapticEngine::vibrate);
};

void HapticEngine::vibrate(int duration_ms, float intensity, float sharpness) API_AVAILABLE(ios(13)) {
	if (haptic_engine == nullptr) {
		NSLog(@"Haptic engine not available");
		return;
	}

	NSDictionary *hapticDict = @{
		CHHapticPatternKeyPattern : @[
			@{CHHapticPatternKeyEvent : @{
				CHHapticPatternKeyEventType : CHHapticEventTypeHapticContinuous,
				CHHapticPatternKeyTime : @(CHHapticTimeImmediate),
				CHHapticPatternKeyEventDuration : @((float)duration_ms / 1000.f),
				CHHapticPatternKeyEventParameters : @[
					@{
						CHHapticPatternKeyParameterID : CHHapticEventParameterIDHapticIntensity,
						CHHapticPatternKeyParameterValue : @(intensity)
					},
					@{
						CHHapticPatternKeyParameterID : CHHapticEventParameterIDHapticSharpness,
						CHHapticPatternKeyParameterValue : @(sharpness)
					}
				]
			},
			},
		],
	};

	NSError *error;
	CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithDictionary:hapticDict error:&error];
	if (error) {
		NSLog(@"Could not initialize haptic pattern: %@", error);
		return;
	}

	[[haptic_engine createPlayerWithPattern:pattern error:&error] startAtTime:0 error:&error];
	if (error) {
		NSLog(@"Could not play haptic pattern: %@", error);
		return;
	}
}

HapticEngine *HapticEngine::get_singleton() {
	return instance;
}

HapticEngine::HapticEngine() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;

	if (@available(iOS 13, *)) {
		id<CHHapticDeviceCapability> capabilities = [CHHapticEngine capabilitiesForHardware];
		if (!capabilities.supportsHaptics) {
			NSLog(@"Hardware does not support haptics");
			return;
		}

		NSError *error = nullptr;
		haptic_engine = [[CHHapticEngine alloc] initAndReturnError:&error];
		if (error) {
			haptic_engine = nullptr;
			NSLog(@"Could not initialize haptic engine: %@", error);
		}

		[haptic_engine setAutoShutdownEnabled:true];
	} else {
		NSLog(@"Haptic engine requires iOS 13 or older");
	}
};

HapticEngine::~HapticEngine() {
	if (@available(iOS 13, *)) {
		if (haptic_engine) {
			[haptic_engine stopWithCompletionHandler:^(NSError *error) {
				if (error) {
					NSLog(@"Could not stop haptic engine: %@", error);
				}
			}];
		}
	}
}
