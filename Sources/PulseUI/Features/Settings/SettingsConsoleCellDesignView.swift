// The MIT License (MIT)
//
// Copyright (c) 2020-2024 Alexander Grebenyuk (github.com/kean).

#if os(iOS)

import SwiftUI
import Pulse

struct SettingsConsoleCellDesignView: View {
    @EnvironmentObject private var settings: UserSettings

    var body: some View {
        VStack(spacing: 0) {
            preview

            Form {
                SettingsConsoleTaskOptionsView(options: $settings.consoleTaskDisplayOptions)
            }
            .environment(\.editMode, .constant(.active))
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Reset") {
                    settings.consoleTaskDisplayOptions = .init()
                }
            }
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Preview".uppercased())
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)

            if let previewTask = StorePreview.previewTask {
                Divider()
                ConsoleTaskCell(task: previewTask, isDisclosureNeeded: true)
                    .padding()
                    .background(Color(.systemBackground))
                Divider()
            } else {
                Text("Failed to load the preview")
            }
        }
        .padding(.top, 16)
        .background(Color(.secondarySystemBackground))
    }
}

private struct SettingsConsoleTaskOptionsView: View {
    @Binding var options: ConsoleTaskDisplayOptions

    @State private var isShowingFieldPicker = false

    var body: some View {
        Section("Content") {
            content
        }
        Section("Details") {
            details
        }
    }

    @ViewBuilder
    private var content: some View {
        Stepper("Line Limit: \(options.contentLineLimit)", value: $options.contentLineLimit, in: 1...20)
    }

    @ViewBuilder
    private var details: some View {
        Toggle("Show Details", isOn: $options.isShowingDetails)

        if options.isShowingDetails {
            Stepper("Line Limit: \(options.detailsLineLimit)", value: $options.detailsLineLimit, in: 1...20)

            ForEach(options.detailsFields) { field in
                Text(field.title)
            }
            .onMove { from, to in
                options.detailsFields.move(fromOffsets: from, toOffset: to)
            }
            .onDelete { indexSet in
                options.detailsFields.remove(atOffsets: indexSet)
            }
            Button {
                isShowingFieldPicker = true
            } label: {
                Label("Add Field", systemImage: "plus.circle")
                    .offset(x: -2, y: 0)
            }
            .sheet(isPresented: $isShowingFieldPicker) {
                NavigationView {
                    ConsoleFieldPicker(currentSelection: Set(options.detailsFields)) {
                        options.detailsFields.append($0)
                    }
                }
            }
        }
    }
}

private struct ConsoleFieldPicker: View {
    @State var selection: ConsoleTaskDisplayOptions.Field?
    let currentSelection: Set<ConsoleTaskDisplayOptions.Field>
    let onSelection: (ConsoleTaskDisplayOptions.Field) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Picker("Field", selection: $selection) {
                let remainingCases = ConsoleTaskDisplayOptions.Field.allCases.filter {
                    !currentSelection.contains($0)
                }
                ForEach(remainingCases) { field in
                    Text(field.title)
                        .tag(Optional.some(field))
                }
            }
            .pickerStyle(.inline)
        }
        .onChange(of: selection) { value in
            if let value {
                dismiss()
                onSelection(value)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .navigationTitle("Add Field")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum StorePreview {
    static let store = try? LoggerStore(storeURL: URL(fileURLWithPath: "/dev/null"), options: [.synchronous, .inMemory])

    static let previewTask: NetworkTaskEntity? = {
        guard let store else { return nil }

        let url = URL(string: "https://api.example.com/v2.1/sites/91023547/users/49032328/profile?locale=en&fields=id,firstName,lastName,email,avatarURL")!

        var request = URLRequest(url: url)
        request.setValue("Pulse", forHTTPHeaderField: "User-Agent")
        request.setValue("Accept", forHTTPHeaderField: "application/json")

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "http/2.0", headerFields: [
            "Content-Length": "412",
            "Content-Type": "application/json; charset=utf-8",
            "Cache-Control": "no-store",
            "Content-Encoding": "gzip"
        ])

        // TODO: add taskDescription support
        store.storeRequest(request, response: response, error: nil, data: Data(count: 412), taskDescription: nil)

        let task = try? store.tasks().first
        // It's a bit hard to pass this info
        task?.duration = 150
        return task
    }()
}

#if DEBUG
#Preview {
    NavigationView {
        SettingsConsoleCellDesignView()
            .injecting(ConsoleEnvironment(store: StorePreview.store!))
            .environmentObject(UserSettings.shared)
            .navigationTitle("Cell Design")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif

#endif
