# Godot iOS GameCenter plugin

## Methods

### Authentication

* `authenticate()` - Performs user authentication.
* `is_authenticated()` - Returns authentication state.

### Leaderboards

* `post_score(Dictionary score_dictionary)` - Reports a score data to `Game Center`. Generates new event with `post_score` type.

### Achievements

* `report_achievement(String identifier, double percent_complete, bool shows_completion_banner)` - Reports progress of achievement data to `Game Center`.
If `percent_complete` is [100.0, then the achievement is awarded](https://developer.apple.com/documentation/gamekit/gkachievement/percentcomplete?language=objc).
When `shows_completion_banner` is false, the native Game Center UI won't trigger so you can implement your own UI.
Docs: https://developer.apple.com/documentation/gamekit/rewarding-players-with-achievements?language=objc
Returns results via an event with the type `report_achievement`.
```gd
{
	"type": "report_achievement",
	"result": "ok",
}
```

* `reset_achievements()` - Resets all achievement progress for the local player. Returns results via an event with the type `reset_achievements`.
Docs: https://developer.apple.com/documentation/gamekit/gkachievement/resetachievements(completionhandler:)?language=objc
```gd
{
	"type": "reset_achievements",
	"result": "ok",
}
```

* `load_achievements()` - Loads previously submitted achievement progress for the local player from `Game Center`.
Returns results via an event with the type `load_achievements`.
```gd
{
	"type": "load_achievements",
	"result": "ok",
	"achievements": [
		{
			"identifier": String,
			"percent_complete": double,
			"completed": bool,
			"last_reported_date": String, # ISO 8601 date: "2025-12-02T16:59:31Z"
		},
		...
	],
}
```

* `load_achievement_descriptions()` - Downloads the achievement descriptions from `Game Center`.  This includes achievements that the player has not achieved.
Docs: https://developer.apple.com/documentation/gamekit/gkachievementdescription/loadachievementdescriptions(completionhandler:)?language=objc
Returns results in an event with the type `load_achievement_descriptions`.
```gd
{
	"type": "load_achievement_descriptions",
	"result": "ok",
	"descriptions": [
		{
			"identifier": String,
			"title": String,
			"unachieved_description": String,
			"achieved_description": String,
			"maximum_points": int64,
			"hidden": bool,
			"replayable": bool,
		},
		...
	],
}
```

### Native Game Center UI

* `show_game_center(Dictionary screen_dictionary)` - Displays Game Center information of your game. Generates new event with `show_game_center` type when information screen closes.
Docs: https://developer.apple.com/documentation/gamekit/gkgamecentercontrollerdelegate/gamecenterviewcontrollerdidfinish(_:)?language=objc
```gd
{
	"type": "show_game_center",
	"result": "ok",
}
```

* `request_identity_verification_signature()` -  Creates a signature for a third-party server to authenticate the local player.
Docs: https://developer.apple.com/documentation/gamekit/gklocalplayer/fetchitems(foridentityverificationsignature:)?language=objc
Returns results in an event with the type `identity_verification_signature`.
```gd
{
	"type": "identity_verification_signature",
	"result": "ok",
	"public_key_url": String,
	"signature": String, # base64 encoded
	"salt": String, # base64 encoded
	"timestamp": uint64,
	"player_id": String, # teamPlayerID
}
```

## Events reporting

`get_pending_event_count()` - Returns number of events pending from plugin to be processed.  
`pop_pending_event()` - Returns first unprocessed plugin event.  

An error event is in the following format:
```gd
{
	"type": String,
	"result": "error",
	"error_code": int64,
	"error_description": String,
}
```
