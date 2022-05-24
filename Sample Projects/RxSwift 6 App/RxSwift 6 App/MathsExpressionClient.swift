//
//  MathsExpressionClient.swift
//  RxSwift 6 App
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

// MARK: - Mocks
extension MathsExpressionClient {

    private static var dummyExpressions: [Expression] {
        [
            Expression(first: 1, second: 2, answer: 3, operation: "+", expression: "1 + 2"),
            Expression(first: 5, second: 5, answer: 10, operation: "+", expression: "5 + 5"),
            Expression(first: 8, second: 4, answer: 4, operation: "-", expression: "8 - 4"),
            Expression(first: 9, second: 5, answer: 45, operation: "*", expression: "9 * 5")
        ]
    }

    static var succeeding: Self {
        Self(
            randomExpression: {
                Just(dummyExpressions.randomElement())
                    .compactMap { $0 }
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        )
    }

    static var delayed: Self {
        Self(
            randomExpression: {
                Just(dummyExpressions.randomElement())
                    .compactMap { $0 }
                    .delay(for: .seconds(3), scheduler: DispatchQueue.main)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        )
    }

    static var failing: Self {
        Self(randomExpression: { Fail(error: Error.invalidURL).eraseToAnyPublisher() })
    }
}
