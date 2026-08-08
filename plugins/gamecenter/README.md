# Godot iOS GameCenter plugin

## Methods

### Authorization

`authenticate()` - Performs user authentication.  
`is_authenticated()` - Returns authentication state.  

### GameCenter methods

`post_score(Dictionary score_dictionary)` - Reports a score data to iOS `GameCenter`. Generates new event with `post_score` type.  
`award_achievement(Dictionary achievent_dictionary)` - Reports progress of achievement data to iOS `GameCenter`. Generates new event with `award_achievement` type.  
`reset_achievements()` - Resets all achievement progress for the local player. Generates new event with `reset_achievements` type.  
`request_achievements()` - Loads previously submitted achievement progress for the local player from iOS `GameCenter`. Generates new event with `achievements` type.  
`request_achievement_descriptions()` - Downloads the achievement descriptions from iOS `GameCenter`. Generates new event with `achievement_descriptions` type.  
`show_game_center(Dictionary screen_dictionary)` - Displays Game Center information of your game. Generates new event with `show_game_center` type when information screen closes.  
`request_identity_verification_signature()` -  Creates a signature for a third-party server to authenticate the local player. Generates new event with `identity_verification_signature` type.  
`save_game_data(Dictionary save_dictionary)` -  Save data to iCloud. Generates new event with `save_game_data` type.  
`fetch_saved_games()` - Fetch saved games. Generates new event with `fetch_saved_games` type containing an array of `saved_games`. To load one of the games' data, call `load_data` and wait for the event with `saved_game_loaded` type.  
`delete_saved_games(String name)` - Delete saved games that match the specified name. Generates new event with `delete_saved_games` type.  
`resolve_conflicting_saved_games(Dictionary resolve_conflict_dictionary)` - Resolve conflicting saved games by passing an array of `saved_games` and the `data` that resolves the conflict. Call this if you receive an event of type `conflicting_saved_games`. Generates new event with `resolve_conflicting_saved_games` type.

## Properties

## Events reporting

`get_pending_event_count()` - Returns number of events pending from plugin to be processed.  
`pop_pending_event()` - Returns first unprocessed plugin event.  
