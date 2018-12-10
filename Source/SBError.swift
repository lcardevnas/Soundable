//
//  SBError.swift
//  Soundable
//
//  Created by Luis Cardenas on 04/12/2018.
//  Copyright © 2018 ThXou. All rights reserved.
//

import Foundation

public enum SBError: Error {
    case playingFailed(reason: PlayingFailureReason)
    
    public enum PlayingFailureReason {
        case wrongUrl
        case noSoundsToPlay
        case audioDisabled
    }
}


// MARK: - Error Descriptions
extension SBError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .playingFailed(let reason):
            return reason.localizedDescription
        }
    }
}

extension SBError.PlayingFailureReason {
    var localizedDescription: String {
        switch self {
        case .wrongUrl:
            return NSLocalizedString("wrong_url", comment: "Player cannot play a sound with this url")
        case .noSoundsToPlay:
            return NSLocalizedString("no_sounds_to_play", comment: "The array does not contain any sound to play")
        case .audioDisabled:
            return NSLocalizedString("audio_disabled", comment: "The audio is disabled in Soundable. Set `Soundable.soundEnabled = true`")
        }
    }
}
