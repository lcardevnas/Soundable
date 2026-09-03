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

/// An object to encapsulate sound functionality.
@MainActor
public final class Sound: NSObject, Playable {
    
    /// The player that will play the sound.
    var player: AVAudioPlayer?

    /// The completion waiting for the current playback attempt.
    private var completion: SoundCompletion?

    /// The volume restored when the sound is unmuted.
    private var volumeBeforeMuting: Float = 1.0
    
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
        get { player?.numberOfLoops ?? 0 }
        set { player?.numberOfLoops = newValue }
    }
    
    /// The volume of the sound.
    public var volume: Float {
        get { player?.volume ?? 1.0 }
        set {
            player?.volume = newValue
            if newValue > 0 {
                volumeBeforeMuting = newValue
            }
        }
    }
    
    /// Indicates if the sound is currently playing.
    public var isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    /// Indicates if the sound is currently muted.
    public var isMuted: Bool {
        player?.volume == 0.0
    }
    
    
    // MARK: - Initializers
    private override init() { }
    
    /// Creates a `Sound` object for the given audio file.
    ///
    /// - parameter fileName:   The name of the file with its extension.
    /// - parameter bundle:     The bundle where the audio file is located. By default it
    ///                             uses the main bundle.
    public init(fileName: String, bundle: Bundle = Bundle.main) {
        super.init()

        identifier = UUID().uuidString
        
        let urlName = URL(fileURLWithPath: fileName)
        let file = urlName.deletingPathExtension().path
        let fileExtension = urlName.pathExtension
        
        name = fileName
        if let path =  bundle.path(forResource: file, ofType: fileExtension) {
            url = URL(fileURLWithPath: path)
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
        identifier = UUID().uuidString
        
        preparePlayer()
    }
    
    
    // MARK: - Private
    private func preparePlayer() {
        do {
            if let url = url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.delegate = self
                player?.volume = 1.0
            }
        } catch {
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
        
        self.completion = completion
        
        player?.numberOfLoops = loopsCount
        Soundable.addPlayableItem(self)

        guard player?.play() == true else {
            finish(with: SBError.playingFailed(reason: .playbackFailed))
            return
        }
    }
    
    /// Pauses the sound.
    public func pause() {
        player?.pause()
    }
    
    /// Stops the sound.
    public func stop() {
        completion = nil
        player?.stop()
        unmute()
        
        Soundable.removePlayableItem(self)
    }
    
    /// Mute the sound.
    public func mute() {
        if let currentVolume = player?.volume, currentVolume > 0 {
            volumeBeforeMuting = currentVolume
        }
        player?.volume = 0.0
    }
    
    /// Unmute the sound.
    public func unmute() {
        if player?.volume == 0.0 {
            player?.volume = volumeBeforeMuting
        }
    }

    private func finish(with error: Error?) {
        let pendingCompletion = completion
        completion = nil
        Soundable.removePlayableItem(self)
        unmute()
        pendingCompletion?(error)
    }
}


extension Sound: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.finish(with: flag ? nil : SBError.playingFailed(reason: .playbackFailed))
        }
    }
    
    nonisolated public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.finish(with: SBError.playingFailed(reason: .playbackFailed))
        }
    }
}


extension String {
    /// Tries to play the audio file by the fileName given in the `String`.
    ///
    /// - parameter completion:     The completion closure called after the sound has finished playing
    ///                                 or an error if any.
    @available(*, deprecated, message: "Create a Sound or use Soundable.play(fileName:) instead.")
    @MainActor
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
    @available(*, deprecated, message: "Create a Sound and call play() instead.")
    @MainActor
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(url: self)
        sound.play { error in
            completion?(error)
        }
    }
}
