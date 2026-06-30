import SwiftUI
import AVFoundation

struct SetupView: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var setupStates: [SetupState] = Array(repeating: .waiting, count: 4)
    @State private var showPrivacyCard = false
    @Environment(AppState.self) private var appState

    enum SetupState { case waiting, active, done }

    private var allDone: Bool { setupStates.allSatisfy { $0 == .done } }

    private let setupSteps: [(icon: String, title: String, description: String)] = [
        ("sparkles",                 "Personalising your story",  "Building your experience"),
        ("sparkles.rectangle.stack", "Crafting your sticker pack","Creating your collection"),
        ("camera.fill",              "Camera access",             "For pointing at things"),
        ("mic.fill",                 "Microphone access",         "For saying words aloud"),
    ]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            FloatingShapes()

            VStack(spacing: 0) {
                // Mascot + header
                VStack(spacing: 12) {
                    Image("duck-mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.05), value: appeared)

                    VStack(spacing: 4) {
                        Text("Setting up Q")
                            .font(.display(28, weight: .black))
                            .foregroundStyle(Color.ink)
                        Text("Personalizing just for \(appState.name)")
                            .font(.bodyText(14))
                            .foregroundStyle(Color.inkMuted)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.15), value: appeared)
                }
                .padding(.top, 52)

                Spacer(minLength: 24)

                // Steps list card
                VStack(spacing: 10) {
                    ForEach(0..<setupSteps.count, id: \.self) { i in
                        SetupStepRow(
                            icon: setupSteps[i].icon,
                            title: setupSteps[i].title,
                            description: setupSteps[i].description,
                            state: setupStates[i]
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2 + Double(i) * 0.07), value: appeared)
                    }
                }
                .padding(.horizontal, 24)

                if showPrivacyCard {
                    PrivacyCard()
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .transition(.scale(scale: 0.92, anchor: .top).combined(with: .opacity))
                }

                Spacer()

                CTAButton(
                    label: "Start exploring",
                    variant: .orange,
                    disabled: !allDone,
                    action: onNext
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35).delay(0.3), value: appeared)
            }
        }
        .onAppear {
            appeared = true
            Task { await runSetupSequence() }
        }
    }

    private func runSetupSequence() async {
        await activate(0); try? await Task.sleep(nanoseconds: 1_400_000_000); await complete(0)
        await activate(1); try? await Task.sleep(nanoseconds: 1_100_000_000); await complete(1)
        await activate(2); _ = await requestCamera();     await complete(2)
        try? await Task.sleep(nanoseconds: 300_000_000)
        await activate(3); _ = await requestMic();        await complete(3)
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showPrivacyCard = true }
    }

    private func activate(_ i: Int) async {
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { setupStates[i] = .active }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func complete(_ i: Int) async {
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { setupStates[i] = .done }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func requestCamera() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    private func requestMic() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .undetermined:
            return await withCheckedContinuation { cont in
                AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
            }
        default: return false
        }
    }
}

// MARK: - Setup Step Row
private struct SetupStepRow: View {
    let icon: String
    let title: String
    let description: String
    let state: SetupView.SetupState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 46, height: 46)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)

                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.paper)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(state == .waiting ? Color.inkMuted : Color.quackOrange)
                        .symbolEffect(.pulse, isActive: state == .active)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyText(14, weight: .bold))
                    .foregroundStyle(state == .waiting ? Color.inkMuted : Color.ink)

                Text(state == .active ? "Setting up..." : description)
                    .font(.bodyText(12))
                    .foregroundStyle(Color.inkMuted)
            }
            .animation(.easeOut(duration: 0.2), value: state)

            Spacer()

            if state == .done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.mintDeep)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.paper)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(state == .active ? Color.quackOrange.opacity(0.4) : Color.inkFaint, lineWidth: 1.5))
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)
    }

    private var iconBg: Color {
        switch state {
        case .waiting: return Color.inkFaint
        case .active:  return Color.quackOrange.opacity(0.15)
        case .done:    return Color.mintDeep
        }
    }
}

// MARK: - Privacy Card
private struct PrivacyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.cobalt)
                Text("Your Privacy is Protected")
                    .font(.bodyText(13, weight: .bold))
                    .foregroundStyle(Color.ink)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 6) {
                privacyRow("iphone.gen3",  "All data stored locally on your device")
                privacyRow("wifi.slash",   "No cloud sync or internet transmission")
                privacyRow("eye.slash.fill","We never track or analyse your data")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.paper).overlay(
            RoundedRectangle(cornerRadius: 16).stroke(Color.cobalt.opacity(0.2), lineWidth: 1.5)
        ))
    }

    private func privacyRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 16)
            Text(text)
                .font(.bodyText(12))
                .foregroundStyle(Color.inkMuted)
        }
    }
}

#Preview {
    SetupView(onNext: {})
        .environment(AppState())
}
