//
//  CreateProfileView.swift
//  iSmail
//
//  Parent-facing child profile create / edit — avatar, nickname, birth date.
//

import SwiftData
import SwiftUI

struct CreateProfileView: View {
    enum Mode {
        case create
        case edit(ChildProfile)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) private var session

    let mode: Mode
    var onCreated: ((ChildProfile) -> Void)?
    var onDeleted: (() -> Void)?

    @State private var selectedAvatarId: String?
    @State private var nickname = ""
    @State private var dateOfBirth = Calendar.current.date(
        byAdding: .year,
        value: -6,
        to: .now
    ) ?? .now
    @State private var didSavePulse = false
    @State private var showDeleteConfirm = false
    @State private var didLoadExisting = false

    init(
        mode: Mode = .create,
        onCreated: ((ChildProfile) -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onCreated = onCreated
        self.onDeleted = onDeleted
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingProfile: ChildProfile? {
        if case .edit(let profile) = mode { return profile }
        return nil
    }

    private var trimmedNickname: String {
        ChildProfile.clampedNickname(nickname)
    }

    private var canSave: Bool {
        selectedAvatarId != nil && !trimmedNickname.isEmpty
    }

    private var characterCountLabel: String {
        "\(min(nickname.count, ChildProfile.nicknameMaxLength))/\(ChildProfile.nicknameMaxLength)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                avatarSection
                nicknameSection
                birthDateSection
                saveButton

                if isEditing {
                    deleteButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(PlayWorldBackground())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            closeBar
        }
        .onAppear {
            loadExistingIfNeeded()
        }
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Profile", role: .destructive) {
                deleteProfile()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Stars and progress for this profile will be removed. This can't be undone.")
        }
    }

    // MARK: - Chrome

    private var closeBar: some View {
        HStack {
            ScreenCloseButton(size: 48) {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isEditing ? "Edit play profile" : "New play profile")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.ink)
                .accessibilityAddTraits(.isHeader)

            Text(
                isEditing
                    ? "Update the avatar, nickname, or birth date anytime."
                    : "Parents set this up — kids pick who is playing next."
            )
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(LearningTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Pick an avatar")
            AvatarPickerView(selectedAvatarId: $selectedAvatarId)
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                        .fill(LearningTheme.surface.opacity(0.92))
                        .overlay {
                            RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                                .strokeBorder(LearningTheme.border.opacity(0.18), lineWidth: 2)
                        }
                }
        }
    }

    // MARK: - Nickname

    private var nicknameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Nickname")
                Spacer()
                Text(characterCountLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(
                        nickname.count >= ChildProfile.nicknameMaxLength
                            ? LearningTheme.coral
                            : LearningTheme.mutedInk
                    )
                    .monospacedDigit()
                    .accessibilityLabel("\(characterCountLabel) characters")
            }

            TextField("e.g. Sam", text: $nickname)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(LearningTheme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .frame(minHeight: LearningTheme.minTouchTarget + 8)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LearningTheme.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(LearningTheme.accent.opacity(0.45), lineWidth: 3)
                        }
                }
                .onChange(of: nickname) { _, newValue in
                    if newValue.count > ChildProfile.nicknameMaxLength {
                        nickname = String(newValue.prefix(ChildProfile.nicknameMaxLength))
                    }
                }
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .accessibilityLabel("Nickname")
        }
    }

    // MARK: - Birth date

    private var birthDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Date of birth")

            DatePicker(
                "Date of birth",
                selection: $dateOfBirth,
                in: ...Date.now,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                    .fill(LearningTheme.surface.opacity(0.95))
                    .overlay {
                        RoundedRectangle(cornerRadius: LearningTheme.cornerRadius, style: .continuous)
                            .strokeBorder(LearningTheme.border.opacity(0.18), lineWidth: 2)
                    }
            }
            .accessibilityLabel("Date of birth")

            Label {
                Text("We only use birth date to tailor activity difficulty.")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(LearningTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(LearningTheme.accent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LearningTheme.accentSoft)
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Save / Delete

    private var saveButton: some View {
        Button {
            saveProfile()
        } label: {
            Text(isEditing ? "Save changes" : "Save profile")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(canSave ? LearningTheme.accent : LearningTheme.mutedInk.opacity(0.35))
                }
                .scaleEffect(didSavePulse ? 1.04 : 1.0)
        }
        .buttonStyle(KidBounceButtonStyle())
        .disabled(!canSave)
        .accessibilityHint(
            canSave
                ? (isEditing ? "Saves changes to this profile" : "Saves this child profile")
                : "Choose an avatar and enter a nickname first"
        )
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Delete profile")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(LearningTheme.coral)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LearningTheme.coralSoft)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(LearningTheme.coral.opacity(0.45), lineWidth: 2)
                        }
                }
        }
        .buttonStyle(KidBounceButtonStyle())
        .accessibilityHint("Removes this child profile and their progress")
    }

    private var deleteDialogTitle: String {
        if let name = editingProfile?.nickname, !name.isEmpty {
            return "Delete \(name)?"
        }
        return "Delete this profile?"
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(LearningTheme.ink)
    }

    private func loadExistingIfNeeded() {
        guard !didLoadExisting, let profile = editingProfile else { return }
        didLoadExisting = true
        selectedAvatarId = profile.avatarId
        nickname = profile.nickname
        dateOfBirth = profile.dateOfBirth
    }

    private func saveProfile() {
        guard let avatarId = selectedAvatarId, canSave else { return }

        if let profile = editingProfile {
            profile.nickname = trimmedNickname
            profile.dateOfBirth = dateOfBirth
            profile.avatarId = avatarId
        } else {
            let profile = ChildProfile(
                nickname: trimmedNickname,
                dateOfBirth: dateOfBirth,
                avatarId: avatarId
            )
            modelContext.insert(profile)
            onCreated?(profile)
        }

        withAnimation(LearningTheme.successBump) {
            didSavePulse = true
        }
        AudioHapticManager.shared.playSuccess()
        dismiss()
    }

    private func deleteProfile() {
        guard let profile = editingProfile else { return }

        if session.activeProfileID == profile.id {
            session.clearActiveProfile()
        }
        ChildProfile.clearLocalProgress(for: profile.id)
        modelContext.delete(profile)
        onDeleted?()
        dismiss()
    }
}

#Preview("Create") {
    NavigationStack {
        CreateProfileView()
    }
    .environment(AppSession())
    .modelContainer(for: ChildProfile.self, inMemory: true)
}

#Preview("Edit") {
    let container = try! ModelContainer(
        for: ChildProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = ChildProfile(
        nickname: "Maya",
        dateOfBirth: .now.addingTimeInterval(-5 * 365 * 24 * 3600),
        avatarId: "avatar_fox",
        totalCoins: 42
    )
    container.mainContext.insert(profile)

    return NavigationStack {
        CreateProfileView(mode: .edit(profile))
    }
    .environment(AppSession())
    .modelContainer(container)
}
