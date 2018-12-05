//
//  SoundsGroup.swift
//  Soundable
//
//  Created by Luis Cardenas on 05/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public typealias GroupSoundCompletion = (_ sound: Sound?) -> Void

fileprivate var associatedSoundGroupCompletionKey = "kAssociatedSoundGroupCompletionKey"

extension Notification.Name {
    static let QueuePlayerPlayedToEnd = Notification.Name(rawValue: "QueuePlayerPlayedToEnd")
}

class SoundsGroup {

    private var sounds: [Sound] = []
    private var pendingSoundsToPlay = 0
    
    var queuePlayer: AVQueuePlayer?
    
    
    // MARK: - Initializers
    init(sounds: [Sound]) {
        self.sounds = sounds
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        
        prepareSounds()
    }
    
    
    // MARK: - Helpers
    fileprivate func prepareSounds() {
        var items: [AVPlayerItem] = []
        for sound in sounds {
            if let url = sound.url {
                let urlString = url.absoluteString
                let newUrl = URL(fileURLWithPath: urlString)
                items.append(AVPlayerItem(url: newUrl))
            }
        }
        
        queuePlayer = AVQueuePlayer(items: items)
        pendingSoundsToPlay = items.count
    }
    
    
    // MARK: - Actions
    @objc func playerItemDidReachEnd() {
        pendingSoundsToPlay -= 1
        if pendingSoundsToPlay <= 0 {
            let completion = objc_getAssociatedObject(self, &associatedSoundGroupCompletionKey) as? SoundCompletion
            completion?(nil)
            
            objc_removeAssociatedObjects(self)
            print("played to end!")
        }
    }
    
    
    // MARK: -
    public func playNext(_ completion: GroupSoundCompletion) {
        
    }
    
    public func play(_ completion: SoundCompletion? = nil) {
        queuePlayer?.play()
        
        if let completion = completion {
            objc_setAssociatedObject(self, &associatedSoundGroupCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
