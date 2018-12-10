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

fileprivate var associatedCompletionKey = "kAssociatedCompletionKey"

public class Sound : NSObject, Playable {
    var player: AVAudioPlayer?
    
    public var identifier = ""
    public var groupKey: String = SoundableKey.DefaultGroupKey
    public var url: URL?
    
    public var loopsCount: Int = 0 {
        didSet {
            player?.numberOfLoops = loopsCount
        }
    }
    
    var name: String?
    var volume: Float = 1.0 {
        didSet {
            player?.volume = volume
        }
    }
    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    
    // MARK: - Initializers
    override private init() { }
    
    init(fileName: String, bundle: Bundle = Bundle.main) {
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
    
    init(url: URL) {
        super.init()
        
        self.url = url
        name = url.lastPathComponent
        identifier = url.absoluteString
        
        preparePlayer()
    }
    
    
    // MARK: - Helpers
    fileprivate func preparePlayer() {
        if identifier == "" {
            print("could not create an identifier for the sound")
            return
        }
        
        do {
            if let url = url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.delegate = self
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
            objc_setAssociatedObject(self, &associatedCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        player?.numberOfLoops = loopsCount
        player?.play()
        
        Soundable.addPlayableItem(self)
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func stop() {
        player?.stop()
        
        Soundable.removePlayableItem(self)
    }
}


extension Sound : AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let completion = objc_getAssociatedObject(self, &associatedCompletionKey) as? SoundCompletion
        completion?(nil)
        
        objc_setAssociatedObject(self, &associatedCompletionKey, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        Soundable.removePlayableItem(self)
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let completion = objc_getAssociatedObject(self, &associatedCompletionKey) as? SoundCompletion
        completion?(error)
        
        objc_setAssociatedObject(self, &associatedCompletionKey, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        
        Soundable.removePlayableItem(self)
    }
}


extension String {
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(fileName: self)
        sound.play { error in
            completion?(error)
        }
    }
}


extension URL {
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(url: self)
        sound.play { error in
            completion?(error)
        }
    }
}
