/*************************************************************************/
/*  game_center_match_delegate.h                                         */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2025 mime29 (Game Center matchmaking)                   */
/*                                                                       */
/* Delegate for GKMatchmakerViewController and GKMatch (real-time).      */
/* Forwards events to GameCenter's pending_events queue.                 */
/*************************************************************************/

#pragma once

#import <GameKit/GameKit.h>

@class GKMatch;
@class GKPlayer;

@interface GodotGameCenterMatchDelegate : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLocalPlayerListener>

@property (nonatomic, strong) GKMatch *currentMatch;
@property (nonatomic, strong) GKInvite *pendingInvite;

/// Call after authentication to present any invite that arrived during cold start.
- (void)presentPendingInviteIfNeeded;

@end
