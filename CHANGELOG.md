# Soundable CHANGELOG

## 2.0.0

* Added Swift Package Manager support as the primary installation method.
* Migrated the library and example project to Swift 6 with complete concurrency checking.
* Raised the minimum deployment target to iOS 13.
* Isolated the public playback API and completion callbacks to the main actor.
* Fixed sound volume and loop setters, duplicate playback identifiers, queue replay, empty queues, queue cleanup, and unrelated AVPlayer notifications.
* Preserved interruption observation across multiple notifications and migrated the persisted sound-enabled value from a string to a Boolean.
* Deprecated the global `String.tryToPlay` and `URL.tryToPlay` conveniences.

## 1.1.0

* Added audio-session category configuration and interruption handling.

## 1.0.4

* Added functionality to mute/unmute sounds and sound queues.

## 1.0.3

* Code restructured to be more organized and compatible with Carthage.

## 1.0.2

* Changed access control keyword for the `SoundsQueue` object initializer.

## 1.0.1

* Changed access control keyword for the `Sound` object initializer.

## 1.0.0

* Initial release.
