
#include "haptic_engine_module.h"

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/config/engine.h"
#else
#include "core/engine.h"
#endif

#include "haptic_engine.h"

HapticEngine *haptic_engine;

void haptic_engine_init() {
	haptic_engine = memnew(HapticEngine);
	Engine::get_singleton()->add_singleton(Engine::Singleton("HapticEngine", haptic_engine));
}

void haptic_engine_deinit() {
	if (haptic_engine) {
		memdelete(haptic_engine);
	}
}
