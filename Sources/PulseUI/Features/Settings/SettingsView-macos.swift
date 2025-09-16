// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

#if os(macOS)

import SwiftUI
import Pulse

struct SettingsView: View {
    @State private var isPresentingShareStoreView = false
    @State private var shareItems: ShareItems?

    @Environment(\.store) private var store
    @EnvironmentObject private var environment: ConsoleEnvironment
    @EnvironmentObject private var settings: UserSettings

    var body: some View {
        List {
            if !UserSettings.shared.isRemoteLoggingHidden {
                if store === RemoteLogger.shared.store {
                    RemoteLoggerSettingsView(viewModel: .shared)
                } else {
                    Text("Not available")
                        .foregroundColor(.secondary)
                }
            }
            Section("Display") {
                Toggle("Collapsible JSON Viewer", isOn: $settings.useCollapsibleJSONViewer)
                Text("When enabled, JSON responses will be displayed with collapsible nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Store") {
                // TODO: load this info async
                //                if #available(macOS 13, *), let info = try? store.info() {
                //                    LoggerStoreSizeChart(info: info, sizeLimit: store.configuration.sizeLimit)
                //                }
            }

            Section {
                HStack {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([store.storeURL])
                    }
                    if !(store.options.contains(.readonly)) {
                        Button("Remove Logs") {
                            store.removeAll()
                        }
                    }
                }
            }
        }.listStyle(.sidebar).scrollContentBackground(.hidden)
    }
}

// MARK: - Preview

#if DEBUG
struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
#endif
