// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse

#if os(macOS)
import AppKit
#endif

package final class TextRendererJSON {
    // Input
    private let json: Any
    private var error: NetworkLogger.DecodingError?

    // Settings
    private let options: TextRenderer.Options
    private let helper: TextHelper
    private let spaces = 2

    // Temporary state (one-shot, doesn't reset)
    private var indentation = 0
    private var index = 0
    private var codingPath: [NetworkLogger.DecodingError.CodingKey] = []
    private var elements: [(NSRange, JSONElement, JSONContainerNode?)] = []
    private var errorRange: NSRange?
    private var string = ""
    private var collapsedPaths: Set<String> = []
    private var nodesByPath: [String: JSONContainerNode] = [:]

    package init(json: Any, error: NetworkLogger.DecodingError? = nil, options: TextRenderer.Options = .init(), collapsedPaths: Set<String> = [], nodesByPath: [String: JSONContainerNode] = [:]) {
        self.options = options
        self.helper = TextHelper()
        self.json = json
        self.error = error
        self.collapsedPaths = collapsedPaths
        self.nodesByPath = nodesByPath
    }

    package func render() -> NSAttributedString {
        render(json: json, path: "$", isFree: true)

        let output = NSMutableAttributedString(string: string, attributes: helper.attributes(role: .body2, style: .monospaced, color: color(for: .key)))
        for (range, element, node) in elements {
            output.addAttribute(.foregroundColor, value: color(for: element), range: range)
            if let node = node {
                output.addAttribute(.node, value: node, range: range)
#if os(macOS)
                if TextRendererJSON.makeErrorAttributes != nil {
                    output.addAttribute(.cursor, value: NSCursor.pointingHand, range: range)
                }
#endif
            }
        }
        if let range = errorRange {
            output.addAttributes(makeErrorAttributes(), range: range)
        }
        return output
    }

    private func color(for element: JSONElement) -> UXColor {
        if options.color == .monochrome {
            switch element {
            case .punctuation: return UXColor.secondaryLabel
            case .key: return UXColor.label
            case .valueString: return UXColor.label
            case .valueOther: return UXColor.label
            case .boolean: return UXColor.label
            case .null: return UXColor.label
            }
        } else {
            switch element {
            case .punctuation: return JSONColors.punctuation
            case .key: return JSONColors.key
            case .valueString: return JSONColors.valueString
            case .valueOther: return JSONColors.valueOther
            case .boolean: return JSONColors.null
            case .null: return JSONColors.null
            }
        }
    }

    // MARK: - Walk JSON

    private func render(json: Any, path: String, isFree: Bool) {
        switch json {
        case let object as [String: Any]:
            if isFree {
                indent()
            }
            renderObject(object, path: path)
        case let string as String:
            renderString(string)
        case let array as [Any]:
            renderArray(array, path: path)
        case let number as NSNumber:
            renderNumber(number)
        default:
            if json is NSNull {
                append("null", .null)
            } else {
                append("\(json)", .valueOther)
            }
        }
    }

    private func render(json: Any, key: NetworkLogger.DecodingError.CodingKey, path: String, isFree: Bool) {
        codingPath.append(key)
        render(json: json, path: path, isFree: isFree)
        codingPath.removeLast()
    }

    private func renderObject(_ object: [String: Any], path: String) {
        let node = renderToggleIndicator(path: path, kind: .object, json: object, openBracket: "{", closeBracket: "{ ... }")
        guard node == nil || !collapsedPaths.contains(path) else { return }
        
        newline() 
        let keys = object.keys.sorted()
        for index in keys.indices {
            let key = keys[index]
            indent()
            append(String(repeating: " ", count: spaces), .punctuation)
            append("\"\(key)\"", .key)
            append(": ", .punctuation)
            indentation += 1
            let subPath = "\(path).\(key)"
            render(json: object[key]!, key: .string(key), path: subPath, isFree: false)
            indentation -= 1
            if index < keys.endIndex - 1 {
                append(",", .punctuation)
            }
            newline()
        }
        indent()
        append("}", .punctuation, nil)
    }

    private func renderArray(_ array: [Any], path: String) {
        let node = renderToggleIndicator(path: path, kind: .array, json: array, openBracket: "[", closeBracket: "[ ... ]")
        guard node == nil || !collapsedPaths.contains(path) else { return }
        
        append("\n", .punctuation)
        indentation += 1
        for index in array.indices {
            let subPath = "\(path)[\(index)]"
            render(json: array[index], key: .int(index), path: subPath, isFree: true)
            if index < array.endIndex - 1 {
                append(",", .punctuation)
            }
            newline()
        }
        indentation -= 1
        indent()
        append("]", .punctuation, nil)
    }
    
    private func renderToggleIndicator(path: String, kind: JSONContainerNode.Kind, json: Any, openBracket: String, closeBracket: String) -> JSONContainerNode? {
        guard !nodesByPath.isEmpty else {
            // Traditional rendering without collapse indicators
            append(openBracket, .punctuation, nil)
            return nil
        }
        
        let node = nodesByPath[path] ?? JSONContainerNode(kind: kind, json: json, path: path)
        let isCollapsed = collapsedPaths.contains(path)
        
        if isCollapsed {
            append("▶ ", .punctuation, node)
            append(closeBracket, .punctuation, nil)
        } else {
            append("▼ ", .punctuation, node)
            append(openBracket, .punctuation, nil)
        }
        
        return node
    }

    private func renderString(_ string: String) {
        append("\"\(string)\"", .valueString)
    }

    private func renderNumber(_ number: NSNumber) {
        if number === kCFBooleanTrue {
            append("true", .boolean)
        } else if number === kCFBooleanFalse {
            append("false", .boolean)
        } else {
            append("\(number)", .valueOther)
        }
    }

    // MARK: - Modify String

    private var previousElement: JSONElement?

    private func append(_ string: String, _ element: JSONElement, _ node: JSONContainerNode? = nil) {
        let length = string.utf16.count
        self.string += string

        if element != .key { // Style for keys is the default one
            if previousElement == element, element != .punctuation { // Coalesce the same elements
                elements[elements.endIndex - 1].0.length += length
            } else {
                elements.append((NSRange(location: index, length: length), element, node))
            }
        }
        previousElement = element

        if let error = self.error, errorRange == nil, codingPath == error.context?.codingPath {
            switch error {
            case .keyNotFound:
                // Display error on the first key in the object regardless of what it is
                if element == .key {
                    errorRange = NSRange(location: index, length: length)
                }
            default:
                errorRange = NSRange(location: index, length: length)
            }
        }

        index += length
    }

    private func indent() {
        append(String(repeating: " ", count: indentation * spaces), .punctuation)
    }

    private func newline() {
        append("\n", .punctuation)
    }

    // MARK: Error

    package static var makeErrorAttributes: ((Error) -> [NSAttributedString.Key: Any])?

    func makeErrorAttributes() -> [NSAttributedString.Key: Any] {
        guard let error = error else {
            return [:]
        }
        if let closure = TextRendererJSON.makeErrorAttributes {
            return closure(error)
        }
        return [
            .backgroundColor: options.color == .monochrome ? UXColor.label : UXColor.red,
            .foregroundColor: UXColor.white,
            .decodingError: error,
            .link: {
                var components = URLComponents()
                components.scheme = "pulse"
                components.path = "tooltip"
                components.queryItems = [
                    URLQueryItem(name: "title", value: "Decoding Error"),
                    URLQueryItem(name: "message", value: error.debugDescription)
                ]
                return components.url as Any
            }(),
            .underlineColor: UXColor.clear
        ]
    }
}

package struct JSONColors {
    package static let punctuation = UXColor.dynamic(
        light: .init(red: 113.0/255.0, green: 128.0/255.0, blue: 141.0/255.0, alpha: 1.0),
        dark: .init(red: 113.0/255.0, green: 128.0/255.0, blue: 141.0/255.0, alpha: 1.0)
    )
    package static let key = UXColor.label
    package static let valueString = Palette.red
    package static let valueOther = UXColor.dynamic(
        light: .init(red: 28.0/255.0, green: 0.0/255.0, blue: 207.0/255.0, alpha: 1.0),
        dark: .init(red: 208.0/255.0, green: 191.0/255.0, blue: 105.0/255.0, alpha: 1.0)
    )
    package static let null = Palette.pink
}

extension NSAttributedString.Key {
    package static let decodingError = NSAttributedString.Key(rawValue: "com.github.kean.pulse.decoding-error-key")
    package static let node = NSAttributedString.Key(rawValue: "com.github.kean.pulse.json-container-node")
}

package enum JSONElement {
    case punctuation
    case key
    case valueString
    case valueOther
    case boolean
    case null
}

package final class JSONContainerNode {
    package enum Kind {
        case object
        case array
    }

    package let kind: Kind
    package let json: Any
    package let path: String?

    package init(kind: Kind, json: Any, path: String? = nil) {
        self.kind = kind
        self.json = json
        self.path = path
    }
}
