//
//  Expression.swift
//  RxSwift 5 App
//
//  Created by Jack Stone on 24/05/2022.
//

import Foundation

struct Expression: Equatable, Codable {
    let first: Int
    let second: Int
    let answer: Int
    let operation: String
    let expression: String
}
