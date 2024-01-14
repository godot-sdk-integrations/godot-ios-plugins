/*************************************************************************/
/*  healthkit.h                                                          */
/*************************************************************************/
/*                       This file is part of:                            */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2021 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the        */
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

#ifndef HEALTHKIT_H
#define HEALTHKIT_H

#include "core/version.h"

#if VERSION_MAJOR == 4
#include "core/object/class_db.h"
#include "core/templates/vector.h"
#else
#include "core/object.h"
#include "core/vector.h"
#endif

class HealthKit : public Object {
	GDCLASS(HealthKit, Object);

	static HealthKit *_instance;

	static void _bind_methods();

public:

	enum AuthorizationStatus {
		AUTHORIZATION_STATUS_NOT_DETERMINED,
		AUTHORIZATION_STATUS_DENIED,
		AUTHORIZATION_STATUS_AUTHORIZED,
	};

	enum SharingAuthorizationStatus {
		SHARING_AUTHORIZATION_STATUS_NOT_DETERMINED,
		SHARING_AUTHORIZATION_STATUS_DENIED,
		SHARING_AUTHORIZATION_STATUS_AUTHORIZED,
	};

	enum ObjectType {
		OBJECT_TYPE_UNKNOWN,
		OBJECT_TYPE_QUANTITY_TYPE_STEP_COUNT,
		OBJECT_TYPE_QUANTITY_TYPE_ACTIVE_ENERY_BURNED,
	};

	enum QuantityType {
		QUANTITY_TYPE_UNKNOWN,
		QUANTITY_TYPE_STEP_COUNT,
		QUANTITY_TYPE_ACTIVE_ENERY_BURNED,
	};

	static HealthKit *get_singleton();

	bool is_health_data_available() const;
	Error request_authorization(Vector<int> to_share, Vector<int> to_read);
	SharingAuthorizationStatus authorization_status_for_type(ObjectType object_type);
	Error execute_statistics_query(QuantityType quantity_type, int start_date, int end_date);

	HealthKit();
	~HealthKit();
};

VARIANT_ENUM_CAST(HealthKit::AuthorizationStatus);
VARIANT_ENUM_CAST(HealthKit::SharingAuthorizationStatus);
VARIANT_ENUM_CAST(HealthKit::ObjectType);
VARIANT_ENUM_CAST(HealthKit::QuantityType);

#endif
