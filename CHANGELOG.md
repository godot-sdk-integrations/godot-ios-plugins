# Changelog

All notable changes to this project will be documented in this file.

## 2021-07-14

## Added

- `PhotoPicker` plugin allows to take a photo from camera or select it from photo library. [#19](https://github.com/godotengine/godot-ios-plugins/pull/19)

## 2021-07-13

## Fixes

- Replaced `copymem` usage with `memcpy`. [#20](https://github.com/godotengine/godot-ios-plugins/pull/20)

## 2021-05-16

## Added

- `InAppStore` plugin now returns a receipt for restored transactions. [#11](https://github.com/godotengine/godot-ios-plugins/pull/11)

## 2021-03-19

## Fixes

- `GameCenter` plugin now returns correct `player_id` value for iOS versions  between 13.0 and 13.5. [#4](https://github.com/godotengine/godot-ios-plugins/pull/4)

## 2021-02-05

## Added

- `badge_number` property, `set_badge_number`, `get_badge_number` methods to `PushNotifications` plugin.
  `GodotUserNotificationDelegate` and `UserNotificationService` can be used by as a single interface to process incoming notifications (both remote and local). [1e8c302](https://github.com/godotengine/godot-ios-plugins/commit/1e8c302b871e1e19ff907223e7e92b16884e32f7)

## 2021-02-03

## Added

- `PushNotifications` plugin that enables Apple Remote Notifications support for Godot projects. [b3e308a](https://github.com/godotengine/godot-ios-plugins/commit/b3e308a868274e29f62de92d22fd9ebdb703207c)

## 2021-01-31

## Fixes

- `InAppStore` plugin now handles additional `transactionState`s.

## 2021-01-27

Initial iOS plugins release.