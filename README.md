Overview
==============

[![Pod Version](http://img.shields.io/cocoapods/v/Soundable.svg?style=flat)](https://github.com/ThXou/Soundable)
[![Pod Platform](http://img.shields.io/cocoapods/p/Soundable.svg?style=flat)](https://github.com/ThXou/Soundable)
[![Pod License](http://img.shields.io/cocoapods/l/Soundable.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

Soundable is a tiny library that uses `AVFoundation` to manage the playing of sounds in iOS applications in a simple and easy way. You can play single audios, in sequence and in parallel, all is handled by the Soundable library and all they have completion closures when playing finishes.

- [Requirements](#requirements)
- [Install](#install)
- [Setup](#setup)
- [Playing Sounds](#playing-sounds)
	- [Single Sounds](#single-sounds)
	- [Multiple Sounds](#multiple-sounds)
- [Stop Sounds](#stop-sounds)
- [Looped Sounds](#looped-sounds)


## TO-DO

* Support `AVAudioSession` to set the category and manage audio interruptions.


## Requirements

* iOS 9.0+
* Xcode 10.0+
* Swift 4.2+


## Install

### Cocoapods

Add this line to your podfile:

```ruby
pod 'Soundable'
```

## Setup

Import `Soundable` in your source file:

```swift
import Soundable
```

## Playing Sounds

### Single Sounds

`Soundable` provides multiple ways to play a sound. The first one is by creating a `Sound` object:

```swift
let sound = Sound(fileName: "guitar-chord.wav")
sound.play()
```

This will play the `guitar-chord.wav` track located in the main bundle of the application. If you have multiple bundles in your application, use the `fileName:bundle:` function to create the sound. If you have an `URL` object instead, you can use:

```swift
let sound = Sound(url: url)
sound.play()
```

The second one is using the `Soundable` class functions:

```swift
Soundable.play(fileName: "guitar-chord.wav")
```
And the third is for the laziest people. Put the file name in a `String` object and just `tryToPlay`:

```swift
"guitar-chord.wav".tryToPlay()
```

This is possible due to a simple `String` category packed with the library that will try to play an audio file located in the application's main bundle with the specified name.

If you have an `URL` object and are lazzy too, you can use it like this also:

```swift
url.tryToPlay()
```

All these functions have their respective completion closures that passes an `Error` object if something wrong have happened in the process:

```swift
sound.play { error in
    if let error = error {
        print("error: \(error.localizedDescription)")
    }
}
```

### Multiple Sounds

#### Playing In Parallel

To play audios in parallel your only have to worry on call the `play` function in all the audios you want to play in parallel, all the completion closures will be called when the audio finished playing.

#### Playing In Sequence

`Soundable` supports the playing of audios in sequence, and as for a single sound, you have multitple ways to play audios in sequence. The first one is the best (IMO):

```swift
let sound1 = Sound(fileName: "guitar-chord.wav")
let sound2 = Sound(fileName: "rain.mp3")
let sound3 = Sound(fileName: "water-stream.wav")

let sounds = [sound1, sound2, sound3]
sounds.play()
```

Or:

```swift
[sound1, sound2, sound3].play()
```

Can you play and array of `Sound` objects?. Yes. This is thanks to a simple `Sequence` extension packed with the library that only accepts `Sound` objects to play.

The second one is using the `Soundable` class functions, again:

```swift
Soundable.play(sounds: [sound1, sound2, sound3])
```

And the third is using the `SoundsQueue` object to create a queue of sounds:

```swift
let soundsQueue = SoundsQueue(sounds: [sound1, sound2, sound3])
soundsQueue.play()
```

As for single sounds, you also have the completion closure after all the sound sequence have been played.

## Stop Sounds

To stop sounds and queues is as simple as play them. If you created the sound using the `Sound` object do it like this:

```swift
let sound = Sound(fileName: "guitar-chord.wav")
sound.play()
...
sound.stop()
```

You can stop a specific sound using the `Soundable` class functions:

```swift
Soundable.stop(sound)
```

You can stop all the sounds currently playing with `Soundable`, including sound queues:

```swift
Soundable.stopAll()
```

Or you can stop all the sounds in a specific group. I explain to you what is that thing of "Groups" in the next section.

> **Stop the sounds or sound queues does not trigger the completion closure.**


## Sound Groups

Sound groups is a feature that allows you to group sounds under the same string key, then you can stop all the sounds in that group and keep playing the rest.

By default all the sounds and sound queues are created under the `Soundable.DefaultGroupKey` key. In this way, you can group for example, game sounds under the "game_sounds" key and then stop only those sounds:

```swift
Soundable.stopAll(for: "game_sounds")
```

All the rest of the sounds keep playing until they reach the end of the track or queue.

You can set the group where a sound will belong to in the `groupKey` parameter of every `play` function. For example, when creating a `Sound` object:

```swift
let sound = Sound(fileName: "sprite-walk.wav")
sound.play(groupKey: "game_sounds") { error in
   // Handle error if any
}
```

## Looped Sounds

Play sounds and sound queues in loop by setting the `loopsCount` parameter in every `play` call, as with the `groupKey`:

```swift
let sound = Sound(fileName: "sprite-walk.wav")
sound.play(groupKey: "game_sounds", loopsCount: 2) { error in
   // Handle error if any
}
```

The sound or sound queue will play a total of `loopsCount + 1` times before it triggers the completion closure.

## Credits

The sounds in the code example has been downloaded from the FreeSound database ([https://freesound.org](https://freesound.org/)).