//
//  IdleAttentionAnchor.swift
//  iSmail
//
//  Gentle pulse on interactive surfaces when the child has been idle too long.
//

import SwiftUI

/// Pulses the wrapped view after a stretch of no touches, then waits again.
/// Any tap or drag instantly resets the idle clock.
struct IdleAttentionAnchor: ViewModifier {
    var idleThreshold: TimeInterval = 10
    var pulseScale: CGFloat = 1.04
    var pulseDuration: TimeInterval = 0.8
    var pulseCycles: Int = 2
    /// Fired once per discrete press/drag end (for anti-spam detectors).
    var onInteractionEnded: (() -> Void)?

    @State private var scale: CGFloat = 1.0
    @State private var watchToken = 0
    @State private var watchTask: Task<Void, Never>?
    @State private var didAnnounceTouch = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !didAnnounceTouch {
                            didAnnounceTouch = true
                            resetIdleTimer()
                        }
                    }
                    .onEnded { _ in
                        didAnnounceTouch = false
                        resetIdleTimer()
                        onInteractionEnded?()
                    }
            )
            .onAppear {
                resetIdleTimer()
            }
            .onDisappear {
                cancelWatch()
                scale = 1.0
            }
    }

    private func resetIdleTimer() {
        if scale != 1.0 {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 1.0
            }
        }

        cancelWatch()
        watchToken += 1
        let token = watchToken

        watchTask = Task { @MainActor in
            let nanos = UInt64(max(0, idleThreshold) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled, token == watchToken else { return }
            await runPulseCycles(token: token)
        }
    }

    private func runPulseCycles(token: Int) async {
        let half = UInt64(pulseDuration * 1_000_000_000)

        for _ in 0..<max(pulseCycles, 1) {
            guard !Task.isCancelled, token == watchToken else { return }

            withAnimation(.easeInOut(duration: pulseDuration)) {
                scale = pulseScale
            }
            try? await Task.sleep(nanoseconds: half)
            guard !Task.isCancelled, token == watchToken else { return }

            withAnimation(.easeInOut(duration: pulseDuration)) {
                scale = 1.0
            }
            try? await Task.sleep(nanoseconds: half)
        }

        guard !Task.isCancelled, token == watchToken else { return }
        // Soft re-arm so another nudge can happen if they stay idle.
        resetIdleTimer()
    }

    private func cancelWatch() {
        watchTask?.cancel()
        watchTask = nil
    }
}

extension View {
    /// Starts a gentle 2-cycle pulse on the view after `seconds` of no interaction.
    func idleAttentionAnchor(
        after seconds: TimeInterval = 10,
        scale: CGFloat = 1.04,
        onInteractionEnded: (() -> Void)? = nil
    ) -> some View {
        modifier(
            IdleAttentionAnchor(
                idleThreshold: seconds,
                pulseScale: scale,
                onInteractionEnded: onInteractionEnded
            )
        )
    }
}
