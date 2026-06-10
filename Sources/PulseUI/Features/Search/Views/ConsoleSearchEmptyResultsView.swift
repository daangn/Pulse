// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(visionOS)

import SwiftUI
import Pulse
import CoreData

@available(iOS 16, tvOS 16, macOS 13, watchOS 9, visionOS 1, *)
struct ConsoleSearchEmptyResultsView: View {
    @ObservedObject var viewModel: ConsoleSearchViewModel
    @EnvironmentObject private var searchBar: ConsoleSearchBarViewModel

    var body: some View {
        emptyResults
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 8, trailing: 16))
    }

    @ViewBuilder
    private var emptyResults: some View {
        if #available(iOS 17, visionOS 1, *) {
            ContentUnavailableView.search(text: searchBar.text)
        } else {
            PulseContentUnavailableView(
                title: "No Results",
                systemImage: "magnifyingglass",
                description: Text("Check the spelling or try a new search.")
            )
        }
    }
}

#endif
