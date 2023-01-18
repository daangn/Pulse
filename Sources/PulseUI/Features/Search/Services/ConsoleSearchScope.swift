// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import Foundation

enum ConsoleSearchScope: Equatable, Hashable, Codable, CaseIterable {
    case url
    case queryItems
    case originalRequestHeaders
    case currentRequestHeaders
    case requestBody
    case responseHeaders
    case responseBody

    static let allEligibleScopes = ConsoleSearchScope.allCases.filter { $0 != .originalRequestHeaders }

    var title: String {
        switch self {
        case .originalRequestHeaders: return "Request Headers"
        case .currentRequestHeaders: return "Request Headers"
        default: return fullTitle
        }
    }

    var fullTitle: String {
        switch self {
        case .url: return "URL"
        case .queryItems: return "Query Items"
        case .originalRequestHeaders: return "Original Request Headers"
        case .currentRequestHeaders: return "Current Request Headers"
        case .requestBody: return "Request Body"
        case .responseHeaders: return "Response Headers"
        case .responseBody: return "Response Body"
        }
    }
}
