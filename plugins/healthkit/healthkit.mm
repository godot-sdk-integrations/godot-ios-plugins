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
	NSLog(@"Binding HealthKit methods...");

	ClassDB::bind_method(D_METHOD("is_available"), &HealthKit::is_available);
	ClassDB::bind_method(D_METHOD("create_health_store"), &HealthKit::create_health_store);
	ClassDB::bind_method(D_METHOD("execute_statistics_query", "quantity_type_str", "start_date", "end_date", "on_query_success"), &HealthKit::execute_statistics_query);

	NSLog(@"HealthKit methods bound.");
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
	NSLog(@"Creating HealthKit store...");

	if (!is_available()) {
		NSLog(@"HealthKit is not available.");
		return ERR_UNAVAILABLE;
	}

	if (healthStore != NULL) {
		NSLog(@"HealthKit store already created.");
		return OK;
	}

	healthStore = [[HKHealthStore alloc] init];
	NSLog(@"HealthKit store created.");

	return OK;
}

static NSDate* create_date_from_unix_timestamp(long timestamp) {
	return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

static void call_query_callback(const Callable* callable, double value) {
	NSLog(@"Calling query callback...");

	Callable::CallError err;
	Variant args[] = { value };
	const Variant* arg_ptrs[] = { &args[0] };
	Variant ret;
	callable->callp((const Variant**)arg_ptrs, 1, ret, err);
	if (err.error != Callable::CallError::CALL_OK) {
		ERR_PRINT("Error while calling query callback");
	}

	NSLog(@"Query callback called.");
}

Error HealthKit::execute_statistics_query(String quantity_type_str, int start_date, int end_date, Callable on_query_success) {
	NSLog(@"Executing HealthKit statistics query...");
	NSLog(@"Quantity type: %s", quantity_type_str.utf8().get_data());
	NSLog(@"Start date: %d", start_date);
	NSLog(@"End date: %d", end_date);

	if (!is_available()) {
		NSLog(@"HealthKit is not available");
		return ERR_UNAVAILABLE;
	}

	NSDate* start_date_nsdate = create_date_from_unix_timestamp(start_date);
	NSLog(@"Start date nsdate: %@", start_date_nsdate);

	NSDate* end_date_nsdate = create_date_from_unix_timestamp(end_date);
	NSLog(@"End date nsdate: %@", end_date_nsdate);

	NSString* quantity_type_nsstr = [[NSString alloc] initWithUTF8String:quantity_type_str.utf8().get_data()];
	HKQuantityType* quantity_type = [HKQuantityType quantityTypeForIdentifier:quantity_type_nsstr];
	NSLog(@"Quantity type: %@", quantity_type);

	NSPredicate* predicate = [HKQuery predicateForSamplesWithStartDate:start_date_nsdate endDate:end_date_nsdate options:HKQueryOptionNone];
	NSLog(@"Predicate: %@", predicate);

	HKStatisticsQuery* query = [[HKStatisticsQuery alloc] initWithQuantityType:quantity_type quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery* query, HKStatistics* result, NSError* error) {
		NSLog(@"HealthKit query completed.");

		if (error) {
			NSLog(@"Error while querying health data: %@", error);
			call_query_callback(&on_query_success, -1);
			return;
		}

		HKQuantity* quantity = [result sumQuantity];
		double value = [quantity doubleValueForUnit:[HKUnit countUnit]];
		NSLog(@"HealthKit query result: %@", quantity);

		// Return result
		call_query_callback(&on_query_success, value);
	}];
	NSLog(@"Query: %@", query);

	[healthStore executeQuery:query];
	NSLog(@"HealthKit query executed.");

	return OK;
}
