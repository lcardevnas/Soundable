//
//  Sound.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
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
    
    override public var description: String {
        return "groupKey: \(groupKey)"
    }
    
    deinit {
        print("deallocating sound")
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
