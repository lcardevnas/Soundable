//
//  SoundCell.swift
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
