// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(visionOS)

import Pulse
import SwiftUI
import UIKit

struct JSONViewer: View {
  @ObservedObject var viewModel: JSONViewerViewModel
  @State private var shareItems: ShareItems?

  var body: some View {
    JSONTextView(viewModel: viewModel)
      .navigationBarItems(trailing: navigationBarTrailingItems)
      .sheet(item: $shareItems, content: ShareView.init)
  }

  @ViewBuilder
  private var navigationBarTrailingItems: some View {
    Menu(content: {
      Button(action: { viewModel.expandAll() }) {
        Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
      }
      Button(action: { viewModel.collapseAll() }) {
        Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
      }
      Divider()
      AttributedStringShareMenu(shareItems: $shareItems) {
        viewModel.renderedString
      }
    }, label: {
      Image(systemName: "ellipsis.circle")
    })
  }
}

struct JSONTextView: UIViewRepresentable {
  @ObservedObject var viewModel: JSONViewerViewModel
  
  func makeUIView(context: Context) -> UITextView {
    let textView = UITextView(usingTextLayoutManager: true)
    textView.isEditable = false
    textView.isSelectable = true
    textView.backgroundColor = .systemBackground
    textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    textView.isScrollEnabled = true
    textView.alwaysBounceVertical = true
    
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    tapGesture.cancelsTouchesInView = false
    textView.addGestureRecognizer(tapGesture)
    
    return textView
  }
  
  func updateUIView(_ textView: UITextView, context: Context) {
    let previousOffset = textView.contentOffset
    
    textView.attributedText = viewModel.renderedString
    
    // Force layout update
    if let textLayoutManager = textView.textLayoutManager {
      textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
    }
    
    // Maintain scroll position after toggle
    if context.coordinator.shouldPreserveOffset {
      textView.setContentOffset(previousOffset, animated: false)
      context.coordinator.shouldPreserveOffset = false
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(viewModel: viewModel)
  }
  
  class Coordinator: NSObject {
    let viewModel: JSONViewerViewModel
    var shouldPreserveOffset = false
    
    init(viewModel: JSONViewerViewModel) {
      self.viewModel = viewModel
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let textView = gesture.view as? UITextView else { return }
      
      let location = gesture.location(in: textView)
      guard let characterIndex = findCharacterIndex(at: location, in: textView) else {
        // Tapped on empty space, not on text
        return
      }
      
      if let node = findNode(at: characterIndex, in: textView.textStorage) {
        shouldPreserveOffset = true
        viewModel.toggleNode(node)
      }
    }
    
    private func findCharacterIndex(at location: CGPoint, in textView: UITextView) -> Int? {
      var adjustedLocation = location
      adjustedLocation.x -= textView.textContainerInset.left
      adjustedLocation.y -= textView.textContainerInset.top
      
      guard let textLayoutManager = textView.textLayoutManager,
            let fragment = textLayoutManager.textLayoutFragment(for: adjustedLocation) else {
        return nil  // No text fragment at this location
      }
      
      // Simplified: Get approximate character index
      let relativeLocation = CGPoint(
        x: adjustedLocation.x - fragment.layoutFragmentFrame.minX,
        y: adjustedLocation.y - fragment.layoutFragmentFrame.minY
      )
      
      // Find the line fragment
      for lineFragment in fragment.textLineFragments {
        if lineFragment.typographicBounds.contains(relativeLocation) {
          let index = lineFragment.characterIndex(for: CGPoint(
            x: relativeLocation.x - lineFragment.typographicBounds.minX,
            y: relativeLocation.y - lineFragment.typographicBounds.minY
          ))
          
          let startOffset = textView.textLayoutManager?.offset(
            from: textView.textLayoutManager!.documentRange.location,
            to: fragment.rangeInElement.location
          ) ?? 0
          
          return startOffset + index
        }
      }
      
      return nil  // No line fragment at this location
    }
    
    private func findNode(at index: Int, in textStorage: NSTextStorage) -> JSONContainerNode? {
      guard index < textStorage.length else { return nil }
      
      // Only check the exact position and one character before (for the space after arrow)
      // The arrow "▶ " or "▼ " is 2 characters, so we check current and previous position
      for offset in [0, -1] {
        let checkIndex = index + offset
        guard checkIndex >= 0 && checkIndex < textStorage.length else { continue }
        
        var effectiveRange = NSRange()
        if let node = textStorage.attribute(.node, at: checkIndex, effectiveRange: &effectiveRange) as? JSONContainerNode {
          // Only return the node if we're within the arrow's range
          if NSLocationInRange(index, effectiveRange) {
            return node
          }
        }
      }
      
      return nil
    }
  }
}

#elseif os(tvOS) || os(watchOS)

import Pulse
import SwiftUI

struct JSONViewer: View {
  @ObservedObject var viewModel: JSONViewerViewModel

  var body: some View {
    ScrollView {
      Text(AttributedString(viewModel.renderedString))
        .font(.system(.body, design: .monospaced))
        .padding()
    }
  }
}

#endif