//
//  NumberFactClient.swift
//  RxSwift 6 App
//
//  Created by Jack Stone on 20/09/2024.
//

import Combine
import CombineRx
import Foundation
import RxCocoa
import RxSwift

struct NumberFactClient {
    enum Error: Swift.Error {
        case invalidURL
        case networkError(Swift.Error)
        case decodingError
    }

    let fact: (_ number: Int) -> AnyPublisher<String, Error>
}

extension NumberFactClient {
    static func live(session: URLSession) -> Self {
        Self(
            fact: { number in
                guard let url = URL(string: "http://numbersapi.com/\(number)") else {
                    return Fail(error: .invalidURL).eraseToAnyPublisher()
                }

                return session.rx.data(request: URLRequest(url: url))
                    .asPublisher(withBufferSize: 1, andBridgeBufferingStrategy: .dropOldest)
                    .mapError { Error.networkError($0) }
                    .flatMap(decodeFact(from:))
                    .eraseToAnyPublisher()
            }
        )
    }

    private static func decodeFact(from data: Data) -> AnyPublisher<String, Error> {
        guard let fact = String(data: data, encoding: .utf8) else {
            return Fail<String, Error>(error: .decodingError)
                .eraseToAnyPublisher()
        }

        return Just(fact)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
