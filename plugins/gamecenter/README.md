# Godot iOS/tvOS GameCenter plugin

Game Center is available for exported iOS, iPadOS, and tvOS builds. The plugin
singleton is not available in the Godot editor.

## Methods

### Authentication

`authenticate()` authenticates the local player and presents the native Game
Center sign-in UI when needed.

`is_authenticated()` returns the current authentication state.

Authentication generates an `authentication` event:

```gdscript
{
    "type": "authentication",
    "result": "ok", # or "error"
    "alias": "Player",
    "display_name": "Player",
    "displayName": "Player", # kept for compatibility
    "player_id": "...",
}
```

### Scores and Leaderboards

`post_score(Dictionary score_dictionary)` reports a score. The dictionary must
contain `score` and `category`. It can also contain `context`.

```gdscript
GameCenter.post_score({
    "score": 12345,
    "category": "leaderboard_id",
    "context": 0,
})
```

This uses the modern `GKLeaderboard submitScore` API on iOS/tvOS 14 and newer,
and falls back to `GKScore` on older iOS versions. It generates a `post_score`
event with `result` set to `ok` or `error`.

`request_leaderboard_entries(Dictionary params)` loads leaderboard entries with
the modern GameKit leaderboard API. It requires `leaderboard_id` and accepts
optional `count` and `scope` values. `scope` is `0` for global and `1` for
friends.

```gdscript
GameCenter.request_leaderboard_entries({
    "leaderboard_id": "leaderboard_id",
    "count": 10,
    "scope": 0,
})
```

This generates a `leaderboard_entries` event:

```gdscript
{
    "type": "leaderboard_entries",
    "result": "ok",
    "total_count": 42,
    "entries": [
        {
            "rank": 1,
            "score": 12345,
            "context": 0,
            "display_name": "Player",
            "alias": "Player",
            "player_id": "...",
        },
    ],
    "local_entry": { ... },
}
```

### Achievements

`award_achievement(Dictionary achievement_dictionary)` reports achievement
progress. The dictionary must contain `name` and `progress`; it can contain
`show_completion_banner`.

`request_achievements()` loads local achievement progress.

`request_achievement_descriptions()` loads achievement metadata.

`reset_achievements()` resets all achievement progress for the local player.

These calls generate `award_achievement`, `achievements`,
`achievement_descriptions`, or `reset_achievements` events.

### Native Game Center UI

`show_game_center(Dictionary screen_dictionary)` presents the native Game
Center UI. The optional `view` value can be `default`, `leaderboards`,
`achievements`, or `challenges`. For leaderboards, `leaderboard_name` can be
used to open a specific leaderboard.

`request_identity_verification_signature()` requests a signature that can be
sent to a third-party server to verify the local Game Center player.

`request_review()` requests the App Store review prompt on iOS. It returns
`ERR_UNAVAILABLE` on tvOS.

### Matchmaking

`find_match(Dictionary params)` presents the native matchmaking UI and creates a
real-time `GKMatch`. Supported parameters are:

- `min_players`
- `max_players`
- `player_group`

`send_match_data(String data)` sends UTF-8 match data unreliably.

`send_match_data_reliable(String data)` sends UTF-8 match data reliably.

`disconnect_match()` disconnects the current match.

`choose_best_host()` asks GameKit to choose the best host player for the current
match.

Matchmaking generates these events:

- `match_found`: contains `players` and `expected_player_count`.
- `match_cancelled`: emitted when the native match UI is cancelled.
- `match_error`: contains `error_code` and `error_description`.
- `match_data_received`: contains `data`, `player_id`, and `display_name`.
- `match_player_state_changed`: contains `player_id`, `display_name`, and
  `state`.
- `best_host`: contains the selected host `player_id`, `display_name`, and
  `is_local`.

Incoming Game Center invitations are handled by the plugin. If an invitation is
accepted during cold start, it is kept until authentication and the root view
controller are ready, then the native matchmaker UI is presented.

## Pending Events

GameKit callbacks can arrive on background threads. The plugin queues all events
on the main thread before exposing them to Godot.

`get_pending_event_count()` returns the number of queued events.

`pop_pending_event()` returns and removes the first queued event.

Typical polling code:

```gdscript
func _process(_delta):
    while GameCenter.get_pending_event_count() > 0:
        var event = GameCenter.pop_pending_event()
        _handle_game_center_event(event)
```
