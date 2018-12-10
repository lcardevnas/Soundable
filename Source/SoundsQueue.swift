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
    public var identifier = ""
    public var loopsCount = 0
    public var url: URL?
    
    private var sounds: [Sound] = []
    private var pendingNumberOfSoundsToPlay = 0
    private var numberOfLoopsPlayed = 0
    
    
    // MARK: - Initializers
    private init() { }
    
    init(sounds: [Sound]) {
        self.sounds = sounds.filter({ $0.player != nil })
        self.identifier = uniqueString()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                               object: nil)
        
        createPlayer()
    }
    
    deinit {
        print("deallocating queue")
    }
    
    
    // MARK: - Actions
    @objc func playerItemDidReachEnd(_ notification: Notification) {
        pendingNumberOfSoundsToPlay -= 1
        if pendingNumberOfSoundsToPlay <= 0 {
            if numberOfLoopsPlayed >= loopsCount {
                numberOfLoopsPlayed = 0
                
                let completion = objc_getAssociatedObject(self, &associatedSoundsQueueCompletionKey) as? SoundCompletion
                completion?(nil)
                
                objc_setAssociatedObject(self, &associatedSoundsQueueCompletionKey, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
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
        if !Soundable.soundEnabled {
            completion?(SBError.playingFailed(reason: .audioDisabled))
            return
        }
        
        self.groupKey = groupKey ?? SoundableKey.DefaultGroupKey
        self.loopsCount = loopsCount
        
        if let completion = completion {
            objc_setAssociatedObject(self, &associatedSoundsQueueCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        queuePlayer?.play()
        
        Soundable.addPlayableItem(self)
    }
    
    public func pause() {
        queuePlayer?.pause()
    }
    
    public func stop() {
        queuePlayer?.removeAllItems()
        
        Soundable.removePlayableItem(self)
    }
}
