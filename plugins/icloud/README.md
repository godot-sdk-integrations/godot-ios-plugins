# Godot iOS iCloud plugin

Plugin generates new event with `key_value_changed` type when values stored in the iCloud key-value store changes.  

## Methods

`remove_key(String key)` - Removes the value associated with the specified key from the iCloud key-value store.  
`set_key_values(Dictionary values)` - Sets multiple objects for the specified keys in the iCloud key-value store.  
`get_key_value(String key)` - Returns the object associated with the specified key stored in iCloud key-value store.  
`synchronize_key_values()` - Synchronizes in-memory keys and values for iCloud storage with those stored on disk.  
`get_all_key_values()` - Returns a dictionary containing all of the key-value pairs in the iCloud key-value store.  

## Properties

## Events reporting

`get_pending_event_count()` - Returns number of events pending from plugin to be processed.  
`pop_pending_event()` - Returns first unprocessed plugin event.  