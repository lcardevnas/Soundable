//
//  SBError.swift
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
