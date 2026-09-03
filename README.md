# Soundable

[![CocoaPods](https://img.shields.io/cocoapods/v/Soundable.svg?style=flat)](https://cocoapods.org/pods/Soundable)
[![Platform](https://img.shields.io/cocoapods/p/Soundable.svg?style=flat)](https://cocoapods.org/pods/Soundable)
[![License](https://img.shields.io/cocoapods/l/Soundable.svg?style=flat)](LICENSE)

Soundable is a small AVFoundation-based library for playing individual sounds or sound queues in iOS applications. It supports grouping, muting, looping, stopping, completion callbacks, audio-session configuration, and interruption observation.

## Requirements

- iOS 13 or later
- Swift 6.3 or later
- Xcode 26 or a compatible Swift 6.3 toolchain

Soundable's public playback API is isolated to `@MainActor`. Calls made from UI types normally require no additional work. Calls originating outside the main actor must explicitly switch to it:

```swift
Task { @MainActor in
    Soundable.play(fileName: "notification.wav")
}
```

## Installation

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies** and enter:

```text
https://github.com/ThXou/Soundable.git
```

Select version `2.0.0` or later, then add the `Soundable` product to your app target.

You can also add Soundable to a package manifest:

```swift
dependencies: [
    .package(url: "https://github.com/ThXou/Soundable.git", from: "2.0.0")
]
```

### CocoaPods

```ruby
pod 'Soundable', '~> 2.0'
```

### Carthage

```text
github "ThXou/Soundable" ~> 2.0
```

## Playing a sound

Create a `Sound` from a file in a bundle or from a URL:

```swift
import Soundable

let sound = Sound(fileName: "guitar-chord.wav")
sound.play { error in
    if let error {
        print("Playback failed: \(error.localizedDescription)")
    }
}
```

The static convenience API retains the sound for the duration of playback:

```swift
Soundable.play(fileName: "guitar-chord.wav")
```

The former `String.tryToPlay` and `URL.tryToPlay` conveniences remain available for source compatibility but are deprecated in Soundable 2.0.

## Playing a queue

Play an array or any other sequence of sounds in order:

```swift
let intro = Sound(fileName: "intro.wav")
let message = Sound(fileName: "message.wav")

[intro, message].play { error in
    if let error {
        print("Queue failed: \(error.localizedDescription)")
    }
}
```

An empty queue completes immediately with `SBError.playingFailed(reason: .noSoundsToPlay)`.

## Groups, loops, volume, and muting

```swift
let ambience = Sound(fileName: "rain.mp3")
ambience.volume = 0.4
ambience.play(groupKey: "ambience", loopsCount: -1)

Soundable.muteAll(for: "ambience")
Soundable.unmuteAll(for: "ambience")
Soundable.stopAll(for: "ambience")
```

`loopsCount` is the number of additional plays. Use `-1` for continuous looping. Muting remembers and restores the previous volume.

Calling `stop()` or a `Soundable.stop…` function intentionally does not invoke the pending completion callback.

## Enabling and disabling playback

```swift
Soundable.soundEnabled = false
```

Disabling playback stops all tracked sounds and queues. Later playback attempts complete with `.audioDisabled` until playback is enabled again.

## Audio session

```swift
import AVFoundation

Soundable.activateSession(category: .playback)
// Later, when appropriate:
Soundable.deactivateSession()
```

Audio-session configuration failures are logged and never terminate the host application.

## Interruptions

```swift
Soundable.observeInterruptions { type, userInfo in
    switch type {
    case .began:
        print("Interruption began")
    case .ended:
        print("Interruption ended")
    @unknown default:
        break
    }
}
```

The observer remains active for subsequent interruption notifications. Registering again replaces the callback without installing another observer.

## Migrating from 1.x

Soundable 2.0 raises the minimum deployment target from iOS 9 to iOS 13 and adopts Swift 6 main-actor isolation. Existing API names remain available, but code that calls Soundable from a background or nonisolated context must switch to the main actor. Persisted `soundEnabled` values are migrated automatically from the legacy string representation.

## License

Soundable is available under the MIT license. See [LICENSE](LICENSE).
