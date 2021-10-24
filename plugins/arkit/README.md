# Godot iOS ARKit plugin

Uses Godot's `XRInterface`/`ARVRInterface` to handle iOS AR functionality.

## Example

https://github.com/BastiaanOlij/godot3_test_projects/tree/master/ARKit

## Methods

`set_light_estimation_is_enabled(bool flag)` - Sets a value responsible for usage of estimation of lighting conditions based on the camera image.  
`get_light_estimation_is_enabled()` - Returns a value responsible for usage of estimation of lighting conditions based on the camera image.  
`get_ambient_intensity()` - Returns a value used for intensity, in lumens, of ambient light throughout the scene.  
`get_ambient_color_temperature()` - Return a value used for color temperature of ambient light throughout the scene.  
`raycast(Vector2 screen_coords)` - Performs a raycast to search for real-world objects or AR anchors in the captured camera image.

## Properties

`light_estimation: bool` - Returns or sets a value responsible for usage of estimation of lighting conditions based on the camera image.

## Events reporting
