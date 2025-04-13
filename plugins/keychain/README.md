# Godot iOS Keychain plugin

Requires `-ObjC` value added to the `Other Linker Flags` in Xcode project.

This plugin provides a simple wrapper around the iOS Keychain API for securely storing string values from GDScript.

---

## Example

```gdscript
var keychain = null

func _ready():
    if Engine.has_singleton("Keychain"):
        keychain = Engine.get_singleton("Keychain")
        
        keychain.set_string("username", "knight123")
        var username = keychain.get_string("username")
        print("Stored username: ", username)

        keychain.delete_key("username")
```

## Methods

`set_string(String key, String value)`
Stores the given string in the iOS Keychain under the specified key.

`get_string(String key) -> String`
Retrieves the string stored in the Keychain for the given key. Returns an empty string if not found.

`delete_key(String key)`
Removes the value associated with the given key from the Keychain.

## Notes

* Empty string is returned when key is missing.
* All data is stored securely using kSecClassGenericPassword.
* Keys are namespaced by the app's bundle identifier.