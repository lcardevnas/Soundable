//
//  Sound.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import AVFoundation

public typealias SoundCompletion = (_ error: Error?) -> Void

public class Sound {

    private var player: AVAudioPlayer?
    
    var name: String?
    var url: URL?
    var groupKey: String?
    var volume: Float = 1.0
    
    
    // MARK: - Initializers
    init(name: String, extension: String, bundle: Bundle = Bundle.main) {
        self.name = name
        
        if let path =  bundle.path(forResource: name, ofType: `extension`) {
            url = URL(string: path)
        }
    }
    
    init(fileName: String, bundle: Bundle = Bundle.main) {
        name = fileName
        
        let split = fileName.split(separator: ".")
        if split.count >= 2 {
            if let file = split.first, let fileExtension = split.last {
                if let path =  bundle.path(forResource: String(file), ofType: String(fileExtension)) {
                    url = URL(string: path)
                }
            }
        }
        
    }
    
    init(url: URL) {
        self.name = url.lastPathComponent
        self.url = url
        
    }
    
    
    // MARK: - Helpers
    fileprivate func createPlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: url!)
            player?.prepareToPlay()
            player?.volume = volume
        }
        catch let error {
            print("error creating AVAudioPlayer: \(error)")
        }
        
    }
    
    
    // MARK: - Handling sound
    public func play(groupKey: String = SoundableKey.DefaultGroupKey, loopsCount: Int = 0, completion: SoundCompletion? = nil) {
        self.groupKey = groupKey
        
        player?.numberOfLoops = loopsCount
        
        
    }
    
    public func pause() {
        player?.pause()
    }
    
    public func stop() {
        player?.stop()
    }
    
}


extension String {
    func tryToPlay(_ completion: SoundCompletion? = nil) {
        guard let url = URL(string: self) else {
            completion?(SBError.playingFailed(reason: .wrongUrl))
            return
        }
        
        let sound = Sound(url: url)
        sound.play { error in
            completion?(error)
        }
    }
}


extension URL {
    func tryToPlay(_ completion: SoundCompletion? = nil) {
        let sound = Sound(url: self)
        sound.play { error in
            completion?(error)
        }
    }
}
