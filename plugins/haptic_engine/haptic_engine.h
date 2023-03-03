
#ifndef HAPTIC_ENGINE_H
#define HAPTIC_ENGINE_H

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#else
#include "core/object.h"
#endif

#import <CoreHaptics/CoreHaptics.h>
// #import <Foundation/NSArray.h>

class HapticEngine : public Object {
	GDCLASS(HapticEngine, Object);

	static HapticEngine *instance;
	static void _bind_methods();

private:
	CHHapticEngine *haptic_engine API_AVAILABLE(ios(13)) = nullptr;

public:
	void vibrate(int duration_ms, float intensity, float sharpness);

	static HapticEngine *get_singleton();

	HapticEngine();
	~HapticEngine();
};

#endif
