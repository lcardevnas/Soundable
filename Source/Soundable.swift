//
//  Soundable.swift
//
//  Copyright © 2018 Luis Cardenas. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AVFoundation

/// A closure called after playing a sound or sound queue.
public typealias SoundCompletion = (_ error: Error?) -> Void

/// Alias to keep compatibility with swift versions < 4.2.
public typealias SessionCategory = AVAudioSession.Category

/// Static keys used in the library.
public struct SoundableKey {
    public static let SoundEnabled      = "kSoundableSoundEnabled"
    public static let DefaultGroupKey   = "kSoundableDefaultGroupKey"
}

/// `Soundable` is a class that acts as a manager of all the playing sounds.
public class Soundable {
    
    /// An array of `Playable` objects to track the playing sounds and queues.
    private static var playingSounds: [String: Playable] = [:]
    
    /// The apps audio shared session.
    private static var audioSession = AVAudioSession.sharedInstance()
    
    /// The readonly category of the current audio session.
    public static var sessionCategory: SessionCategory {
        get { return audioSession.category }
    }
    
    /// Enables/disables the sounds played using `Soundable` functions.
    public static var soundEnabled: Bool = {
        guard let value = UserDefaults.standard.string(forKey: SoundableKey.SoundEnabled) else {
            return true
        }
        return value == "true"
        }() { didSet {
            UserDefaults.standard.set(soundEnabled ? "true" : "false", forKey: SoundableKey.SoundEnabled)
            if !soundEnabled {
                stopAll()
            }
        }
    }
    
    // MARK: - Audio Session
    /// Sets and activate a new category for the audio session.
    ///
    /// - parameter category:   The new category to set and activate for the audio session.
    public class func activateSession(category: SessionCategory, options: AVAudioSession.CategoryOptions = []) {
        if !audioSession.availableCategories.contains(category) {
            fatalError("error: The '\(category)' category is not available for this device")
        }
        
        do {
            if #available(iOS 10.0, *) {
                try audioSession.setCategory(category, mode: .default, options: options)
            } else {
                audioSession.perform(NSSelectorFromString("setCategory:withOptions:error:"), with: category, with: options)
            }
            try audioSession.setActive(true)
        }
        catch let error {
            print("error activating session with category \(category): \(error.localizedDescription)")
        }
    }
    
    /// Deactivates the current audio session.
    public class func deactivateSession() {
        do { try audioSession.setActive(false) }
        catch let error {
            print("error deactivating session \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - Playing sounds
    /// Plays the given audio file.
    ///
    /// - parameter fileName:       The name of the file with its extension.
    /// - parameter groupKey:       The group where the audio will be played.
    /// - parameter loopsCount:     The number of times the sound will be played before calling
    ///                                 the completion closure.
    /// - parameter completion:     The completion closure called after the audio has finished playing.
    public class func play(fileName: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sound = Sound(fileName: fileName)
        sound.groupKey = groupKey
        sound.loopsCount = loopsCount
        play(sound, completion: completion)
    }
    
    /// Plays the given sound.
    ///
    /// - parameter sound:      The sound object to be played.
    /// - parameter completion: The completion closure called after the audio has finished playing.
    public class func play(_ sound: Sound, completion: SoundCompletion? = nil) {
        playItem(sound, completion: completion)
    }
    
    
    // MARK: - Playing sounds queues
    /// Plays the given sounds in sequence.
    ///
    /// - parameter sounds:       An array of `Sound` objects to be played in sequence.
    /// - parameter groupKey:     The group where the sounds will be played.
    /// - parameter loopsCount:   The number of times the sounds will be played before calling
    ///                             the completion closure.
    /// - parameter completion:   The completion closure called after the sounds has finished playing.
    public class func play(sounds: [Sound], groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let soundsQueue = SoundsQueue(sounds: sounds)
        soundsQueue.groupKey = groupKey
        soundsQueue.loopsCount = loopsCount
        playQueue(soundsQueue, completion: completion)
    }
    
    /// Plays the given sound queue.
    ///
    /// - parameter soundsQueue:    The sound queue object to be played.
    /// - parameter completion:     The completion closure called after the sound queue has
    ///                                 finished playing.
    public class func playQueue(_ soundsQueue: SoundsQueue, completion: SoundCompletion? = nil) {
        playItem(soundsQueue, completion: completion)
    }
    
    
    // MARK: - Stop sounds
    /// Stops the given `Sound` object.
    public class func stop(_ sound: Sound) {
        sound.stop()
    }
    
    /// Stops the given `SoundsQueue` object.
    public class func stopQueue(_ soundsQueue: SoundsQueue) {
        soundsQueue.stop()
    }
    
    /// Stops a `Playable` item.
    public class func stopItem(_ playableItem: Playable) {
        playableItem.stop()
    }
    
    /// Stops a sound with the given identifier.
    ///
    /// - parameter identifier: The identifier of the item to stop.
    public class func stopSound(with identifier: String? = nil) {
        for (_, playableItem) in playingSounds {
            if playableItem.identifier == identifier {
                stopItem(playableItem)
                return
            }
        }
    }
    
    /// Stops all the sounds currently playing by the `Soundable` library. If the `groupKey`
    /// parameter is set, the function only stops the sounds grouped under the group key.
    ///
    /// - parameter groupKey: The group key whose sounds needs to stop.
    public class func stopAll(for groupKey: String? = nil) {
        usableItemInPlayingSounds(for: groupKey) { (playableItem) in
            stopItem(playableItem)
        }
    }
    
    
    // MARK: - Muting sounds
    /// Mute all the sounds or sound queues currently playing by the library. If the `groupKey`
    /// parameter is set, the function only mutes the sounds grouped under the group key.
    ///
    /// When a muted sound finishes playing the completion closure is called anyway.
    ///
    /// - parameter groupKey: The group key whose sounds needs to mute.
    public class func muteAll(for groupKey: String? = nil) {
        usableItemInPlayingSounds(for: groupKey) { (playableItem) in
            playableItem.mute()
        }
    }
    
    /// Unmute all the sounds or sound queues currently muted (aka volume equal to 0.0).
    /// If the `groupKey` parameter is set, the function only unmutes the sounds grouped under
    /// the group key.
    ///
    /// - parameter groupKey: The group key whose sounds needs to mute.
    public class func unmuteAll(for groupKey: String? = nil) {
        usableItemInPlayingSounds(for: groupKey) { (playableItem) in
            playableItem.unmute()
        }
    }
    
    
    // MARK: - Helpers
    fileprivate class func playItem(_ playableItem: Playable, completion: SoundCompletion? = nil) {
        if !Soundable.soundEnabled {
            completion?(SBError.playingFailed(reason: .audioDisabled))
            return
        }
        
        addPlayableItem(playableItem)
        
        playableItem.play(groupKey: playableItem.groupKey, loopsCount: playableItem.loopsCount) { error in
            removePlayableItem(playableItem)
            completion?(error)
        }
    }
    
    fileprivate class func usableItemInPlayingSounds(for groupKey: String? = nil, _ closure: ((_ playableItem: Playable) -> ())) {
        for (_, playableItem) in playingSounds {
            if let groupKey = groupKey, playableItem.groupKey != groupKey {
                continue
            }
            closure(playableItem)
        }
    }
    
    internal class func addPlayableItem(_ playableItem: Playable) {
        let identifier = playableItem.identifier
        if playingSounds[identifier] == nil {
            playingSounds[identifier] = playableItem
        }
    }
    
    internal class func removePlayableItem(_ playableItem: Playable) {
        playingSounds.removeValue(forKey: playableItem.identifier)
    }
}


extension Sequence where Iterator.Element == Sound {
    /// Plays the array of `Sound` objects.
    ///
    /// - parameter groupKey:     The group where the sounds will be played.
    /// - parameter loopsCount:   The number of times the sounds will be played before calling
    ///                             the completion closure.
    /// - parameter completion:   The completion closure called after the sounds has finished playing.
    public func play(groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sounds = self as! [Sound]
        if sounds.count == 0 {
            completion?(SBError.playingFailed(reason: .noSoundsToPlay))
            return
        }
        
        Soundable.play(sounds: sounds, groupKey: groupKey, loopsCount: loopsCount, completion: completion)
    }
}
