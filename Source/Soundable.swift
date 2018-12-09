//
//  Soundable.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public struct SoundableKey {
    public static let SoundEnabled      = "kSoundableSoundEnabled"
    public static let DefaultGroupKey   = "kSoundableDefaultGroupKey"
}

public class Soundable {
    
    private static var playingSounds: [String: Sound] = [:]
    private static var playingQueues: [String: SoundsQueue] = [:]
    
    public static var soundEnabled: Bool = {
        return UserDefaults.standard.bool(forKey: SoundableKey.SoundEnabled)
        }() { didSet {
            UserDefaults.standard.set(!soundEnabled, forKey: SoundableKey.SoundEnabled)
            if !soundEnabled {
                stopAll()
            }
        }
    }
    
    
    // MARK: - Playing sounds
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
    
    
    // MARK: - Playing sounds queues
    public class func play(sounds: [Sound], completion: SoundCompletion? = nil) {
        let soundsQueue = SoundsQueue(sounds: sounds)
        playQueue(soundsQueue, completion: completion)
    }
    
    public class func playQueue(_ soundsQueue: SoundsQueue, completion: SoundCompletion? = nil) {
        playingQueues[soundsQueue.identifier] = soundsQueue
        
        print("playing queues: \(playingQueues)")
        
        soundsQueue.play { error in
            completion?(error)
        }
    }
    
    
    // MARK: - Stop sounds
    public class func stop(_ sound: Sound) {
        if sound.isPlaying {
            sound.player?.stop()
        }
        remove(sound)
    }
    
    public class func stopQueue(_ soundsQueue: SoundsQueue) {
        soundsQueue.queuePlayer?.removeAllItems()
        removeQueue(soundsQueue)
    }
    
    public class func stopAll(for groupKey: String? = nil) {
        for (_, sound) in playingSounds {
            if let groupKey = groupKey, sound.groupKey != groupKey {
                continue
            }
            stop(sound)
        }
        
        for (_, queue) in playingQueues {
            if let groupKey = groupKey, queue.groupKey != groupKey {
                continue
            }
            stopQueue(queue)
        }
    }
    
    
    // MARK: - Private
    private class func remove(_ sound: Sound) {
        if let urlString = sound.url?.absoluteString {
            playingSounds.removeValue(forKey: urlString)
        }
        print("playing sounds: \(playingSounds)")
    }
    
    private class func removeQueue(_ soundsQueue: SoundsQueue) {
        playingQueues.removeValue(forKey: soundsQueue.identifier)
        
        print("playing queues: \(playingQueues)")
    }
    
}


extension Sequence where Iterator.Element == Sound {
    func play(_ completion: SoundCompletion? = nil) {
        Soundable.play(sounds: self as! [Sound], completion: completion)
    }
}
