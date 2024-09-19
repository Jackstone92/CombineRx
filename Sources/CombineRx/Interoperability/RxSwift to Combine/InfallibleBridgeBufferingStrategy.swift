//
//  InfallibleBridgeBufferingStrategy.swift
//  Copyright © 2022 Jack Stone. All rights reserved.
//

import Combine

public enum InfallibleBridgeBufferingStrategy {
    case dropNewest
    case dropOldest
}

extension InfallibleBridgeBufferingStrategy {

    var strategy: Publishers.BufferingStrategy<Never> {
        switch self {
        case .dropNewest:   return .dropNewest
        case .dropOldest:   return .dropOldest
        }
    }
}
