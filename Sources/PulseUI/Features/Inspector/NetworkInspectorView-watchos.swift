// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

#if os(watchOS)

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
//            .toolbar {
//                if #available(watchOS 9, *), let url = viewModel.shareTaskAsHTML() {
//                    ShareLink(item: url)
//                }
//            }
    }

    var contents: some View {
        List {
            Section {
                NetworkRequestStatusSectionView(viewModel: .init(task: task, store: store))
            }
            Section {
                makeTransferInfo(isReceivedHidden: true)
                NetworkInspectorRequestTypePicker(isCurrentRequest: $settings.isShowingCurrentRequest)
                NetworkInspectorView.makeRequestSection(task: task, isCurrentRequest: settings.isShowingCurrentRequest)
            }
            if task.state != .pending {
                Section {
                    makeTransferInfo(isSentHidden: true)
                    NetworkInspectorView.makeResponseSection(task: task)
                }
            }
            if let custom = environment.delegate?.console(inspectorViewFor: task) {
                custom
            }
        }
    }

    @ViewBuilder
    private func makeTransferInfo(isSentHidden: Bool = false, isReceivedHidden: Bool = false) -> some View {
        if task.hasMetrics {
            NetworkInspectorTransferInfoView(viewModel: .init(task: task), isSentHidden: isSentHidden, isReceivedHidden: isReceivedHidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
    }
}

#if DEBUG
@available(iOS 17, tvOS 17, macOS 14, watchOS 10, visionOS 1, *)
#Preview {
    NavigationView {
        NetworkInspectorView(task: LoggerStore.preview.entity(for: .login))
    }.navigationViewStyle(.stack)
}
#endif

#endif
