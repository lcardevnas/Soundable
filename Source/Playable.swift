//
//  Playable.swift
//  Soundable
//
//  Created by ThXou on 09/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import Foundation

public protocol Playable {
    var url: URL? { get set }
    var identifier: String { get set }
    var groupKey: String { get set }
    var loopsCount: Int { get set }
    
    func play(groupKey: String?, loopsCount: Int, completion: SoundCompletion?)
    func pause()
    func stop()
}
