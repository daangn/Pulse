//
//  LoggerStore+storeSimpleNetwork.swift
//  Pulse
//
//  Created by elon on 1/18/24.
//  Copyright © 2024 kean. All rights reserved.
//

import Foundation

// MARK: - LoggerStore (Storing Messages)

extension LoggerStore {
    public func storeSimpleNetwork(
        url: URL,
        headers: [String: String],
        httpMethod: String? = nil,
        requestJSONData: Data?,
        requestDate: Date?,
        statusCode: Int?,
        responseHeaders: [String: String]?,
        responseJSONData: Data?,
        error: Swift.Error?,
        label: String? = nil,
        taskDescription: String? = nil
    ) {
        let request: NetworkLogger.Request = .init(url: url, headers: headers, httpMethod: httpMethod)
        let endDate = Date()
        handle(.networkTaskCompleted(.init(
            taskId: UUID(),
            taskType: .dataTask,
            createdAt: Date(),
            originalRequest: request,
            currentRequest: request,
            response: .init(statusCode: statusCode, headers: responseHeaders),
            error: error.map(NetworkLogger.ResponseError.init),
            requestBody: requestJSONData,
            responseBody: responseJSONData,
            metrics: .init(taskInterval: .init(start: requestDate ?? endDate, end: endDate), redirectCount: 0, transactions: []),
            label: label,
            taskDescription: taskDescription
        )))
    }
}
