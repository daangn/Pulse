// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse
import Combine

final class JSONViewerViewModel: ObservableObject {
    let json: Any
    let error: NetworkLogger.DecodingError?
    let contentType: NetworkLogger.ContentType?
    
    @Published private(set) var renderedString: NSAttributedString
    
    private var collapsedPaths: Set<String> = []
    private let nodesByPath: [String: JSONContainerNode]
    
    init(json: Any, error: NetworkLogger.DecodingError? = nil, contentType: NetworkLogger.ContentType? = nil) {
        self.json = json
        self.error = error
        self.contentType = contentType
        self.nodesByPath = Self.collectNodes(from: json)
        self.renderedString = Self.render(json: json, error: error, collapsedPaths: [], nodesByPath: nodesByPath)
    }
    
    func toggleNode(_ node: JSONContainerNode) {
        guard let path = node.path else { return }
        
        if collapsedPaths.contains(path) {
            collapsedPaths.remove(path)
        } else {
            collapsedPaths.insert(path)
        }
        
        updateRendering()
    }
    
    func expandAll() {
        collapsedPaths.removeAll()
        updateRendering()
    }
    
    func collapseAll() {
        collapsedPaths = Set(nodesByPath.keys)
        updateRendering()
    }
    
    private func updateRendering() {
        renderedString = Self.render(json: json, error: error, collapsedPaths: collapsedPaths, nodesByPath: nodesByPath)
    }
    
    private static func render(json: Any, error: NetworkLogger.DecodingError?, collapsedPaths: Set<String>, nodesByPath: [String: JSONContainerNode]) -> NSAttributedString {
        TextRendererJSON(json: json, error: error, collapsedPaths: collapsedPaths, nodesByPath: nodesByPath).render()
    }
    
    private static func collectNodes(from json: Any) -> [String: JSONContainerNode] {
        var nodes: [String: JSONContainerNode] = [:]
        
        func traverse(_ value: Any, path: String) {
            switch value {
            case let object as [String: Any]:
                nodes[path] = JSONContainerNode(kind: .object, json: object, path: path)
                for (key, subValue) in object {
                    traverse(subValue, path: "\(path).\(key)")
                }
                
            case let array as [Any]:
                nodes[path] = JSONContainerNode(kind: .array, json: array, path: path)
                for (index, subValue) in array.enumerated() {
                    traverse(subValue, path: "\(path)[\(index)]")
                }
                
            default:
                break
            }
        }
        
        traverse(json, path: "$")
        return nodes
    }
}