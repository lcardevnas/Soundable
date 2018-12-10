//
//  ViewController.swift
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

import UIKit

struct CellIdentifier {
    static let SoundCell = "SoundCell"
}

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView?
    @IBOutlet weak var soundNameField: UITextField?
    @IBOutlet weak var enableSoundButton: UIButton?
    
    var sounds: [Sound] = []
    var selectedSounds: [Sound] = []
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    fileprivate func setup() {
        let sound1 = Sound(fileName: "guitar-chord.wav")
        let sound2 = Sound(fileName: "rain.mp3")
        let sound3 = Sound(fileName: "water-stream.wav")
        let sound4 = Sound(fileName: "rain-thunder.ogg") // Will not play this due to format 😈
        let sound5 = Sound(fileName: "nature.mp3")
        
        sounds = [sound1, sound2, sound3, sound4, sound5]
        
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        gesture.cancelsTouchesInView = false
        view.addGestureRecognizer(gesture)
        
        configureEnableButton()
    }


    // MARK: - Actions
    @IBAction func playSounds(_ sender: UIButton) {
        tableView?.isUserInteractionEnabled = false
        
        selectedSounds.play { error in
            if let error = error {
                print("error: \(error)")
            }
            self.tableView?.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func stopAllSounds(_ sender: UIButton) {
        Soundable.stopAll()
        
        tableView?.isUserInteractionEnabled = true
    }
    
    @IBAction func playSound(_ sender: UIButton) {
        guard let soundName = soundNameField?.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), soundName != "" else {
            return
        }
        
        soundName.tryToPlay { error in
            if let error = error {
                print("error: \(error)")
            }
        }
    }
    
    @IBAction func disableAudio(_ sender: UIButton) {
        Soundable.soundEnabled = !Soundable.soundEnabled
        
        configureEnableButton()
    }
    
    @objc func handleTap() {
        view.endEditing(true)
    }
    
    
    // MARK: - Helpers
    fileprivate func play(_ sound: Sound) {
        sound.play { error in
            if let error = error {
                print("error: \(error)")
            }
            print("finished playing: \(sound.name ?? "")")
        }
    }
    
    fileprivate func configureEnableButton() {
        enableSoundButton?.setTitle("\(Soundable.soundEnabled ? "Disable" : "Enable") Soundable audio", for: .normal)
    }
}


extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sound = sounds[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.SoundCell, for: indexPath) as! SoundCell
        cell.configureCell(with: sound, isSelected: selectedSounds.contains(sound), playTapped: {
            self.play(sound)
        }, pauseTapped: {
            sound.pause()
        })
        return cell
    }
}


extension ViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sound = sounds[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        
        if let index = selectedSounds.firstIndex(of: sound) {
            selectedSounds.remove(at: index)
            cell?.accessoryType = .none
        } else {
            selectedSounds.append(sound)
            cell?.accessoryType = .checkmark
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

