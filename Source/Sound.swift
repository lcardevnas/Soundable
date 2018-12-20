//
//  Sound.swift
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
fileprivate var associatedSoundCompletionKey = "kAssociatedSoundCompletionKey"

/// An object to encapsulate sound functionality.
public class Sound : NSObject, Playable {
    
    /// The player that will play the sound.
    var player: AVAudioPlayer?
    
    /// The name of the sound (file name with extension).
    public var name: String?

    /// The group key where to play the sound.
    public var groupKey: String = SoundableKey.DefaultGroupKey
    
    /// The identifier for the sounds queue.
    public var identifier = ""
    
    /// The url where the audio file is located.
    public var url: URL?
    
    /// The number of times the sound will be played.
    public var loopsCount: Int {
        get { return player?.numberOfLoops ?? 0 }
        set { player?.numberOfLoops = loopsCount }
    }
    
    /// The volume of the sound.
    public var volume: Float {
        get { return player?.volume ?? 1.0 }
        set { player?.volume = volume }
    }
    
    /// Indicates if the sound is currently playing.
    public var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    /// Indicates if the sound is currently muted.
    public var isMuted: Bool {
        return player?.volume == 0.0
    }
    
    
    // MARK: - Initializers
    override private init() { }
    
    /// Creates a `Sound` object for the given audio file.
    ///
    /// - parameter fileName:   The name of the file with its extension.
    /// - parameter bundle:     The bundle where the audio file is located. By default it
    ///                             uses the main bundle.
    public init(fileName: String, bundle: Bundle = Bundle.main) {
        super.init()
        
        let urlName = URL(fileURLWithPath: fileName)
        let file = urlName.deletingPathExtension().lastPathComponent
        let fileExtension = urlName.pathExtension
        
        name = fileName
        if let path =  bundle.path(forResource: file, ofType: fileExtension) {
            url = URL(fileURLWithPath: path)
            identifier = url?.absoluteString ?? ""
        }
        
        preparePlayer()
    }
    
    /// Creates a `Sound` object for the given url.
    ///
    /// - parameter url:    The url of the audio file to be played.
    public init(url: URL) {
        super.init()
        
        self.url = url
        name = url.lastPathComponent
        identifier = url.absoluteString
        
        preparePlayer()
    }
    
    
    // MARK: - Private
    private func preparePlayer() {
        if identifier == "" {
            print("could not create an identifier for the sound")
            return
        }
        
        do {
            if let url = url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.delegate = self
                player?.volume = 1.0
            } else {
                print("missing audio url to play")
            }
        }
        catch let error {
            print("error creating player with provided url: \(error)")
        }
    }
    
}


// MARK: - Playable
extension Sound {
    // MARK: - Playing sounds
    /// Plays the current sound.
    ///
    /// - parameter groupKey:       The group where the sound will be played.
    /// - parameter loopsCount:     The number of times the sound will be played before calling
    ///                                 the completion closure.
    /// - parameter completion:     The completion closure called after the sound has finished playing.
    public func play(groupKey: String? = nil, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        if player == nil {
            completion?(SBError.playingFailed(reason: .wrongUrl))
            return
        }
        
        if !Soundable.soundEnabled {
            completion?(SBError.playingFailed(reason: .audioDisabled))
            return
        }
        
        self.groupKey = groupKey ?? SoundableKey.DefaultGroupKey
        
        if let completion = completion {
            objc_setAssociatedObject(self, &associatedSoundCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        player?.numberOfLoops = loopsCount
        player?.play()
        
        Soundable.addPlayableItem(self)
    }
    
    /// Pauses the sound.
    public func pause() {
        player?.pause()
    }
    
    /// Stops the sound.
    public func stop() {
        player?.stop()
        unmute()
        
        Soundable.removePlayableItem(self)
    }
    
    /// Mute the sound.
    public func mute() {
        player?.volume = 0.0
    }
    
    /// Unmute the sound.
    public func unmute() {
        if player?.volume == 0.0 {
            player?.volume = 1.0
        }
    }
}


extension Sound : AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let completion = objc_getAssociatedObject(self, &associatedSoundCompletionKey) as? SoundCompletion
        completion?(nil)
        
        objc_setAssociatedObject(self, &associatedSoundCompletionKey, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        Soundable.removePlayableItem(self)
        unmute()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let completion = objc_getAssociatedObject(self, &associatedSoundCompletionKey) as? SoundCompletion
        completion?(error)
        
        objc_setAssociatedObject(self, &associatedSoundCompletionKey, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        Soundable.removePlayableItem(self)
        unmute()
    }
}


extension String {
    /// Tries to play the audio file by the fileName given in the `String`.
    ///
    /// - parameter completion:     The completion closure called after the sound has finished playing
    ///                                 or an error if any.
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(fileName: self)
        sound.play { error in
            completion?(error)
        }
    }
}


extension URL {
    /// Tries to play the audio file by the url given.
    ///
    /// - parameter completion:     The completion closure called after the sound has finished playing
    ///                                 or an error if any.
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(url: self)
        sound.play { error in
            completion?(error)
        }
    }
}
