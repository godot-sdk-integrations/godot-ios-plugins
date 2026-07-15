/*************************************************************************/
/*  game_center.mm                                                       */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2025 mime29 (Game Center matchmaking + Godot 4.6 fixes) */
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
#import "game_center_match_delegate.h"

static GodotGameCenterMatchDelegate *matchDelegate = nil;

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
	ClassDB::bind_method(D_METHOD("award_achievement", "achievement"), &GameCenter::award_achievement);
	ClassDB::bind_method(D_METHOD("reset_achievements"), &GameCenter::reset_achievements);
	ClassDB::bind_method(D_METHOD("request_achievements"), &GameCenter::request_achievements);
	ClassDB::bind_method(D_METHOD("request_achievement_descriptions"), &GameCenter::request_achievement_descriptions);
	ClassDB::bind_method(D_METHOD("show_game_center"), &GameCenter::show_game_center);
	ClassDB::bind_method(D_METHOD("request_identity_verification_signature"), &GameCenter::request_identity_verification_signature);

	ClassDB::bind_method(D_METHOD("get_pending_event_count"), &GameCenter::get_pending_event_count);
	ClassDB::bind_method(D_METHOD("pop_pending_event"), &GameCenter::pop_pending_event);

	// Leaderboard entries.
	ClassDB::bind_method(D_METHOD("request_leaderboard_entries"), &GameCenter::request_leaderboard_entries);

	// Matchmaking.
	ClassDB::bind_method(D_METHOD("find_match"), &GameCenter::find_match);
	ClassDB::bind_method(D_METHOD("send_match_data"), &GameCenter::send_match_data);
	ClassDB::bind_method(D_METHOD("send_match_data_reliable"), &GameCenter::send_match_data_reliable);
	ClassDB::bind_method(D_METHOD("disconnect_match"), &GameCenter::disconnect_match);
	ClassDB::bind_method(D_METHOD("choose_best_host"), &GameCenter::choose_best_host);
};

Error GameCenter::authenticate() {
	//if this class isn't available, game center isn't implemented
	if ((NSClassFromString(@"GKLocalPlayer")) == nil) {
		return ERR_UNAVAILABLE;
	}

	GKLocalPlayer *player = [GKLocalPlayer localPlayer];
	ERR_FAIL_COND_V(![player respondsToSelector:@selector(authenticateHandler)], ERR_UNAVAILABLE);

	UIViewController *root_controller = nil;
	if (@available(iOS 13, *)) {
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *ws = (UIWindowScene *)scene;
				for (UIWindow *w in ws.windows) {
					if (w.rootViewController) {
						root_controller = w.rootViewController;
						if (w.isKeyWindow) break;
					}
				}
				if (root_controller) break;
			}
		}
	}
	if (!root_controller) {
		UIWindow *w = [[UIApplication sharedApplication] delegate].window;
		if (w) root_controller = w.rootViewController;
	}
	if (!root_controller) {
		for (UIWindow *w in [UIApplication sharedApplication].windows) {
			if (w.isKeyWindow && w.rootViewController) {
				root_controller = w.rootViewController;
				break;
			}
		}
	}
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

				// Present any invite that arrived during cold start.
				if (matchDelegate) {
					[matchDelegate presentPendingInviteIfNeeded];
				}
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

Error GameCenter::post_score(Dictionary p_score) {
	ERR_FAIL_COND_V(!p_score.has("score") || !p_score.has("category"), ERR_INVALID_PARAMETER);
	int64_t score = p_score["score"];
	String category = p_score["category"];
	int64_t context = 0;
	if (p_score.has("context")) {
		context = p_score["context"];
	}
	NSString *cat_str = [[NSString alloc] initWithUTF8String:category.utf8().get_data()];

	if (@available(iOS 14, *)) {
		[GKLeaderboard submitScore:score
		                   context:(NSUInteger)context
		                    player:[GKLocalPlayer localPlayer]
		      leaderboardIDs:@[cat_str]
		     completionHandler:^(NSError *error) {
			Dictionary ret;
			ret["type"] = "post_score";
			ret["result"] = error == nil ? "ok" : "error";
			if (error) {
				ret["error_code"] = (int64_t)error.code;
				ret["error_description"] = [error.localizedDescription UTF8String];
			}
			pending_events.push_back(ret);
		}];
	} else {
		GKScore *reporter = [[GKScore alloc] initWithLeaderboardIdentifier:cat_str];
		reporter.value = score;
		reporter.context = (uint64_t)context;
		[GKScore reportScores:@[ reporter ]
				withCompletionHandler:^(NSError *error) {
					Dictionary ret;
					ret["type"] = "post_score";
					ret["result"] = error == nil ? "ok" : "error";
					if (error) {
						ret["error_code"] = (int64_t)error.code;
						ret["error_description"] = [error.localizedDescription UTF8String];
					}
					pending_events.push_back(ret);
				}];
	}
	return OK;
};

Error GameCenter::award_achievement(Dictionary p_params) {
	ERR_FAIL_COND_V(!p_params.has("name") || !p_params.has("progress"), ERR_INVALID_PARAMETER);
	String name = p_params["name"];
	float progress = p_params["progress"];

	NSString *name_str = [[NSString alloc] initWithUTF8String:name.utf8().get_data()];
	GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:name_str];
	ERR_FAIL_COND_V(!achievement, FAILED);

	ERR_FAIL_COND_V([GKAchievement respondsToSelector:@selector(reportAchievements)], ERR_UNAVAILABLE);

	achievement.percentComplete = progress;
	achievement.showsCompletionBanner = NO;
	if (p_params.has("show_completion_banner")) {
		achievement.showsCompletionBanner = p_params["show_completion_banner"] ? YES : NO;
	}

	[GKAchievement reportAchievements:@[ achievement ]
				withCompletionHandler:^(NSError *error) {
					Dictionary ret;
					ret["type"] = "award_achievement";
					if (error == nil) {
						ret["result"] = "ok";
					} else {
						ret["result"] = "error";
						ret["error_code"] = (int64_t)error.code;
					};

					pending_events.push_back(ret);
				}];

	return OK;
};

void GameCenter::request_achievement_descriptions() {
	[GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
		Dictionary ret;
		ret["type"] = "achievement_descriptions";
		if (error == nil) {
			ret["result"] = "ok";
			GodotStringArray names;
			GodotStringArray titles;
			GodotStringArray unachieved_descriptions;
			GodotStringArray achieved_descriptions;
			GodotIntArray maximum_points;
			Array hidden;
			Array replayable;

			for (NSUInteger i = 0; i < [descriptions count]; i++) {

				GKAchievementDescription *description = [descriptions objectAtIndex:i];

				const char *str = [description.identifier UTF8String];
				names.push_back(String::utf8(str != NULL ? str : ""));

				str = [description.title UTF8String];
				titles.push_back(String::utf8(str != NULL ? str : ""));

				str = [description.unachievedDescription UTF8String];
				unachieved_descriptions.push_back(String::utf8(str != NULL ? str : ""));

				str = [description.achievedDescription UTF8String];
				achieved_descriptions.push_back(String::utf8(str != NULL ? str : ""));

				maximum_points.push_back(description.maximumPoints);

				hidden.push_back(description.hidden == YES);

				replayable.push_back(description.replayable == YES);
			}

			ret["names"] = names;
			ret["titles"] = titles;
			ret["unachieved_descriptions"] = unachieved_descriptions;
			ret["achieved_descriptions"] = achieved_descriptions;
			ret["maximum_points"] = maximum_points;
			ret["hidden"] = hidden;
			ret["replayable"] = replayable;

		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
		};

		pending_events.push_back(ret);
	}];
};

void GameCenter::request_achievements() {
	[GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
		Dictionary ret;
		ret["type"] = "achievements";
		if (error == nil) {
			ret["result"] = "ok";
			GodotStringArray names;
			GodotFloatArray percentages;

			for (NSUInteger i = 0; i < [achievements count]; i++) {

				GKAchievement *achievement = [achievements objectAtIndex:i];
				const char *str = [achievement.identifier UTF8String];
				names.push_back(String::utf8(str != NULL ? str : ""));

				percentages.push_back(achievement.percentComplete);
			}

			ret["names"] = names;
			ret["progress"] = percentages;

		} else {
			ret["result"] = "error";
			ret["error_code"] = (int64_t)error.code;
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
		};

		pending_events.push_back(ret);
	}];
};

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

	UIViewController *root_controller = nil;
	if (@available(iOS 13, *)) {
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *ws = (UIWindowScene *)scene;
				for (UIWindow *w in ws.windows) {
					if (w.rootViewController) {
						root_controller = w.rootViewController;
						if (w.isKeyWindow) break;
					}
				}
				if (root_controller) break;
			}
		}
	}
	if (!root_controller) {
		UIWindow *w = [[UIApplication sharedApplication] delegate].window;
		if (w) root_controller = w.rootViewController;
	}
	if (!root_controller) {
		for (UIWindow *w in [UIApplication sharedApplication].windows) {
			if (w.isKeyWindow && w.rootViewController) {
				root_controller = w.rootViewController;
				break;
			}
		}
	}
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

Error GameCenter::request_leaderboard_entries(Dictionary p_params) {
	ERR_FAIL_COND_V(!p_params.has("leaderboard_id"), ERR_INVALID_PARAMETER);
	ERR_FAIL_COND_V(!is_authenticated(), ERR_UNAUTHORIZED);

	String leaderboard_id = p_params["leaderboard_id"];
	int count = p_params.has("count") ? (int)p_params["count"] : 10;
	// scope: 0 = global, 1 = friends
	int scope = p_params.has("scope") ? (int)p_params["scope"] : 0;

	NSString *lid = [[NSString alloc] initWithUTF8String:leaderboard_id.utf8().get_data()];

	if (@available(iOS 14, *)) {
		[GKLeaderboard loadLeaderboardsWithIDs:@[lid]
			completionHandler:^(NSArray<GKLeaderboard *> *leaderboards, NSError *error) {
			if (error || leaderboards.count == 0) {
				Dictionary ret;
				ret["type"] = "leaderboard_entries";
				ret["result"] = "error";
				if (error) {
					ret["error_code"] = (int64_t)error.code;
					ret["error_description"] = [error.localizedDescription UTF8String];
				} else {
					ret["error_description"] = "Leaderboard not found";
				}
				pending_events.push_back(ret);
				return;
			}

			GKLeaderboard *lb = leaderboards[0];
			GKLeaderboardPlayerScope playerScope = (scope == 1)
				? GKLeaderboardPlayerScopeFriendsOnly
				: GKLeaderboardPlayerScopeGlobal;

			[lb loadEntriesForPlayerScope:playerScope
				timeScope:GKLeaderboardTimeScopeAllTime
				range:NSMakeRange(1, count)
				completionHandler:^(GKLeaderboardEntry *localEntry,
					NSArray<GKLeaderboardEntry *> *entries,
					NSInteger totalCount, NSError *loadError) {

				Dictionary ret;
				ret["type"] = "leaderboard_entries";
				if (loadError) {
					ret["result"] = "error";
					ret["error_code"] = (int64_t)loadError.code;
					ret["error_description"] = [loadError.localizedDescription UTF8String];
				} else {
					ret["result"] = "ok";
					ret["total_count"] = (int64_t)totalCount;

					Array entry_list;
					for (GKLeaderboardEntry *e in entries) {
						Dictionary ed;
						ed["rank"] = (int64_t)e.rank;
						ed["score"] = (int64_t)e.score;
						ed["context"] = (int64_t)e.context;
						ed["display_name"] = [e.player.displayName UTF8String];
						ed["alias"] = [e.player.alias UTF8String];
						if (@available(iOS 13, *)) {
							ed["player_id"] = [e.player.teamPlayerID UTF8String];
						} else {
							ed["player_id"] = [e.player.playerID UTF8String];
						}
						entry_list.push_back(ed);
					}
					ret["entries"] = entry_list;

					// Local player entry (may be outside the requested range).
					if (localEntry) {
						Dictionary le;
						le["rank"] = (int64_t)localEntry.rank;
						le["score"] = (int64_t)localEntry.score;
						le["context"] = (int64_t)localEntry.context;
						le["display_name"] = [localEntry.player.displayName UTF8String];
						ret["local_entry"] = le;
					}
				}
				pending_events.push_back(ret);
			}];
		}];
	} else {
		// iOS < 14 fallback — not supported.
		Dictionary ret;
		ret["type"] = "leaderboard_entries";
		ret["result"] = "error";
		ret["error_description"] = "loadEntries requires iOS 14+";
		pending_events.push_back(ret);
	}

	return OK;
}

void GameCenter::add_pending_event(const Dictionary &p_event) {
	// Many GameKit callbacks fire on background threads (Swift concurrency,
	// GCD completion handlers). Godot's data structures are NOT thread-safe,
	// so always dispatch to main thread before touching pending_events.
	if ([NSThread isMainThread]) {
		pending_events.push_back(p_event);
	} else {
		// Copy the dictionary so it survives the async dispatch.
		Dictionary copy = p_event;
		dispatch_async(dispatch_get_main_queue(), ^{
			pending_events.push_back(copy);
		});
	}
}

Error GameCenter::find_match(Dictionary p_params) {
	ERR_FAIL_COND_V(!is_authenticated(), ERR_UNAUTHORIZED);
	int min_players = p_params.has("min_players") ? (int)p_params["min_players"] : 2;
	int max_players = p_params.has("max_players") ? (int)p_params["max_players"] : 2;
	int player_group = p_params.has("player_group") ? (int)p_params["player_group"] : 0;

	GKMatchRequest *request = [[GKMatchRequest alloc] init];
	request.minPlayers = min_players;
	request.maxPlayers = max_players;
	if (player_group > 0) request.playerGroup = player_group;

	GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
	ERR_FAIL_COND_V(!mmvc, FAILED);
	if (!matchDelegate) matchDelegate = [[GodotGameCenterMatchDelegate alloc] init];
	mmvc.matchmakerDelegate = matchDelegate;

	UIViewController *root_controller = nil;
	if (@available(iOS 13, *)) {
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *ws = (UIWindowScene *)scene;
				for (UIWindow *w in ws.windows) {
					if (w.rootViewController) { root_controller = w.rootViewController; if (w.isKeyWindow) break; }
				}
				if (root_controller) break;
			}
		}
	}
	if (!root_controller) root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
	ERR_FAIL_COND_V(!root_controller, FAILED);
	[root_controller presentViewController:mmvc animated:YES completion:nil];
	return OK;
}

Error GameCenter::send_match_data(String p_data) {
	ERR_FAIL_COND_V(!matchDelegate || !matchDelegate.currentMatch, ERR_UNCONFIGURED);
	NSData *data = [[NSString stringWithUTF8String:p_data.utf8().get_data()] dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	[matchDelegate.currentMatch sendDataToAllPlayers:data withDataMode:GKMatchSendDataUnreliable error:&error];
	return error ? FAILED : OK;
}

Error GameCenter::send_match_data_reliable(String p_data) {
	ERR_FAIL_COND_V(!matchDelegate || !matchDelegate.currentMatch, ERR_UNCONFIGURED);
	NSData *data = [[NSString stringWithUTF8String:p_data.utf8().get_data()] dataUsingEncoding:NSUTF8StringEncoding];
	NSError *error = nil;
	[matchDelegate.currentMatch sendDataToAllPlayers:data withDataMode:GKMatchSendDataReliable error:&error];
	return error ? FAILED : OK;
}

void GameCenter::disconnect_match() {
	if (matchDelegate && matchDelegate.currentMatch) {
		[matchDelegate.currentMatch disconnect];
		matchDelegate.currentMatch = nil;
	}
}

void GameCenter::choose_best_host() {
	ERR_FAIL_COND(!matchDelegate || !matchDelegate.currentMatch);
	[matchDelegate.currentMatch chooseBestHostingPlayerWithCompletionHandler:^(GKPlayer *bestHost) {
		Dictionary ret;
		ret["type"] = "best_host";
		if (bestHost) {
			ret["display_name"] = [bestHost.displayName UTF8String];
			if (@available(iOS 13, *)) { ret["player_id"] = [bestHost.teamPlayerID UTF8String]; }
			else { ret["player_id"] = [bestHost.playerID UTF8String]; }
			ret["is_local"] = [bestHost isEqual:[GKLocalPlayer localPlayer]] ? true : false;
		} else {
			ret["player_id"] = "";
			ret["is_local"] = true;
		}
		GameCenter::get_singleton()->add_pending_event(ret);
	}];
}

GameCenter::GameCenter() {
	ERR_FAIL_COND(instance != NULL);
	instance = this;
	authenticated = false;

	gameCenterDelegate = [[GodotGameCenterDelegate alloc] init];

	// Create and register the match delegate early so it can receive
	// invitations that arrive during cold start (before auth completes).
	// The invite handler stores the invite if auth isn't ready yet.
	if (!matchDelegate) {
		matchDelegate = [[GodotGameCenterMatchDelegate alloc] init];
	}
	[GKLocalPlayer.localPlayer registerListener:matchDelegate];
};

GameCenter::~GameCenter() {
	if (gameCenterDelegate) {
		gameCenterDelegate = nil;
	}
}
