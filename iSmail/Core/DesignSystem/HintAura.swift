//
//  HintAura.swift
//  iSmail
//
//  Shared pulsing yellow glow used by adaptive hints.
//

import SwiftUI

struct HintAuraModifier: ViewModifier {
    let isActive: Bool
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? Color.yellow.opacity(pulse ? 0.9 : 0.4) : .clear,
                radius: isActive ? (pulse ? 14 : 8) : 0
            )
            .shadow(
                color: isActive ? Color.yellow.opacity(pulse ? 0.55 : 0.2) : .clear,
                radius: isActive ? (pulse ? 22 : 12) : 0
            )
            .onChange(of: isActive) { _, active in
                guard active else {
                    pulse = false
                    return
                }
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

extension View {
    /// Subtle pulsing yellow aura for ADHD-friendly adaptive hints.
    func hintAura(isActive: Bool) -> some View {
        modifier(HintAuraModifier(isActive: isActive))
    }

    /// Gentle repeating scale pulse for the correct tap-select card.
    func hintScalePulse(isActive: Bool) -> some View {
        modifier(HintScalePulseModifier(isActive: isActive))
    }
}

private struct HintScalePulseModifier: ViewModifier {
    let isActive: Bool
    @State private var pulsed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && pulsed ? 1.06 : 1.0)
            .onChange(of: isActive) { _, active in
                guard active else {
                    pulsed = false
                    return
                }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulsed = true
                }
            }
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulsed = true
                }
            }
    }
}
