/*************************************************************************/
/*  game_center.mm                                                       */
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

#include "game_center.h"

#import "game_center_delegate.h"

#if VERSION_MAJOR == 4
#if VERSION_MINOR >= 6
#import "drivers/apple_embedded/godot_app_delegate.h"
#import "drivers/apple_embedded/godot_view_controller.h"
#elif VERSION_MINOR >= 5
#import "drivers/apple_embedded/godot_app_delegate.h"
#import "drivers/apple_embedded/view_controller.h"
#else
#import "platform/ios/app_delegate.h"
#import "platform/ios/view_controller.h"
#endif
#else
#import "platform/iphone/app_delegate.h"
#import "platform/iphone/view_controller.h"
#endif

#import <GameKit/GameKit.h>

#if VERSION_MAJOR == 4
typedef PackedStringArray GodotStringArray;
typedef PackedInt32Array GodotIntArray;
typedef PackedFloat32Array GodotFloatArray;
#else
typedef PoolStringArray GodotStringArray;
typedef PoolIntArray GodotIntArray;
typedef PoolRealArray GodotFloatArray;
#endif

GameCenter *GameCenter::instance = NULL;
GodotGameCenterDelegate *gameCenterDelegate = nil;

void GameCenter::_bind_methods() {
	ClassDB::bind_method(D_METHOD("authenticate"), &GameCenter::authenticate);
	ClassDB::bind_method(D_METHOD("is_authenticated"), &GameCenter::is_authenticated);

	ClassDB::bind_method(D_METHOD("post_score"), &GameCenter::post_score);
	ClassDB::bind_method(D_METHOD("report_achievement", "identifier", "percent_complete", "shows_completion_banner"), &GameCenter::report_achievement);
	ClassDB::bind_method(D_METHOD("reset_achievements"), &GameCenter::reset_achievements);
	ClassDB::bind_method(D_METHOD("load_achievements"), &GameCenter::load_achievements);
	ClassDB::bind_method(D_METHOD("load_achievement_descriptions"), &GameCenter::load_achievement_descriptions);
	ClassDB::bind_method(D_METHOD("show_game_center"), &GameCenter::show_game_center);
	ClassDB::bind_method(D_METHOD("request_identity_verification_signature"), &GameCenter::request_identity_verification_signature);

	ClassDB::bind_method(D_METHOD("get_pending_event_count"), &GameCenter::get_pending_event_count);
	ClassDB::bind_method(D_METHOD("pop_pending_event"), &GameCenter::pop_pending_event);
};

// Authentication

Error GameCenter::authenticate() {
	//if this class isn't available, game center isn't implemented
	if ((NSClassFromString(@"GKLocalPlayer")) == nil) {
		return ERR_UNAVAILABLE;
	}

	GKLocalPlayer *player = [GKLocalPlayer localPlayer];
	ERR_FAIL_COND_V(![player respondsToSelector:@selector(authenticateHandler)], ERR_UNAVAILABLE);

	UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
	ERR_FAIL_COND_V(!root_controller, FAILED);

	// This handler is called several times.  First when the view needs to be shown, then again
	// after the view is cancelled or the user logs in.  Or if the user's already logged in, it's
	// called just once to confirm they're authenticated.  This is why no result needs to be specified
	// in the presentViewController phase. In this case, more calls to this function will follow.
	_weakify(root_controller);
	_weakify(player);
	player.authenticateHandler = (^(UIViewController *controller, NSError *error) {
		_strongify(root_controller);
		_strongify(player);

		if (controller) {
			[root_controller presentViewController:controller animated:YES completion:nil];
		} else {
			Dictionary ret;
			ret["type"] = "authentication";
			if (player.isAuthenticated) {
				ret["result"] = "ok";
				ret["alias"] = [player.alias UTF8String];
				ret["displayName"] = [player.displayName UTF8String];

				if (@available(iOS 13, *)) {
					ret["player_id"] = [player.teamPlayerID UTF8String];
				} else {
					ret["player_id"] = [player.playerID UTF8String];
				}

				GameCenter::get_singleton()->authenticated = true;
			} else {
				ret["result"] = "error";
				ret["error_code"] = (int64_t)error.code;
				ret["error_description"] = [error.localizedDescription UTF8String];
				GameCenter::get_singleton()->authenticated = false;
			};

			pending_events.push_back(ret);
		};
	});

	return OK;
};

bool GameCenter::is_authenticated() {
	return authenticated;
};

// Leaderboards

Error GameCenter::post_score(Dictionary p_score) {
	ERR_FAIL_COND_V(!p_score.has("score") || !p_score.has("category"), ERR_INVALID_PARAMETER);
	float score = p_score["score"];
	String category = p_score["category"];

	NSString *cat_str = [[NSString alloc] initWithUTF8String:category.utf8().get_data()];
	GKScore *reporter = [[GKScore alloc] initWithLeaderboardIdentifier:cat_str];
	reporter.value = score;

	ERR_FAIL_COND_V([GKScore respondsToSelector:@selector(reportScores)], ERR_UNAVAILABLE);

	[GKScore reportScores:@[ reporter ]
			withCompletionHandler:^(NSError *error) {
				Dictionary ret;
				ret["type"] = "post_score";
				if (error == nil) {
					ret["result"] = "ok";
				} else {
					ret["result"] = "error";
					ret["error_code"] = (int64_t)error.code;
					ret["error_description"] = [error.localizedDescription UTF8String];
				};

				pending_events.push_back(ret);
			}];

	return OK;
};

// Achievements

Error GameCenter::report_achievement(String identifier, double percent_complete, bool shows_completion_banner) {
	NSString *identifier_nsstring = [[NSString alloc] initWithUTF8String: identifier.utf8().get_data()];
	GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: identifier_nsstring];
	ERR_FAIL_COND_V(!achievement, FAILED);

	achievement.percentComplete = percent_complete;
	achievement.showsCompletionBanner = shows_completion_banner;

	[GKAchievement reportAchievements: @[ achievement ]
				withCompletionHandler: ^(NSError *error) {
					Dictionary ret;
					ret["type"] = "report_achievement";
					if (error == nil) {
						ret["result"] = "ok";
					} else {
						ret["result"] = "error";
						ret["error_code"] = (int64_t)error.code;
						ret["error_description"] = [error.localizedDescription UTF8String];
					}
					pending_events.push_back(ret);
				}];
	return OK;
}

void GameCenter::load_achievements() {
	[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray<GKAchievement *> *achievements, NSError *error) {
		Dictionary ret;
		ret["type"] = "load_achievements";
		NSISO8601DateFormatter *dateFormatter = [[NSISO8601DateFormatter alloc] init];
		if (error == nil) {
			ret["result"] = "ok";
			Array result_achievements;
			for (GKAchievement *achievement in achievements) {
				Dictionary achievement_dict;
				achievement_dict["identifier"] = String([achievement.identifier UTF8String] ?: "");
				achievement_dict["percent_complete"] = achievement.percentComplete;
				achievement_dict["completed"] = achievement.completed == YES;
				NSString *isoDateString = [dateFormatter stringFromDate:achievement.lastReportedDate];
				achievement_dict["last_reported_date"] = String([isoDateString UTF8String] ?: "");
				result_achievements.push_back(achievement_dict);
			}
			ret["achievements"] = result_achievements;
		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
			ret["error_description"] = [error.localizedDescription UTF8String];
		};

		pending_events.push_back(ret);
	}];
};

void GameCenter::load_achievement_descriptions() {
	[GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray<GKAchievementDescription *> *descriptions, NSError *error) {
		Dictionary ret;
		ret["type"] = "load_achievement_descriptions";
		if (error == nil) {
			ret["result"] = "ok";
			Array result_descriptions;
			for (GKAchievementDescription *description in descriptions) {
				Dictionary description_dict;
				description_dict["identifier"] = String([description.identifier UTF8String] ?: "");
				description_dict["title"] = String([description.title UTF8String] ?: "");
				description_dict["unachieved_description"] = String([description.unachievedDescription UTF8String] ?: "");
				description_dict["achieved_description"] = String([description.achievedDescription UTF8String] ?: "");
				description_dict["maximum_points"] = (int64_t)description.maximumPoints;
				description_dict["hidden"] = description.hidden == YES;
				description_dict["replayable"] = description.replayable == YES;
				result_descriptions.push_back(description_dict);
			}
			ret["descriptions"] = result_descriptions;
		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
			ret["error_description"] = [error.localizedDescription UTF8String];
		};

		pending_events.push_back(ret);
	}];
};

void GameCenter::reset_achievements() {
	[GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
		Dictionary ret;
		ret["type"] = "reset_achievements";
		if (error == nil) {
			ret["result"] = "ok";
		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
			ret["error_description"] = [error.localizedDescription UTF8String];
		};

		pending_events.push_back(ret);
	}];
};

// Native Game Center UI

Error GameCenter::show_game_center(Dictionary p_params) {
	ERR_FAIL_COND_V(!NSProtocolFromString(@"GKGameCenterControllerDelegate"), FAILED);

	GKGameCenterViewControllerState view_state = GKGameCenterViewControllerStateDefault;
	if (p_params.has("view")) {
		String view_name = p_params["view"];
		if (view_name == "default") {
			view_state = GKGameCenterViewControllerStateDefault;
		} else if (view_name == "leaderboards") {
			view_state = GKGameCenterViewControllerStateLeaderboards;
		} else if (view_name == "achievements") {
			view_state = GKGameCenterViewControllerStateAchievements;
		} else if (view_name == "challenges") {
			view_state = GKGameCenterViewControllerStateChallenges;
		} else {
			return ERR_INVALID_PARAMETER;
		}
	}

	GKGameCenterViewController *controller = [[GKGameCenterViewController alloc] init];
	ERR_FAIL_COND_V(!controller, FAILED);

	UIViewController *root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
	ERR_FAIL_COND_V(!root_controller, FAILED);

	controller.gameCenterDelegate = gameCenterDelegate;
	controller.viewState = view_state;
	if (view_state == GKGameCenterViewControllerStateLeaderboards) {
		controller.leaderboardIdentifier = nil;
		if (p_params.has("leaderboard_name")) {
			String name = p_params["leaderboard_name"];
			NSString *name_str = [[NSString alloc] initWithUTF8String:name.utf8().get_data()];
			controller.leaderboardIdentifier = name_str;
		}
	}

	[root_controller presentViewController:controller animated:YES completion:nil];

	return OK;
};

Error GameCenter::request_identity_verification_signature() {
	ERR_FAIL_COND_V(!is_authenticated(), ERR_UNAUTHORIZED);

	GKLocalPlayer *player = [GKLocalPlayer localPlayer];
	void (^verificationSignatureHandler)(NSURL *publicKeyUrl, NSData *signature, NSData *salt, uint64_t timestamp, NSError *error) = ^(NSURL *publicKeyUrl, NSData *signature, NSData *salt, uint64_t timestamp, NSError *error) {
		Dictionary ret;
		ret["type"] = "identity_verification_signature";
		if (error == nil) {
			ret["result"] = "ok";
			ret["public_key_url"] = [publicKeyUrl.absoluteString UTF8String];
			ret["signature"] = [[signature base64EncodedStringWithOptions:0] UTF8String];
			ret["salt"] = [[salt base64EncodedStringWithOptions:0] UTF8String];
			ret["timestamp"] = timestamp;
			if (@available(iOS 13.5, *)) {
				ret["player_id"] = [player.teamPlayerID UTF8String];
			} else {
				ret["player_id"] = [player.playerID UTF8String];
			}
		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
			ret["error_description"] = [error.localizedDescription UTF8String];
		};

		pending_events.push_back(ret);
	};

	if (@available(iOS 13.5, *)) {
		[player fetchItemsForIdentityVerificationSignature:verificationSignatureHandler];
	} else {
		[player generateIdentityVerificationSignatureWithCompletionHandler:verificationSignatureHandler];
	}

	return OK;
};

void GameCenter::game_center_closed() {
	Dictionary ret;
	ret["type"] = "show_game_center";
	ret["result"] = "ok";
	pending_events.push_back(ret);
}

int GameCenter::get_pending_event_count() {
	return pending_events.size();
};

Variant GameCenter::pop_pending_event() {
	Variant front = pending_events.front()->get();
	pending_events.pop_front();

	return front;
};

GameCenter *GameCenter::get_singleton() {
	return instance;
};

GameCenter::GameCenter() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;
	authenticated = false;

	gameCenterDelegate = [[GodotGameCenterDelegate alloc] init];
};

GameCenter::~GameCenter() {
	if (gameCenterDelegate) {
		gameCenterDelegate = nil;
	}
}
