//
//  MathsExpressionClient.swift
//  RxSwift 5 App
//
//  Created by Jack Stone on 24/05/2022.
//

import Foundation
import Combine

// MARK: - Interface
struct MathsExpressionClient {

    enum Error: Swift.Error {
        case invalidURL
        case networkError(Swift.Error)
        case decodingError(Swift.Error)
    }

    let randomExpression: () -> AnyPublisher<Expression, Error>
}

// MARK: - Live
extension MathsExpressionClient {

    static func live(session: URLSession) -> Self {
        Self(
            randomExpression: {
                guard let endpoint = URL(string: "https://x-math.herokuapp.com/api/random") else {
                    return Fail(error: .invalidURL).eraseToAnyPublisher()
                }

                return session.dataTaskPublisher(for: endpoint)
                    .mapError { Error.networkError($0) }
                    .map(\.data)
                    .decode(type: Expression.self, decoder: JSONDecoder())
                    .mapError { Error.decodingError($0) }
                    .eraseToAnyPublisher()
            }
        )
    }
}
