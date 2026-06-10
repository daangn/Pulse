// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

import SwiftUI

// Backports of iOS 17 APIs so that PulseUI views can deploy down to iOS 16.
// Each helper applies the modern modifier when available and falls back to an
// iOS 16-compatible behavior otherwise.

// MARK: - All platforms

extension View {
    /// Applies `scrollClipDisabled()` on iOS 17+, no-op on earlier versions.
    @ViewBuilder
    func pulseScrollClipDisabled() -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            scrollClipDisabled()
        } else {
            self
        }
    }

    /// Applies the symbol-replace content transition on iOS 17+, falls back to
    /// a simple opacity transition on earlier versions.
    @ViewBuilder
    func pulseSymbolReplaceTransition() -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *) {
            contentTransition(.symbolEffect(.replace))
        } else if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *) {
            contentTransition(.opacity)
        } else {
            self
        }
    }
}

// MARK: - iOS / visionOS

#if os(iOS) || os(visionOS)

    extension View {
        /// Applies `listSectionSpacing(_:)` on iOS 17+, no-op on earlier versions.
        @ViewBuilder
        func pulseListSectionSpacing(_ spacing: CGFloat) -> some View {
            if #available(iOS 17, visionOS 1, *) {
                listSectionSpacing(spacing)
            } else {
                self
            }
        }

        /// Applies `toolbarTitleDisplayMode(.inline)` on iOS 17+, no-op on earlier versions.
        @ViewBuilder
        func pulseToolbarTitleDisplayModeInline() -> some View {
            if #available(iOS 17, visionOS 1, *) {
                toolbarTitleDisplayMode(.inline)
            } else {
                self
            }
        }

        /// Uses the programmatic `searchable(text:isPresented:)` on iOS 17+ (plus the
        /// 17.1 toolbar behavior), and falls back to `searchable(text:)` on iOS 16.
        @ViewBuilder
        func pulseSearchable(text: Binding<String>, isPresented: Binding<Bool>) -> some View {
            if #available(iOS 17, visionOS 1, *) {
                searchable(text: text, isPresented: isPresented)
                    .modifier(SearchToolbarBehaviorBackport())
            } else {
                searchable(text: text)
            }
        }
    }

    @available(iOS 17, visionOS 1, *)
    private struct SearchToolbarBehaviorBackport: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 17.1, visionOS 1.1, *) {
                content.searchPresentationToolbarBehavior(.avoidHidingContent)
            } else {
                content
            }
        }
    }

    /// Backport of `ContentUnavailableView` for iOS 16.
    struct PulseContentUnavailableView: View {
        let title: String
        let systemImage: String
        var description: Text?

        var body: some View {
            if #available(iOS 17, visionOS 1, *) {
                ContentUnavailableView {
                    Label(title, systemImage: systemImage)
                } description: {
                    description
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.system(size: 52))
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.title2.weight(.semibold))
                    description?
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

#endif
