import SwiftUI
import AVFoundation

struct SetupView: View {
    let onNext: () -> Void

    @State private var appeared = false
    @State private var cameraPermissionState: PermissionState = .waiting
    @State private var micPermissionState: PermissionState = .waiting
    @State private var showPrivacyCard = false

    enum PermissionState { case waiting, active, done, denied }

    private var allResolved: Bool {
        (cameraPermissionState == .done || cameraPermissionState == .denied) &&
        (micPermissionState == .done || micPermissionState == .denied)
    }

    private let animationSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    private let cameraStepDelay: CGFloat = 0.06
    private let micStepDelay: CGFloat = 0.12
    private let buttonDelay: CGFloat = 0.2

    var body: some View {
        ZStack {
            Color.quackOrange.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Getting Q ready")
                        .font(.display(32, weight: .heavy))
                        .foregroundStyle(.white)
                    Text("We'll ask for a few things")
                        .font(.bodyText(15))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .offset(y: appeared ? 0 : 16)
                .opacity(appeared ? 1 : 0)
                .animation(animationSpring, value: appeared)

                Spacer(minLength: 20)

                // Setup steps
                VStack(spacing: 12) {
                    SetupStepRow(
                        icon: "camera.fill",
                        title: "Camera access",
                        subtitle: "For pointing at things",
                        state: cameraPermissionState
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(animationSpring.delay(cameraStepDelay), value: appeared)

                    SetupStepRow(
                        icon: "mic.fill",
                        title: "Microphone access",
                        subtitle: "For saying words aloud",
                        state: micPermissionState
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(animationSpring.delay(micStepDelay), value: appeared)
                }
                .padding(.horizontal, 24)

                if showPrivacyCard {
                    PrivacyCard()
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Button
                CTAButton(
                    label: showPrivacyCard ? "Start exploring" : "Enter the app",
                    variant: .ink,
                    disabled: !allResolved,
                    action: onNext
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(animationSpring.delay(buttonDelay), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            Task { await runSetupSequence() }
        }
    }

    private func runSetupSequence() async {
        withAnimation { cameraPermissionState = .active }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let cameraGranted = await requestCameraPermission()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            cameraPermissionState = cameraGranted ? .done : .denied
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        try? await Task.sleep(nanoseconds: 400_000_000)

        withAnimation { micPermissionState = .active }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let micGranted = await requestMicrophonePermission()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            micPermissionState = micGranted ? .done : .denied
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        try? await Task.sleep(nanoseconds: 350_000_000)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            showPrivacyCard = true
        }
    }

    private func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        @unknown default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
}

// MARK: - Setup Step Row

private struct SetupStepRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let state: SetupView.PermissionState

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 44, height: 44)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)

                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else if state == .denied {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(state == .waiting ? .white.opacity(0.45) : .white)
                        .symbolEffect(.pulse, isActive: state == .active)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(state == .waiting ? .white.opacity(0.5) : .white)
                    .animation(.easeOut(duration: 0.2), value: state)

                if state == .active {
                    Text("In progress...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .transition(.opacity.combined(with: .offset(y: 4)))
                } else {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(state == .waiting ? 0.45 : 0.75))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)

            Spacer()

            if state == .done {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(state == .waiting ? 0.06 : 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(state == .active ? 0.35 : 0.15), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)
    }

    private var circleColor: Color {
        switch state {
        case .waiting: return .white.opacity(0.12)
        case .active:  return .white.opacity(0.25)
        case .done:    return .white.opacity(0.9)
        case .denied:  return .red.opacity(0.8)
        }
    }
}

private struct PrivacyCard: View {
    private let items: [(emoji: String, label: String)] = [
        ("🔒", "Privacy protected"),
        ("☁️", "No cloud sync"),
        ("👁", "Never tracked"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                HStack(spacing: 5) {
                    Text(items[i].emoji)
                        .font(.system(size: 13))
                    Text(items[i].label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                if i < items.count - 1 {
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 18)
                }
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SetupView(onNext: {})
        .environment(AppState())
}
