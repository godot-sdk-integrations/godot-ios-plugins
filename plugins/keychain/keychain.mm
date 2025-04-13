/*************************************************************************/
/*  keychain.mm                                                               */
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

#include "keychain.h"

#import <Foundation/Foundation.h>

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#include "core/config/project_settings.h"
#else
#include "core/class_db.h"
#include "core/project_settings.h"
#endif

#import "keychain_wrapper.h"

static KeychainPlugin *singleton;

KeychainPlugin *KeychainPlugin::get_singleton() {
	return singleton;
}

void KeychainPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_string", "key", "value"), &KeychainPlugin::set_string);
	ClassDB::bind_method(D_METHOD("get_string", "key"), &KeychainPlugin::get_string);
	ClassDB::bind_method(D_METHOD("delete_key", "key"), &KeychainPlugin::delete_key);
}

void KeychainPlugin::set_string(const String &key, const String &value) {
	NSString *ns_key = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSString *ns_value = [NSString stringWithUTF8String:value.utf8().get_data()];
	[KeychainWrapper setString:ns_value forKey:ns_key];
}

String KeychainPlugin::get_string(const String &key) const {
	NSString *ns_key = [NSString stringWithUTF8String:key.utf8().get_data()];
	NSString *result = [KeychainWrapper getStringForKey:ns_key];
	if (!result) return "";
	return String::utf8([result UTF8String]);
}

void KeychainPlugin::delete_key(const String &key) {
	NSString *ns_key = [NSString stringWithUTF8String:key.utf8().get_data()];
	[KeychainWrapper deleteStringForKey:ns_key];
}

KeychainPlugin::KeychainPlugin() {
	singleton = this;
}

KeychainPlugin::~KeychainPlugin() {
	singleton = NULL;
}
