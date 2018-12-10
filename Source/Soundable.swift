//
//  Soundable.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public typealias SoundCompletion = (_ error: Error?) -> Void

public struct SoundableKey {
    public static let SoundEnabled      = "kSoundableSoundEnabled"
    public static let DefaultGroupKey   = "kSoundableDefaultGroupKey"
}

public class Soundable {
    
    private static var playingSounds: [String: Playable] = [:]
    
    public static var soundEnabled: Bool = {
        guard let value = UserDefaults.standard.string(forKey: SoundableKey.SoundEnabled) else {
            return true
        }
        return value == "true"
        }() { didSet {
            UserDefaults.standard.set(!soundEnabled ? "true" : "false", forKey: SoundableKey.SoundEnabled)
            if !soundEnabled {
                stopAll()
            }
        }
    }
    
    
    // MARK: - Playing sounds
    public class func play(fileName: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sound = Sound(fileName: fileName)
        sound.groupKey = groupKey
        sound.loopsCount = loopsCount
        play(sound, completion: completion)
    }
    
    public class func play(_ sound: Sound, completion: SoundCompletion? = nil) {
        playItem(sound, completion: completion)
    }
    
    
    // MARK: - Playing sounds queues
    public class func play(sounds: [Sound], groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let soundsQueue = SoundsQueue(sounds: sounds)
        soundsQueue.groupKey = groupKey
        soundsQueue.loopsCount = loopsCount
        playQueue(soundsQueue, completion: completion)
    }
    
    public class func playQueue(_ soundsQueue: SoundsQueue, completion: SoundCompletion? = nil) {
        playItem(soundsQueue, completion: completion)
    }
    
    
    // MARK: - Stop sounds
    public class func stop(_ sound: Sound) {
        sound.stop()
    }
    
    public class func stopQueue(_ soundsQueue: SoundsQueue) {
        soundsQueue.stop()
    }
    
    public class func stopItem(_ playableItem: Playable) {
        playableItem.stop()
    }
    
    public class func stopSound(with identifier: String? = nil) {
        for (_, playableItem) in playingSounds {
            if playableItem.identifier == identifier {
                stopItem(playableItem)
                return
            }
        }
    }
    
    public class func stopAll(for groupKey: String? = nil) {
        for (_, playableItem) in playingSounds {
            if let groupKey = groupKey, playableItem.groupKey != groupKey {
                continue
            }
            stopItem(playableItem)
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
    
    internal class func addPlayableItem(_ playableItem: Playable) {
        let identifier = playableItem.identifier
        if playingSounds[identifier] == nil {
            playingSounds[identifier] = playableItem
            
            print("[adding] playing sounds: \(playingSounds)")
        }
    }
    
    internal class func removePlayableItem(_ playableItem: Playable) {
        playingSounds.removeValue(forKey: playableItem.identifier)
        
        print("[removing] playing sounds: \(playingSounds)")
    }
}


extension Sequence where Iterator.Element == Sound {
    func play(groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        let sounds = self as! [Sound]
        if sounds.count == 0 {
            completion?(SBError.playingFailed(reason: .noSoundsToPlay))
            return
        }
        
        Soundable.play(sounds: sounds, groupKey: groupKey, loopsCount: loopsCount, completion: completion)
    }
}
