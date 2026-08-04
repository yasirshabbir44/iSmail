//
//  SpeakAndSayTaskView.swift
//  iSmail
//
//  Listen → say the word → confirm. Builds speaking confidence like LingoKids.
//

import SwiftUI

struct SpeakAndSayTaskView: View {
    let content: SpeakAndSayContent
    var showHint: Bool = false
    var onIncorrectAttempt: (() -> Void)?
    var onCorrectAttempt: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var didHear = false
    @State private var pulseHear = false
    @State private var isDone = false
    @State private var celebrateScale: CGFloat = 1
    @State private var successTrigger = 0
    @State private var generation = 0

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: content.symbolName)
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(LearningTheme.activityTint(for: .speakAndSay))
                .frame(maxWidth: 140, maxHeight: 140)
                .frame(width: 140, height: 140)
                .background {
                    Circle()
                        .fill(LearningTheme.activitySoft(for: .speakAndSay))
                }
                .scaleEffect(celebrateScale)
                .accessibilityHidden(true)

            Text(content.word)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(content.word)

            Text(content.coachLine)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)

            Button {
                didHear = true
                SpeechManager.shared.speak(text: content.word)
                withAnimation(LearningTheme.buddyBounce) {
                    pulseHear = true
                }
                SafeAsync.after(0.35) { pulseHear = false }
            } label: {
                Label(didHear ? "Hear again" : "Hear the word", systemImage: "speaker.wave.2.fill")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(LearningTheme.activityTint(for: .speakAndSay))
                    }
                    .scaleEffect(pulseHear ? 1.04 : 1)
                    .hintAura(isActive: showHint && !didHear)
                    .hintScalePulse(isActive: showHint && !didHear)
            }
            .buttonStyle(KidBounceButtonStyle())
            .accessibilityLabel("Hear the word \(content.word)")

            Button {
                guard !isDone else { return }
                if didHear {
                    completeSay()
                } else {
                    // Soft nudge — hear first, then say.
                    onIncorrectAttempt?()
                    AudioHapticManager.shared.playIncorrect()
                    SpeechManager.shared.speak(text: "First tap Hear the word, then say \(content.word)!")
                    withAnimation(LearningTheme.buddyBounce) {
                        pulseHear = true
                    }
                    SafeAsync.after(0.4) { pulseHear = false }
                }
            } label: {
                Label("I said it!", systemImage: "checkmark.bubble.fill")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(didHear ? .white : LearningTheme.mutedInk)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: LearningTheme.minTouchTarget)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(didHear ? LearningTheme.success : LearningTheme.slot)
                    }
            }
            .buttonStyle(KidBounceButtonStyle())
            .disabled(isDone)
            .accessibilityLabel("I said \(content.word)")
            .accessibilityHint(didHear ? "Confirm you said the word" : "Listen to the word first")
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.success, trigger: successTrigger)
        .onAppear {
            SafeAsync.after(0.35) {
                SpeechManager.shared.speak(text: "Say \(content.word)!")
            }
        }
        .onDisappear { generation += 1 }
    }

    private func completeSay() {
        isDone = true
        successTrigger += 1
        AudioHapticManager.shared.playSuccess()
        SpeechManager.shared.speak(text: "Awesome! \(content.word)!")
        withAnimation(LearningTheme.successBump) {
            celebrateScale = 1.12
        }
        onCorrectAttempt?()
        let gen = generation
        SafeAsync.after(0.6) {
            guard gen == generation else { return }
            onComplete?()
        }
    }
}
