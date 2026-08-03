//
//  ProfileSelectionView.swift
//  iSmail
//
//  Launch screen — pick who is playing, or add a new child profile.
//

import SwiftData
import SwiftUI

struct ProfileSelectionView: View {
    @Environment(AppSession.self) private var session
    @Query(sort: \ChildProfile.createdDate) private var profiles: [ChildProfile]

    @State private var showCreateProfile = false
    @State private var selectedCardID: UUID?

    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 16),
        GridItem(.flexible(minimum: 140), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if profiles.isEmpty {
                    emptyState
                } else {
                    profileGrid
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(PlayWorldBackground())
        .sheet(isPresented: $showCreateProfile) {
            NavigationStack {
                CreateProfileView { profile in
                    session.selectProfile(profile)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("iSmail")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.ink)
                .accessibilityAddTraits(.isHeader)

            Text("Who's playing?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.ink)

            Text("Tap your card to start. Parents can add a new profile anytime.")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(LearningTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 20) {
            BuddyCoachView(mood: .cheering, size: 100)

            Text("Let's make the first profile!")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.ink)
                .multilineTextAlignment(.center)

            addProfileCard(isProminent: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Grid

    private var profileGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(profiles) { profile in
                profileCard(profile)
            }
            addProfileCard(isProminent: false)
        }
    }

    private func profileCard(_ profile: ChildProfile) -> some View {
        Button {
            selectedCardID = profile.id
            withAnimation(LearningTheme.forgivingSpring) {
                session.selectProfile(profile)
            }
        } label: {
            VStack(spacing: 14) {
                AvatarBadgeView(avatarId: profile.avatarId, size: 88)
                    .overlay {
                        RoundedRectangle(cornerRadius: 88 * 0.28, style: .continuous)
                            .strokeBorder(LearningTheme.border.opacity(0.35), lineWidth: 3)
                    }

                Text(profile.nickname)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LearningTheme.sunshine)
                    Text("\(profile.totalCoins)")
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(LearningTheme.mutedInk)
                        .monospacedDigit()
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 196)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.95))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(LearningTheme.accent.opacity(0.35), lineWidth: 3)
                    }
                    .shadow(color: LearningTheme.accent.opacity(0.12), radius: 12, y: 6)
            }
            .scaleEffect(selectedCardID == profile.id ? 1.04 : 1.0)
        }
        .buttonStyle(KidBounceButtonStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: selectedCardID)
        .accessibilityLabel("\(profile.nickname), \(profile.totalCoins) stars")
        .accessibilityHint("Start playing as \(profile.nickname)")
    }

    private func addProfileCard(isProminent: Bool) -> some View {
        Button {
            showCreateProfile = true
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(LearningTheme.accentSoft)
                        .frame(width: 88, height: 88)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(LearningTheme.accent, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                        }

                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(LearningTheme.accent)
                }

                Text("+ Add Child Profile")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(LearningTheme.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(minHeight: isProminent ? 160 : 196)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.88))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(LearningTheme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 3, dash: [10, 7]))
                    }
            }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityLabel("Add Child Profile")
        .accessibilityHint("Opens profile creation for a parent")
    }
}

#Preview("With profiles") {
    let container = try! ModelContainer(
        for: ChildProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    context.insert(ChildProfile(nickname: "Sam", dateOfBirth: .now.addingTimeInterval(-8 * 365 * 24 * 3600), avatarId: "avatar_lion"))
    context.insert(ChildProfile(nickname: "Maya", dateOfBirth: .now.addingTimeInterval(-5 * 365 * 24 * 3600), avatarId: "avatar_fox", totalCoins: 42))

    return ProfileSelectionView()
        .environment(AppSession())
        .modelContainer(container)
}

#Preview("Empty") {
    ProfileSelectionView()
        .environment(AppSession())
        .modelContainer(for: ChildProfile.self, inMemory: true)
}
