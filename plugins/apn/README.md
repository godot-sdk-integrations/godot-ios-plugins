# Godot iOS Apple Push Notifications plugin

Requires `-ObjC` value added to the `Other Linker Flags` in Xcode project.

Example:

```
var _apn = null

func _apn_device(value):
	print("device string: " + value);

...

func _ready():
    if Engine.has_singleton("APN"):
        var _apn = Engine.get_singleton("APN");
        _apn.connect("device_address_changed", self, "_apn_device");

        _apn.register_push_notifications(_apn.PUSH_SOUND | _apn.PUSH_BADGE | _apn.PUSH_ALERT);		
```

## Enum

Type: `PushOptions`  
Values: `PUSH_ALERT`, `PUSH_BADGE`, `PUSH_SOUND`, `PUSH_SETTINGS`

## Methods

`register_push_notifications(PushOptions options)` - Registers device to receive remote notifications through Apple Push Notification service.  
`set_badge_number(int value)` - Sets the badge value of the app icon on the Home screen.  
`get_badge_number()` - Returns the badge value of the app icon on the Home screen.

## Properties

`badge_number: int` - The number represents the badge of the app icon on the Home screen.

## Signals

`device_address_changed(String token)` - Called whenever iOS device updates remote notification token value.
