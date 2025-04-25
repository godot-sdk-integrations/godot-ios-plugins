/*************************************************************************/
/*  apn.mm                                                               */
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

#include "apn.h"

#import <Foundation/Foundation.h>

#if VERSION_MAJOR >= 4
#include "core/object/class_db.h"
#include "core/config/project_settings.h"
#else
#include "core/class_db.h"
#include "core/project_settings.h"
#endif

#import "godot_apn_delegate.h"

static APNPlugin *singleton;

APNPlugin *APNPlugin::get_singleton() {
	return singleton;
}

void APNPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("register_push_notifications", "options"), &APNPlugin::register_push_notifications);

	ClassDB::bind_method(D_METHOD("set_badge_number", "value"), &APNPlugin::set_badge_number);
	ClassDB::bind_method(D_METHOD("get_badge_number"), &APNPlugin::get_badge_number);
	ADD_PROPERTY(PropertyInfo(Variant::INT, "badge_number"), "set_badge_number", "get_badge_number");

	ADD_SIGNAL(MethodInfo("device_address_changed", PropertyInfo(Variant::STRING, "id")));

	BIND_ENUM_CONSTANT(PUSH_ALERT);
	BIND_ENUM_CONSTANT(PUSH_BADGE);
	BIND_ENUM_CONSTANT(PUSH_SOUND);
	BIND_ENUM_CONSTANT(PUSH_SETTINGS);
}

void APNPlugin::register_push_notifications(PushOptions options) {
	UNAuthorizationOptions notificationsOptions = UNAuthorizationOptionNone;

	if (options & PUSH_ALERT) {
		notificationsOptions |= UNAuthorizationOptionAlert;
	}

	if (options & PUSH_BADGE) {
		notificationsOptions |= UNAuthorizationOptionBadge;
	}

	if (options & PUSH_SOUND) {
		notificationsOptions |= UNAuthorizationOptionSound;
	}

	[[GodotAPNAppDelegate shared] registerPushNotificationsWithOptions:notificationsOptions];
}

void APNPlugin::update_device_token(String token) {
	emit_signal("device_address_changed", token);
}

void APNPlugin::set_badge_number(int value) {
	UIApplication.sharedApplication.applicationIconBadgeNumber = (long)value;
}

int APNPlugin::get_badge_number() {
	return (int)UIApplication.sharedApplication.applicationIconBadgeNumber;
}

APNPlugin::APNPlugin() {
	singleton = this;
}

APNPlugin::~APNPlugin() {
	singleton = NULL;
}
