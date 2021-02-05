/*************************************************************************/
/*  godot_user_notification_delegate.m                                   */
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

#import "godot_user_notification_delegate.h"

@interface GodotUserNotificationDelegate ()

@end

@implementation GodotUserNotificationDelegate

static NSMutableArray<UserNotificationService *> *services = nil;

+ (NSArray<UserNotificationService *> *)services {
	return services;
}

+ (void)load {
	services = [NSMutableArray new];
}

+ (instancetype)shared {
	static GodotUserNotificationDelegate *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[GodotUserNotificationDelegate alloc] init];
	});
	return sharedInstance;
}

+ (void)addService:(UserNotificationService *)service {
	if (!services || !service) {
		return;
	}
	[services addObject:service];
}

// MARK: Delegate

// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
	for (UserNotificationService *service in services) {
		if (![service respondsToSelector:_cmd]) {
			continue;
		}

		[service userNotificationCenter:center willPresentNotification:notification withCompletionHandler:completionHandler];
	}
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
	for (UserNotificationService *service in services) {
		if (![service respondsToSelector:_cmd]) {
			continue;
		}

		[service userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
	}
}

// The method will be called on the delegate when the application is launched in response to the user's request to view in-app notification settings.
// Add UNAuthorizationOptionProvidesAppNotificationSettings as an option in requestAuthorizationWithOptions:completionHandler: to add a button to inline notification settings view and the notification settings view in Settings.
// The notification will be nil when opened from Settings.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(nullable UNNotification *)notification __API_AVAILABLE(macos(10.14), ios(12.0))__API_UNAVAILABLE(watchos, tvos) {
	for (UserNotificationService *service in services) {
		if (![service respondsToSelector:_cmd]) {
			continue;
		}

		[service userNotificationCenter:center openSettingsForNotification:notification];
	}
}

@end
