//
//  NetworkLogger+Request+PublicInit.swift.swift
//  Pulse
//
//  Created by elon on 1/18/24.
//  Copyright © 2024 kean. All rights reserved.
//

import Foundation

extension NetworkLogger.Request {
    public init(url: URL, headers: [String: String], httpMethod: String? = nil) {
        self.url = url
        self.headers = headers
        self.httpMethod = httpMethod
        self.timeout = 0
        self.options = []
    }
}

extension NetworkLogger.Response {
    public init(statusCode: Int?, headers: [String: String]?) {
        self.statusCode = statusCode
        self.headers = headers
    }
}
