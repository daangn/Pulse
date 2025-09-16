// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

#if os(iOS) || os(visionOS)

import SwiftUI
import Pulse
import UniformTypeIdentifiers

public struct SettingsView: View {
    private let store: LoggerStore
    @State private var newHeaderName = ""
    @EnvironmentObject private var settings: UserSettings
    @ObservedObject private var logger: RemoteLogger = .shared

    public init(store: LoggerStore = .shared) {
        self.store = store
    }

    public var body: some View {
        Form {
            if !UserSettings.shared.isRemoteLoggingHidden,
               store === RemoteLogger.shared.store {
                RemoteLoggerSettingsView(viewModel: .shared)
            }
            Section("Display") {
                Toggle("Collapsible JSON Viewer", isOn: $settings.useCollapsibleJSONViewer)
                Text("When enabled, JSON responses will be displayed with collapsible nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Section("Other") {
                NavigationLink(destination: StoreDetailsView(source: .store(store)), label: {
                    Text("Store Info")
                })
            }
        }
        .animation(.default, value: logger.selectedServerName)
        .animation(.default, value: logger.servers)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(store: .mock)
                .environmentObject(UserSettings.shared)
                .injecting(ConsoleEnvironment(store: .mock))
                .navigationTitle("Settings")
        }
    }
}
#endif

#endif
