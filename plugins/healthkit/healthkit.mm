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

HealthKit* HealthKit::instance = NULL;
HKHealthStore* healthStore = NULL;

void HealthKit::_bind_methods() {
	ClassDB::bind_method(D_METHOD("is_available"), &HealthKit::is_available);
	ClassDB::bind_method(D_METHOD("create_health_store"), &HealthKit::create_health_store);
	//ClassDB::bind_method(D_METHOD("query_health_data", "start_date", "end_date", "data_type" /*, "callback"*/), &HealthKit::query_health_data);
}

HealthKit* HealthKit::get_singleton() {
	return instance;
}

HealthKit::HealthKit() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;
}

HealthKit::~HealthKit() {
}

bool HealthKit::is_available() const {
	return HKHealthStore.isHealthDataAvailable;
}

Error HealthKit::create_health_store() {
	if (!is_available()) {
		NSLog(@"HealthKit is not available");
		return ERR_UNAVAILABLE;
	}

	healthStore = [[HKHealthStore alloc] init];
	return OK;
}

#if 0
static NSDate* create_date_from_unix_timestamp(long timestamp) {
	return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

static void call_query_callback(Callable* callback, double value) {
	// Return result
	Callable::CallError err;
	Variant args[] = { value };
	callback.callp(&args, 1, NULL, &err);
	if (err.error != Callable::CallError::CALL_OK) {
		ERR_PRINT("Error while calling query callback");
	}
}

Error HealthKit::query_health_data(int start_date, int end_date, String data_type /*, Callable* callback*/) {
	if (!is_available()) {
		NSLog(@"HealthKit is not available");
		return ERR_UNAVAILABLE;
	}

	NSDate* start_date_nsdate = create_date_from_unix_timestamp(start_date);
	NSDate* end_date_nsdate = create_date_from_unix_timestamp(end_date);

	NSString* data_type_nsstr = [[NSString alloc] initWithUTF8String:data_type.utf8().get_data()];

	HKQuantityType* quantity_type = [HKQuantityType quantityTypeForIdentifier:data_type_nsstr];

	NSPredicate* predicate = [HKQuery predicateForSamplesWithStartDate:start_date_nsdate endDate:end_date_nsdate options:HKQueryOptionNone];

	HKStatisticsQuery* query = [[HKStatisticsQuery alloc] initWithQuantityType:quantity_type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery* query, HKStatistics* result, NSError* error) {
		if (error) {
			NSLog(@"Error while querying health data: %@", error);
			//call_query_callback(callback, -1);
			return;
		}

		HKQuantity* quantity = [result sumQuantity];
		double value = [quantity doubleValueForUnit:[HKUnit countUnit]];

		// Return result
		//call_query_callback(callback, value);
		NSLog(@"HealthKit query result: %f", value);
	}];

	[healthStore executeQuery:query];

	return OK;
}
#endif
