//
//  SoundsQueue.swift
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

/// The associated key for the completion closure.
fileprivate var associatedSoundsQueueCompletionKey = "kAssociatedSoundsQueueCompletionKey"

extension Notification.Name {
    static let QueuePlayerPlayedToEnd = Notification.Name(rawValue: "QueuePlayerPlayedToEnd")
}

/// An object to encapsulate playing queues functionality.
public class SoundsQueue : Playable {
    
    /// The queue player that will play the queued sounds.
    var queuePlayer: AVQueuePlayer?

    /// The group key where to play the sound queue.
    public var groupKey: String = SoundableKey.DefaultGroupKey
    
    /// The identifier for the sounds queue.
    public var identifier = ""
    
    /// The number of times the queue will be played.
    public var loopsCount = 0
    
    /// Not used in this object.
    public var url: URL?
    
    /// The array of `Sound` objects to be played.
    private var sounds: [Sound] = []
    
    /// Keeps track of the remaining number of sounds to play.
    private var pendingNumberOfSoundsToPlay = 0
    
    /// Keeps track of the times the sounds queue has been played.
    private var numberOfLoopsPlayed = 0
    
    /// The volume of the sound queue items.
    public var volume: Float {
        get { return queuePlayer?.volume ?? 1.0 }
        set { queuePlayer?.volume = volume }
    }
    
    /// Indicates if the sound queue is currently muted.
    public var isMuted: Bool {
        return queuePlayer?.volume == 0.0
    }
    
    
    // MARK: - Initializers
    private init() { }
    
    /// Created a `SoundsQueue` object with the given sounds.
    ///
    /// - parameter sounds: An array of `Sound` object to play.
    public init(sounds: [Sound]) {
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
    
    
    // MARK: - Actions
    /// Funcion called after each sound has finished playing.
    @objc fileprivate func playerItemDidReachEnd() {
        pendingNumberOfSoundsToPlay -= 1
        if pendingNumberOfSoundsToPlay <= 0 {
            if numberOfLoopsPlayed >= loopsCount {
                numberOfLoopsPlayed = 0
                unmute()
                
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
    /// Plays the current sounds queue.
    ///
    /// - parameter groupKey:     The group where the sounds queue will be played.
    /// - parameter loopsCount:   The number of times the sounds queue will be played before calling
    ///                             the completion closure.
    /// - parameter completion:   The completion closure called after the sounds queue has
    ///                             finished playing.
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
    
    /// Pauses the sounds queue.
    public func pause() {
        queuePlayer?.pause()
    }
    
    /// Stops the sounds queue.
    public func stop() {
        queuePlayer?.removeAllItems()
        unmute()
        
        Soundable.removePlayableItem(self)
    }
    
    /// Mutes the sounds queue.
    public func mute() {
        queuePlayer?.volume = 0.0
    }
    
    /// Unmutes the sounds queue.
    public func unmute() {
        if queuePlayer?.volume == 0.0 {
            queuePlayer?.volume = 1.0
        }
    }
}
