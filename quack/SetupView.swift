import SwiftUI
import AVFoundation

struct SetupView: View {
    let onNext: () -> Void
    @Environment(AppState.self) private var appState

    @State private var appeared = false
    @State private var cameraPermissionState: PermissionState = .waiting
    @State private var micPermissionState: PermissionState = .waiting

    enum PermissionState { case waiting, active, done }

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
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

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
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.06), value: appeared)

                    SetupStepRow(
                        icon: "mic.fill",
                        title: "Microphone access",
                        subtitle: "For saying words aloud",
                        state: micPermissionState
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.12), value: appeared)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Button
                CTAButton(
                    label: "Enter the app",
                    variant: .ink,
                    disabled: cameraPermissionState != .done || micPermissionState != .done,
                    action: onNext
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            Task { await runSetupSequence() }
        }
    }

    private func runSetupSequence() async {
        // Camera
        withAnimation { cameraPermissionState = .active }
        let cameraGranted = await requestCameraPermission()
        if cameraGranted {
            withAnimation { cameraPermissionState = .done }
        }

        // Microphone
        withAnimation { micPermissionState = .active }
        let micGranted = await requestMicrophonePermission()
        if micGranted {
            withAnimation { micPermissionState = .done }
        }
    }

    private func requestCameraPermission() async -> Bool {
        // Stub for now, will be implemented in Task 6
        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        // Stub for now, will be implemented in Task 6
        return true
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
                    .frame(width: 40, height: 40)

                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else if state == .active {
                    ProgressView()
                        .tint(.white.opacity(0.7))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(state == .waiting ? 0.05 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var circleColor: Color {
        switch state {
        case .waiting: return .white.opacity(0.15)
        case .active: return .white.opacity(0.2)
        case .done: return .white
        }
    }
}

#Preview {
    SetupView(onNext: {})
        .environment(AppState())
}
