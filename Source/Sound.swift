//
//  Sound.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public typealias SoundCompletion = (_ error: Error?) -> Void

fileprivate var associatedCompletionKey = "kAssociatedCompletionKey"

public class Sound : NSObject, Playable {

    var player: AVAudioPlayer?
    
    public var groupKey: String = SoundableKey.DefaultGroupKey
    var name: String?
    var url: URL?
    var volume: Float = 1.0
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
    
    init(name: String, extension: String, bundle: Bundle = Bundle.main) {
        super.init()
        
        self.name = name
        if let path =  bundle.path(forResource: name, ofType: `extension`) {
            url = URL(fileURLWithPath: path)
        }
        preparePlayer()
    }
    
    init(fileName: String, bundle: Bundle = Bundle.main) {
        super.init()
        
        let urlName = URL(fileURLWithPath: fileName)
        let file = urlName.deletingPathExtension().lastPathComponent
        let fileExtension = urlName.pathExtension
        
        name = file
        if let path =  bundle.path(forResource: file, ofType: fileExtension) {
            url = URL(fileURLWithPath: path)
        }
        preparePlayer()
    }
    
    init(url: URL) {
        super.init()
        
        self.name = url.lastPathComponent
        self.url = url
        
        preparePlayer()
    }
    
    
    // MARK: - Helpers
    fileprivate func preparePlayer() {
        do {
            if let url = url {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.volume = volume
                player?.delegate = self
            } else {
                print("missing url")
            }
        }
        catch let error {
            print("error creating AVAudioPlayer: \(error)")
        }
    }
    
}


// MARK: - Playable
extension Sound {
    public func play(groupKey: String? = nil, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        self.groupKey = groupKey ?? SoundableKey.DefaultGroupKey
        
        if let completion = completion {
            objc_setAssociatedObject(self, &associatedCompletionKey, completion, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        
        player?.numberOfLoops = loopsCount
        player?.play()
        
        Soundable.play(self, completion: completion)
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func stop() {
        Soundable.stop(self)
    }
}


extension Sound : AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let completion = objc_getAssociatedObject(self, &associatedCompletionKey) as? SoundCompletion
        completion?(nil)
        
        objc_removeAssociatedObjects(self)
        player.delegate = nil
        
        Soundable.stop(self)
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let completion = objc_getAssociatedObject(self, &associatedCompletionKey) as? SoundCompletion
        completion?(error)
        
        objc_removeAssociatedObjects(self)
        player.delegate = nil
        
        Soundable.stop(self)
    }
}


extension String {
    public func tryToPlay(_ completion: SoundCompletion? = nil) {
        let url = URL(fileURLWithPath: self)
        
        let sound = Sound(url: url)
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
