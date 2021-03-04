//
//  BridgeFailure.swift
//  Copyright © 2020 Jack Stone. All rights reserved.
//

import Foundation

public enum BridgeFailure: Error {
    case upstreamError(_ error: Error)
    case bufferOverflow
}
