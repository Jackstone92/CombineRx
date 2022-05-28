//
//  InfallibleBridgeBufferingStrategy.swift
//  
//
//  Created by Jack Stone on 24/05/2022.
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
