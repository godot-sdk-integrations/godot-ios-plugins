# Changelog

All notable changes to this project will be documented in this file.

## 2021-03-19

## Fixes

- `GameCenter` plugin now returns correct `player_id` value for iOS versions  between 13.0 and 13.5.

## 2021-02-05

## Added

- `badge_number` property, `set_badge_number`, `get_badge_number` methods to `PushNotifications` plugin.
- `GodotUserNotificationDelegate` and `UserNotificationService` can be used by as a single interface to process incoming notifications (both remote and local).

## 2021-02-03

## Added

- `PushNotifications` plugin that enables Apple Remote Notifications support for Godot projects.

## 2021-01-31

## Fixes

- `InAppStore` plugin now handles additional `transactionState`s.

## 2021-01-27

Initial iOS plugins release.