//
//  ScreenChromeButtons.swift
//  iSmail
//
//  Shared back / close controls for kid-friendly screen exits.
//

import SwiftUI

/// Circular chevron control used to leave a pushed screen or return to the map.
struct ScreenBackButton: View {
    var accessibilityLabel: String = "Back"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(LearningTheme.ink)
                .frame(width: LearningTheme.minTouchTarget, height: LearningTheme.minTouchTarget)
                .background {
                    Circle()
                        .fill(LearningTheme.surface.opacity(0.95))
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Compact circular X used on sheets and completion overlays.
struct ScreenCloseButton: View {
    var accessibilityLabel: String = "Close"
    var size: CGFloat = 44
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(LearningTheme.ink)
                .frame(width: size, height: size)
                .background {
                    Circle()
                        .fill(LearningTheme.slot)
                }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}
