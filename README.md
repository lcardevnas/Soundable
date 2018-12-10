Overview
==============

[![Pod Version](http://img.shields.io/cocoapods/v/Soundable.svg?style=flat)](https://github.com/ThXou/Soundable)
[![Pod Platform](http://img.shields.io/cocoapods/p/Soundable.svg?style=flat)](https://github.com/ThXou/Soundable)
[![Pod License](http://img.shields.io/cocoapods/l/Soundable.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

Soundable is a tiny library that uses `AVFoundation` to manage the playing of sounds in iOS applications in a simple and easy way. You can play single audios, in sequence and in parallel, all is handled by the Soundable library and all they have completion closures when playing finishes.

TO-DO
==============

* Support `AVAudioSession` to set the category and manage audio interruptions.


Requirements
==============

* iOS 9.0+
* Xcode 10.0+
* Swift 4.2+


Install
==============

### Cocoapods

Add this line to your podfile:

```ruby
pod 'Soundable'
```

Setup
==============

Import `Soundable` in your source file:

```swift
import Soundable
```

Playing sounds
==============

### Single sounds

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

### Multiple sounds

#### Playing in parallel

To play audios in parallel your only have to worry on call the `play` function in all the audios you want to play in parallel, all the completion closures will be called when the audio finished playing.

#### Playing in sequence

`Soundable` supports the playing of audios in sequence, and as for a single sound, you have multitple ways to play audios in sequence. The first one is the best (IMO):

```swift
let sound1 = Sound(fileName: "guitar-chord.wav")
let sound2 = Sound(fileName: "rain.mp3")
let sound3 = Sound(fileName: "water-stream.wav")

let sounds = [sound1, sound2, sound3]
sounds.play()
```

Can you play and array of `Sound` objects?. Yes. This is thanks to a simple `Sequence` extension packed with the library that only accepts `Sound` objects to play.

The second one is using the `Soundable` class functions, again:

```swift
Soundable.play(sounds: [sound1, sound2, sound3])
```