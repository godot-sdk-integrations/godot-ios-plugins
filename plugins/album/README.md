# Godot iOS Album plugin

This plugin enables you to publish images and videos that have been saved in the //user: storage space.

## Example

```
extends Control

var album_ios = null

func _ready():
    if Engine.has_singleton("AlbumIOS"):
        album_ios = Engine.get_singleton('AlbumIOS')

func publish_image_to_album(image_path: String):
    if album_ios != null:
        album_ios.publish_image_to_album(image_path)
        
func publish_video_to_album(video_path: String):
    if album_ios != null:
        album_ios.publish_video_to_album(video_path)

```