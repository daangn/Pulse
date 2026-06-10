// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

#if os(tvOS)

import SwiftUI
import CoreData
import Pulse
import Combine

@available(iOS 16, tvOS 16, macOS 13, watchOS 9, visionOS 1, *)
struct NetworkInspectorView: View {
    @ObservedObject var task: NetworkTaskEntity

    @ObservedObject private var settings: UserSettings = .shared
    @Environment(\.store) private var store
    @EnvironmentObject private var environment: ConsoleEnvironment

    var body: some View {
        contents
            .inlineNavigationTitle(environment.shortTitle(for: task))
    }

    var contents: some View {
        HStack {
            Form { lhs }.frame(width: 740)
            Form { rhs }
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private var lhs: some View {
        Section {
            NetworkRequestStatusSectionView(viewModel: .init(task: task, store: store))
        }
        Section {
            NetworkInspectorRequestTypePicker(isCurrentRequest: $settings.isShowingCurrentRequest)
            NetworkInspectorView.makeRequestSection(task: task, isCurrentRequest: settings.isShowingCurrentRequest)
        } header: { Text("Request") }
        if task.state != .pending {
            Section {
                NetworkInspectorView.makeResponseSection(task: task)
            } header: { Text("Response") }

        }
        Section {
            NetworkCURLCell(task: task)
        } header: { Text("Transactions") }
        if let custom = environment.delegate?.console(inspectorViewFor: task) {
            custom
        }
    }

    @ViewBuilder
    private var rhs: some View {
        Section {
            NetworkInspectorView.makeHeaderView(task: task, store: store)
                .padding(.bottom, 32)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
        NetworkInspectorMetricsViewModel(task: task)
            .map(NetworkInspectorMetricsView.init)
    }
}

#if DEBUG
@available(iOS 17, tvOS 17, macOS 14, watchOS 10, visionOS 1, *)
#Preview {
    NavigationView {
        NetworkInspectorView(task: LoggerStore.preview.entity(for: .login))
    }
    .injecting(ConsoleEnvironment(store: LoggerStore.preview))
}
#endif

#endif
