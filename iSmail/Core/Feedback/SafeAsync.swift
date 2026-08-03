//
//  SafeAsync.swift
//  iSmail
//
//  Cancellation-safe delayed work for SwiftUI views (avoids post-dismiss crashes).
//

import Foundation

enum SafeAsync {
    /// Runs `action` on the main actor after `seconds`, unless the task is cancelled.
    @MainActor
    static func after(_ seconds: Double, action: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            let nanos = UInt64(max(0, seconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
