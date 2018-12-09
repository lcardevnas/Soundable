//
//  ViewController.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var mainSound: Sound!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        let sound1 = Sound(fileName: "nature.qwer.sdfg.hert.dbfd.mp3")
        let sound2 = Sound(fileName: "nature.mp3")
        let sound3 = Sound(fileName: "nature.mp3")
        
        let sounds = [sound1, sound2, sound3]
        sounds.play { error in
            
        }*/
    }


    @IBAction func playSound(_ sender: UIButton) {
        
        let sound1 = Sound(fileName: "nature.mp3")
        let sound2 = Sound(fileName: "rain-thunder.ogg")
        let sound3 = Sound(fileName: "guitar-chord.wav")
        
        let sounds = [sound1, sound2, sound3]
        sounds.play { error in
            print("finished playing")
        }
        
        /*
        mainSound = Sound(fileName: "nature-2.mp3")
        mainSound.play(loopsCount: 0) { error in
            print("sound 1 stopped")
            print("error sound 1: \(String(describing: error))")
            
            let sound2 = Sound(fileName: "guitar-chord.wav")
            sound2.play { error in
                print("sound 2 stopped")
                print("error sound 2: \(String(describing: error))")
            }
        }*/
    }
    
    @IBAction func stopAllSounds(_ sender: UIButton) {
        Soundable.stopAll()
    }
    
    @IBAction func stopSound1(_ sender: UIButton) {
        mainSound.stop()
    }
}

