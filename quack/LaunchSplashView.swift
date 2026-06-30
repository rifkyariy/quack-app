import SwiftUI

struct LaunchSplashView: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Image("splash-quack")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Logo
                LogoType()
                    .frame(maxWidth: 200)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: appeared)
                    .padding(.top, 80)

                Text("Your cute learning buddy")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.25), value: appeared)
                    .padding(.top, 2)


                Spacer()

                Text("Preparing your quack-tastic adventure...")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkMuted)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.45), value: appeared)
                    .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            appeared = true
            Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                onDismiss()
            }
        }
    }
}

// MARK: - Shared floating background shapes
struct FloatingShapes: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle().fill(Color.quackYellow.opacity(0.75)).frame(width: 18, height: 18)
                    .position(x: w * 0.10, y: h * 0.12)
                Circle().fill(Color.quackOrange.opacity(0.45)).frame(width: 11, height: 11)
                    .position(x: w * 0.88, y: h * 0.17)
                Circle().fill(Color.cobalt.opacity(0.35)).frame(width: 13, height: 13)
                    .position(x: w * 0.06, y: h * 0.52)
                Circle().fill(Color.rose.opacity(0.5)).frame(width: 9, height: 9)
                    .position(x: w * 0.93, y: h * 0.44)
                Circle().fill(Color.mintDeep.opacity(0.4)).frame(width: 14, height: 14)
                    .position(x: w * 0.80, y: h * 0.07)
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.rose.opacity(0.65)).font(.system(size: 18))
                    .position(x: w * 0.87, y: h * 0.29)
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.lilac.opacity(0.75)).font(.system(size: 22))
                    .position(x: w * 0.12, y: h * 0.30)
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.quackYellow.opacity(0.65)).font(.system(size: 14))
                    .position(x: w * 0.82, y: h * 0.72)
                Circle().fill(Color.quackOrange.opacity(0.30)).frame(width: 10, height: 10)
                    .position(x: w * 0.18, y: h * 0.82)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    LaunchSplashView(onDismiss: {})
        .environment(AppState())
}
