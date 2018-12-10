//
//  SoundCell.swift
//  Soundable
//
//  Created by Luis Cardenas on 10/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import UIKit

typealias PlayButtonClosure = () -> Void

class SoundCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var pauseButton: UIButton?
    
    var playTappedClosure: PlayButtonClosure?
    var pauseTappedClosure: PlayButtonClosure?

    
    func configureCell(with sound: Sound, isSelected: Bool, playTapped: @escaping PlayButtonClosure, pauseTapped: @escaping PlayButtonClosure) {
        playTappedClosure = playTapped
        pauseTappedClosure = pauseTapped
        
        titleLabel?.text = sound.name
        playButton?.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        pauseButton?.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        
        accessoryType = isSelected ? .checkmark : .none
    }
    
    @objc func playButtonTapped() {
        playTappedClosure?()
    }
    
    @objc func pauseButtonTapped() {
        pauseTappedClosure?()
    }

}
