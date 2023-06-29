// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse
import Combine

public final class UserSettings: ObservableObject {
    public static let shared = UserSettings()

    @AppStorage("console-cell-line-limit")
    var lineLimit: Int = 4

    @AppStorage("link-detection")
    var isLinkDetectionEnabled = false

    @AppStorage("sharing-output")
    var sharingOutput: ShareStoreOutput = .store
}
