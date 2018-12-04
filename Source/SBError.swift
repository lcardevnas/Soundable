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
            return NSLocalizedString("wrong_url", comment: "Player cannot play a sound at this url")
        }
    }
}
