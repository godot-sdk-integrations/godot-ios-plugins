/*************************************************************************/
/*  godot_apn_delegate.mm                                                */
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

#import "godot_apn_delegate.h"

#include "apn.h"

#import "godot_user_notification_delegate.h"

#if VERSION_MAJOR >= 4
#import "platform/ios/godot_app_delegate.h"
#else
#import "platform/iphone/godot_app_delegate.h"
#endif

struct APNSInitializer {

	APNSInitializer() {
#if VERSION_MAJOR == 4 && VERSION_MINOR >= 4
		[GodotApplicationDelegate addService:[GodotAPNAppDelegate shared]];
#else
		[GodotApplicalitionDelegate addService:[GodotAPNAppDelegate shared]];
#endif
	}
};
static APNSInitializer initializer;

@interface GodotAPNAppDelegate ()

@end

@implementation GodotAPNAppDelegate

- (instancetype)init {
	self = [super init];

	if (self) {
		UNUserNotificationCenter.currentNotificationCenter.delegate = [GodotUserNotificationDelegate shared];
	}

	return self;
}

+ (instancetype)shared {
	static GodotAPNAppDelegate *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[GodotAPNAppDelegate alloc] init];
	});
	return sharedInstance;
}

- (void)registerPushNotificationsWithOptions:(UNAuthorizationOptions)options {
	[UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:options
																	  completionHandler:^(BOOL granted, NSError *_Nullable error) {
																		  NSLog(@"Push notifications access: %@, error: %@", @(granted), error);
																	  }];
	[UIApplication.sharedApplication registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	const char *data = (const char *)[deviceToken bytes];
	NSMutableString *token = [NSMutableString string];

	for (NSUInteger i = 0; i < [deviceToken length]; i++) {
		[token appendFormat:@"%02.2hhX", data[i]];
	}

	String device_token;
	device_token.parse_utf8([[token copy] UTF8String]);

	APNPlugin::get_singleton()->update_device_token(device_token);
}

@end
