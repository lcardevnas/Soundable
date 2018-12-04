//
//  Soundable.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public struct SoundableKey {
    public static let SoundsEnabled = "kSoundableSoundsEnabled"
    public static let DefaultGroupKey = "kSoundableDefaultGroupKey"
}

public class Soundable {
    
    private var playingSounds: [Sound] = []
    
    public static var enabled: Bool {
        get { return UserDefaults.standard.bool(forKey: SoundableKey.SoundsEnabled) }
        set {
            UserDefaults.standard.set(enabled, forKey: SoundableKey.SoundsEnabled)
            stopAll()
        }
    }
    
    
    // MARK: - Playing
    public class func play(name: String, extension: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0) {
        let sound = Sound(name: name, extension: `extension`)
        
    }
    
    public class func play(fileName: String, groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0) {
        
    }
    
    
    // MARK: - Handling sounds
    public class func addToQueue(_ sound: Sound) {
        
    }
    
    public class func stopAll() {
        
    }
    
    
}


extension Sequence where Iterator.Element == Sound
{
    func play() {
        for sound in self {
            print("sound: \(sound.name ?? "")")
        }
    }
}
