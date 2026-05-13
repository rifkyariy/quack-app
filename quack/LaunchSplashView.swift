import SwiftUI

struct LaunchSplashView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.quackOrange.ignoresSafeArea()
            Sparkles(count: 8, animate: true)

            VStack(spacing: 0) {
                Spacer()
                Mascot(state: .speaking, size: 100)
                    .padding(.bottom, 24)

                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text("Q")
                        .font(.display(72, weight: .black))
                        .foregroundStyle(.white)
                    Text("uack")
                        .font(.display(48, weight: .black))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                onDismiss()
            }
        }
    }
}

#Preview {
    LaunchSplashView(onDismiss: {})
        .environment(AppState())
}
