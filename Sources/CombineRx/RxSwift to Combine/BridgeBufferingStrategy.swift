//
//  BridgeBufferingStrategy.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Combine

public enum BridgeBufferingStrategy {
    case error
    case dropNewest
    case dropOldest
}

extension BridgeBufferingStrategy {

    var strategy: Publishers.BufferingStrategy<BridgeFailure> {
        switch self {
        case .error:        return .customError { .bufferOverflow }
        case .dropNewest:   return .dropNewest
        case .dropOldest:   return .dropOldest
        }
    }
}
