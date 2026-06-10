// The MIT License (MIT)
//
// Copyright (c) 2020-2026 Alexander Grebenyuk (github.com/kean).

import Foundation
import Pulse
import SwiftUI
import CoreData

@available(iOS 16, tvOS 16, macOS 13, watchOS 9, visionOS 1, *)
struct SessionPreviewView: View {
    let session: LoggerSessionEntity

    @Environment(\.store) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {
                Text(previewDateFormatter.string(from: session.createdAt))
                    .font(.headline)

                if let version = session.fullVersion {
                    Text("Version \(version)")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text(session.id.uuidString)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 300, alignment: .leading)
    }
}

private let previewDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .medium
    return formatter
}()
