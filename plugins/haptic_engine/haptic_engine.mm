
#include "haptic_engine.h"

#if VERSION_MAJOR == 4
#import "platform/ios/app_delegate.h"
#else
#import "platform/iphone/app_delegate.h"
#endif

#import <CoreHaptics/CoreHaptics.h>
// #import <Foundation/NSArray.h>

HapticEngine *HapticEngine::instance = NULL;
// static CHHapticEngine *haptic_engine API_AVAILABLE(ios(13)) = nullptr;

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
