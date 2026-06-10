// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

#if os(watchOS)

import SwiftUI
import Pulse

@available(iOS 16, tvOS 16, macOS 13, watchOS 9, visionOS 1, *)
public struct SettingsView: View {
    private let store: LoggerStore

    @State private var isShowingShareView = false

    public init(store: LoggerStore = .shared) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section {
                if !UserSettings.shared.isRemoteLoggingHidden,
                   store === RemoteLogger.shared.store {
#if targetEnvironment(simulator)
                    RemoteLoggerSettingsView(viewModel: .shared)
#else
                    RemoteLoggerSettingsView(viewModel: .shared)
                        .disabled(true)
                        .foregroundColor(.secondary)
                    Text("Not available on watchOS devices")
                        .foregroundColor(.secondary)
#endif
                }
            }
            Section {
                Button("Share Store") { isShowingShareView = true }
            }
            Section {
                NavigationLink(destination: StoreDetailsView(source: .store(store))) {
                    Text("Store Info")
                }
                if !(store.options.contains(.readonly)) {
                    Button(role: .destructive, action: { store.removeAll() }) {
                        Text("Remove Logs")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingShareView) {
            NavigationView {
                ShareStoreView {
                    isShowingShareView = false
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 17, tvOS 17, macOS 14, watchOS 10, visionOS 1, *)
#Preview {
    NavigationView {
        SettingsView(store: .mock)
    }.navigationViewStyle(.stack)
}
#endif
#endif
