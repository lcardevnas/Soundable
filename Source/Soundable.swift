//
//  Soundable.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public struct SoundableKey {
    public static let SoundsEnabled     = "kSoundableSoundsEnabled"
    public static let DefaultGroupKey   = "kSoundableDefaultGroupKey"
}

public class Soundable {
    
    private static var playingSounds: [String: Sound] = [:]
    private static var soundGroups: [SoundsGroup] = []
    
    public static var soundEnabled: Bool = {
        return UserDefaults.standard.bool(forKey: SoundableKey.SoundsEnabled)
        }() { didSet {
            UserDefaults.standard.set(!soundEnabled, forKey: SoundableKey.SoundsEnabled)
            if !soundEnabled {
                stopAll()
            }
        }
    }
    
    
    // MARK: - Playing
    public class func play(sounds: [Sound], completion: SoundCompletion? = nil) {
        let soundGroup = SoundsGroup(sounds: sounds)
        soundGroups.append(soundGroup)
        
        soundGroup.play { error in
            completion?(error)
        }
    }
    
    public class func play(name: String, extension: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sound = Sound(name: name, extension: `extension`)
        sound.groupKey = groupKey
        sound.player?.numberOfLoops = loopsCount
        play(sound, completion: completion)
    }
    
    public class func play(fileName: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sound = Sound(fileName: fileName)
        sound.groupKey = groupKey
        sound.player?.numberOfLoops = loopsCount
        play(sound, completion: completion)
    }
    
    public class func play(_ sound: Sound, completion: SoundCompletion? = nil) {
        if let urlString = sound.url?.absoluteString {
            playingSounds[urlString] = sound
        }
        
        print("playing sounds: \(playingSounds)")
        
        if !sound.isPlaying {
            sound.play { error in
                remove(sound)
                completion?(error)
            }
        }
    }
    
    
    // MARK: - Handling sounds
    public class func stop(_ sound: Sound) {
        if sound.isPlaying {
            sound.stop()
        }
        remove(sound)
    }
    
    public class func stopAll(for groupKey: String? = nil) {
        for (_, sound) in playingSounds {
            if let groupKey = groupKey, sound.groupKey != groupKey {
                continue
            }
            stop(sound)
        }
    }
    
    
    // MARK: - Private
    private class func remove(_ sound: Sound) {
        if let urlString = sound.url?.absoluteString {
            playingSounds.removeValue(forKey: urlString)
        }
        print("playing sounds: \(playingSounds)")
    }
    
}


extension Sequence where Iterator.Element == Sound {
    func play(_ completion: SoundCompletion? = nil) {
        Soundable.play(sounds: self as! [Sound], completion: completion)
    }
}
