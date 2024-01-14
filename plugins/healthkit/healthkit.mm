/*************************************************************************/
/*  healthkit.mm                                                         */
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

#include "healthkit.h"

#if VERSION_MAJOR == 4
#import "platform/ios/app_delegate.h"
#else
#import "platform/iphone/app_delegate.h"
#endif

#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>
#import <HealthKit/HKHealthStore.h>

HealthKit *HealthKit::_instance = NULL;

static HKHealthStore *_health_store;

void HealthKit::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_health_data_available"), &HealthKit::is_health_data_available);
	ClassDB::bind_method(D_METHOD("request_authorization", "to_share", "to_read"), &HealthKit::request_authorization, DEFVAL(Vector<int>()), DEFVAL(Vector<int>()));
	ClassDB::bind_method(D_METHOD("execute_statistics_query", "quantity_type", "start_date", "end_date"), &HealthKit::execute_statistics_query);

	ADD_SIGNAL(MethodInfo("authorization_completed", PropertyInfo(Variant::INT, "object_type"), PropertyInfo(Variant::INT, "status")));
	ADD_SIGNAL(MethodInfo("statistics_query_completed", PropertyInfo(Variant::INT, "quantity_type"), PropertyInfo(Variant::FLOAT, "value")));
	ADD_SIGNAL(MethodInfo("statistics_query_failed", PropertyInfo(Variant::INT, "quantity_type"), PropertyInfo(Variant::INT, "error_code")));

	BIND_ENUM_CONSTANT(AUTHORIZATION_STATUS_NOT_DETERMINED);
	BIND_ENUM_CONSTANT(AUTHORIZATION_STATUS_NOT_DETERMINED);
	BIND_ENUM_CONSTANT(AUTHORIZATION_STATUS_DENIED);
	BIND_ENUM_CONSTANT(AUTHORIZATION_STATUS_AUTHORIZED);

	BIND_ENUM_CONSTANT(OBJECT_TYPE_UNKNOWN);
	BIND_ENUM_CONSTANT(OBJECT_TYPE_QUANTITY_TYPE_STEP_COUNT);
	BIND_ENUM_CONSTANT(OBJECT_TYPE_QUANTITY_TYPE_ACTIVE_ENERY_BURNED);

	BIND_ENUM_CONSTANT(QUANTITY_TYPE_UNKNOWN);
	BIND_ENUM_CONSTANT(QUANTITY_TYPE_STEP_COUNT);
	BIND_ENUM_CONSTANT(QUANTITY_TYPE_ACTIVE_ENERY_BURNED);
}

HealthKit *HealthKit::get_singleton() {
	return _instance;
}

bool HealthKit::is_health_data_available() const {
	return HKHealthStore.isHealthDataAvailable;
}

static NSSet *_nsset_from_object_type_vector(Vector<int> obj_type_vector) {
	NSMutableSet *to_share_nsmutableset = [NSMutableSet set];

	for (int i = 0; i < obj_type_vector.size(); i++) {
		HealthKit::ObjectType object_type = (HealthKit::ObjectType)obj_type_vector[i];
		HKObjectType *object_type_nsobj;

		switch (object_type) {
			case HealthKit::OBJECT_TYPE_QUANTITY_TYPE_STEP_COUNT:
				object_type_nsobj = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
				break;
			case HealthKit::OBJECT_TYPE_QUANTITY_TYPE_ACTIVE_ENERY_BURNED:
				object_type_nsobj = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
				break;
			case HealthKit::OBJECT_TYPE_UNKNOWN:
			default:
				NSLog(@"Error unknown object type");
				return [NSSet set];
		}

		[to_share_nsmutableset addObject:object_type_nsobj];
	}

	return [NSSet setWithSet:to_share_nsmutableset];
}

Error HealthKit::request_authorization(Vector<int> to_share, Vector<int> to_read) {
	NSLog(@"Requesting HealthKit authorization...");

	if (!is_health_data_available()) {
		NSLog(@"HealthKit is not available");
		return ERR_UNAVAILABLE;
	}

	NSSet *to_share_nsset = _nsset_from_object_type_vector(to_share);
	if (to_share_nsset.count != to_share.size()) {
		NSLog(@"Error while requesting HealthKit authorization.");
		return ERR_INVALID_PARAMETER;
	}
	NSSet *to_read_nsset = _nsset_from_object_type_vector(to_read);
	if (to_read_nsset.count != to_read.size()) {
		NSLog(@"Error while requesting HealthKit authorization.");
		return ERR_INVALID_PARAMETER;
	}

	[_health_store requestAuthorizationToShareTypes:to_share_nsset readTypes:to_read_nsset completion:^(BOOL success, NSError *error) {
		NSLog(@"HealthKit authorization completed.");

		if (error) {
			NSLog(@"Error while requesting HealthKit authorization: %@", error);
			emit_signal("authorization_completed", OBJECT_TYPE_UNKNOWN, AUTHORIZATION_STATUS_NOT_DETERMINED);
			return;
		}

		if (success) {
			NSLog(@"HealthKit authorization succeeded.");
			emit_signal("authorization_completed", OBJECT_TYPE_UNKNOWN, AUTHORIZATION_STATUS_AUTHORIZED);
		} else {
			NSLog(@"HealthKit authorization failed.");
			emit_signal("authorization_completed", OBJECT_TYPE_UNKNOWN, AUTHORIZATION_STATUS_DENIED);
		}
	}];

	return OK;
}

Error HealthKit::execute_statistics_query(QuantityType quantity_type, int start_date, int end_date) {
	NSLog(@"Executing HealthKit statistics query...");

	if (!is_health_data_available()) {
		NSLog(@"HealthKit is not available");
		return ERR_UNAVAILABLE;
	}

	NSDate *start_date_nsdate = [NSDate dateWithTimeIntervalSince1970:start_date];
	NSDate *end_date_nsdate = [NSDate dateWithTimeIntervalSince1970:end_date];

	HKQuantityType *hk_quantity_type;
	switch (quantity_type) {
		case QUANTITY_TYPE_STEP_COUNT:
			hk_quantity_type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
			break;
		case QUANTITY_TYPE_ACTIVE_ENERY_BURNED:
			hk_quantity_type = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
			break;
		case QUANTITY_TYPE_UNKNOWN:
		default:
			NSLog(@"Unknown quantity type");
			return ERR_INVALID_PARAMETER;
	}

	NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:start_date_nsdate endDate:end_date_nsdate options:HKQueryOptionNone];

	HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:hk_quantity_type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
		NSLog(@"HealthKit query completed.");

		if (error) {
			NSLog(@"Error while querying health data: %@", error);
			emit_signal("statistics_query_failed", quantity_type, error.code);
			return;
		}

		HKQuantity *quantity = [result sumQuantity];
		double value = [quantity doubleValueForUnit:[HKUnit countUnit]];

		emit_signal("statistics_query_completed", quantity_type, value);
	}];

	[_health_store executeQuery:query];
	NSLog(@"HealthKit query executed.");

	return OK;
}

HealthKit::HealthKit() {
	ERR_FAIL_COND(_instance != NULL);
	_instance = this;

	NSLog(@"Creating HealthStore...");
	if (is_health_data_available()) {
		_health_store = [[HKHealthStore alloc] init];
		NSLog(@"HealthStore created.");
	} else {
		NSLog(@"HealthKit is not available");
		NSLog(@"HealthStore creation failed.");
	}
}

HealthKit::~HealthKit() {
}
