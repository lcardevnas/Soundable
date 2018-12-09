//
//  SoundsQueue.swift
//  Soundable
//
//  Created by Luis Cardenas on 05/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public typealias SoundQueueCompletion = (_ sound: Sound?) -> Void

fileprivate var associatedSoundsQueueCompletionKey = "kAssociatedSoundsQueueCompletionKey"

extension Notification.Name {
    static let QueuePlayerPlayedToEnd = Notification.Name(rawValue: "QueuePlayerPlayedToEnd")
}

public class SoundsQueue : Playable {
    
    var queuePlayer: AVQueuePlayer?

    public var groupKey: String = SoundableKey.DefaultGroupKey
    var numberOfLoops = 0
    var identifier = ""
    
    private var sounds: [Sound] = []
    private var pendingNumberOfSoundsToPlay = 0
    private var numberOfLoopsPlayed = 0
    
    
    // MARK: - Initializers
    private init() { }
    
    init(sounds: [Sound]) {
        self.sounds = sounds
        self.identifier = uniqueString()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        
        createPlayer()
    }
    
    
    // MARK: - Actions
    @objc func playerItemDidReachEnd() {
        pendingNumberOfSoundsToPlay -= 1
        if pendingNumberOfSoundsToPlay <= 0 {
            if numberOfLoopsPlayed >= numberOfLoops {
                numberOfLoopsPlayed = 0
                
                let completion = objc_getAssociatedObject(self, &associatedSoundsQueueCompletionKey) as? SoundCompletion
                completion?(nil)
                
                objc_removeAssociatedObjects(self)
            }
            else {
                numberOfLoopsPlayed += 1
                createPlayer()
                queuePlayer?.play()
            }
        }
    }
    
    
    // MARK: - Private
    private func setupItems() -> [AVPlayerItem] {
        var items: [AVPlayerItem] = []
        for sound in sounds {
            if let url = sound.url {
                items.append(AVPlayerItem(url: url))
            }
        }
        return items
    }
    
    private func createPlayer() {
        let items = setupItems()
        
        queuePlayer = AVQueuePlayer(items: items)
        pendingNumberOfSoundsToPlay = items.count
    }
    
    private func uniqueString() -> String {
        return String(UInt(bitPattern: ObjectIdentifier(self)))
    }
    
}


// MARK: - Playable
extension SoundsQueue {
    public func play(groupKey: String? = nil, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        self.groupKey = groupKey ?? SoundableKey.DefaultGroupKey
        self.numberOfLoops = loopsCount
        
        if let completion = completion {
            objc_setAssociatedObject(self, &associatedSoundsQueueCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        queuePlayer?.play()
        
        Soundable.playQueue(self, completion: completion)
    }
    
    public func pause() {
        queuePlayer?.pause()
    }
    
    public func stop() {
        Soundable.stopQueue(self)
    }
}
