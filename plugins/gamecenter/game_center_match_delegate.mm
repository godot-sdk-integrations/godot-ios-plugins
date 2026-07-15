/*************************************************************************/
/*  game_center_match_delegate.mm                                        */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2025 mime29 (Game Center matchmaking)                   */
/*                                                                       */
/* Implements GKMatchmakerViewControllerDelegate + GKMatchDelegate.      */
/* All events go through GameCenter's pending_events queue.              */
/*************************************************************************/

#import "game_center_match_delegate.h"
#import "game_center.h"

@implementation GodotGameCenterMatchDelegate

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
	[viewController dismissViewControllerAnimated:YES completion:nil];
	Dictionary ret;
	ret["type"] = "match_cancelled";
	GameCenter::get_singleton()->add_pending_event(ret);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
	[viewController dismissViewControllerAnimated:YES completion:nil];
	Dictionary ret;
	ret["type"] = "match_error";
	ret["error_code"] = (int64_t)error.code;
	ret["error_description"] = [error.localizedDescription UTF8String];
	GameCenter::get_singleton()->add_pending_event(ret);
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match {
	[viewController dismissViewControllerAnimated:YES completion:nil];
	self.currentMatch = match;
	match.delegate = self;

	Array players;
	for (GKPlayer *player in match.players) {
		Dictionary p;
		p["display_name"] = [player.displayName UTF8String];
		p["alias"] = [player.alias UTF8String];
		if (@available(iOS 13, *)) {
			p["player_id"] = [player.teamPlayerID UTF8String];
		} else {
			p["player_id"] = [player.playerID UTF8String];
		}
		players.push_back(p);
	}

	Dictionary ret;
	ret["type"] = "match_found";
	ret["players"] = players;
	ret["expected_player_count"] = (int64_t)match.expectedPlayerCount;
	GameCenter::get_singleton()->add_pending_event(ret);
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromRemotePlayer:(GKPlayer *)player {
	NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!str) return;
	Dictionary ret;
	ret["type"] = "match_data_received";
	ret["data"] = [str UTF8String];
	if (@available(iOS 13, *)) { ret["player_id"] = [player.teamPlayerID UTF8String]; }
	else { ret["player_id"] = [player.playerID UTF8String]; }
	ret["display_name"] = [player.displayName UTF8String];
	GameCenter::get_singleton()->add_pending_event(ret);
}

- (void)match:(GKMatch *)match player:(GKPlayer *)player didChangeConnectionState:(GKPlayerConnectionState)state {
	Dictionary ret;
	ret["type"] = "match_player_state_changed";
	if (@available(iOS 13, *)) { ret["player_id"] = [player.teamPlayerID UTF8String]; }
	else { ret["player_id"] = [player.playerID UTF8String]; }
	ret["display_name"] = [player.displayName UTF8String];
	ret["state"] = (state == GKPlayerStateConnected) ? "connected" : "disconnected";
	GameCenter::get_singleton()->add_pending_event(ret);
}

- (BOOL)match:(GKMatch *)match shouldReinviteDisconnectedPlayer:(GKPlayer *)player {
	return NO;
}

// GKInviteEventListener — handle incoming match invitations.
// When a friend taps an invitation, iOS calls this method on the registered
// GKLocalPlayerListener. We present the GKMatchmakerViewController with the
// invite so the native UI handles the connection.
//
// On cold start, this can fire before authentication completes or before
// the root view controller is available. In that case, store the invite
// and present it later via presentPendingInviteIfNeeded.
- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController *root_controller = [self _findRootController];
		if (root_controller && GKLocalPlayer.localPlayer.isAuthenticated) {
			[self _presentInvite:invite onController:root_controller];
		} else {
			// App still starting up — save for later.
			self.pendingInvite = invite;
		}
	});
}

- (void)presentPendingInviteIfNeeded {
	if (!self.pendingInvite) return;
	GKInvite *invite = self.pendingInvite;
	self.pendingInvite = nil;
	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController *root_controller = [self _findRootController];
		if (root_controller) {
			[self _presentInvite:invite onController:root_controller];
		}
	});
}

- (void)_presentInvite:(GKInvite *)invite onController:(UIViewController *)root_controller {
	GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithInvite:invite];
	if (!mmvc) return;
	mmvc.matchmakerDelegate = self;
	[root_controller presentViewController:mmvc animated:YES completion:nil];
}

- (UIViewController *)_findRootController {
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
		root_controller = [[UIApplication sharedApplication] delegate].window.rootViewController;
	}
	return root_controller;
}

@end
