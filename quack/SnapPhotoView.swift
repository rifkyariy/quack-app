import SwiftUI

struct SnapPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phase: SnapPhase = .compose
    @State private var resultWords: [VocabItem] = []
    @State private var selectedId: String? = nil
    @State private var dotScale = [false, false, false]

    enum SnapPhase { case compose, analyzing, result }

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button row
                HStack {
                    BackBtn(dark: true) { dismiss() }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)

                switch phase {
                case .compose:   composePhaseView
                case .analyzing: analyzingPhaseView
                case .result:    resultPhaseView
                }

                Spacer()

                // CTA area
                if phase == .compose {
                    CTAButton(label: "Scan it!", variant: .orange) {
                        withAnimation(.easeOut(duration: 0.3)) { phase = .analyzing }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                } else if phase == .result {
                    CTAButton(
                        label: "Learn this word",
                        variant: .ink,
                        disabled: selectedId == nil,
                        action: { dismiss() }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear { resultWords = Array(VOCAB.shuffled().prefix(4)) }
    }

    // MARK: - Compose phase
    private var composePhaseView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Point Q's camera at anything", flank: false, size: 11)
                Text("What do you see?")
                    .font(.display(24, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ink)
                    .grain(opacity: 0.12)

                SnapCornerBrackets()

                Mascot(state: .idle, size: 80)
                    .opacity(0.3)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }

    // MARK: - Analyzing phase
    private var analyzingPhaseView: some View {
        VStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ink)
                    .grain(opacity: 0.12)

                SnapCornerBrackets()

                VStack(spacing: 20) {
                    Mascot(state: .speaking, size: 80)

                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(Color.quackOrange)
                                .frame(width: 12, height: 12)
                                .scaleEffect(dotScale[i] ? 1.4 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.18),
                                    value: dotScale[i]
                                )
                        }
                    }

                    Text("Q is looking...")
                        .font(.display(16, weight: .heavy))
                        .foregroundStyle(Color.cream)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
        .onAppear {
            for i in 0..<3 { dotScale[i] = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation { phase = .result }
            }
        }
    }

    // MARK: - Result phase
    private var resultPhaseView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: "Q found these words!", flank: false, size: 11)
                Text("Pick one to learn")
                    .font(.display(24, weight: .heavy))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(resultWords) { word in
                    Button { selectedId = word.id } label: {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 8) {
                                ObjectArt(vocab: word, size: 60)
                                Text(word.hanzi)
                                    .font(.display(20, weight: .heavy))
                                    .foregroundStyle(Color.ink)
                                Text(word.en)
                                    .font(.bodyText(12))
                                    .foregroundStyle(Color.inkMuted)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cream)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                selectedId == word.id ? Color.quackOrange : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            )
                            .cardShadow()

                            if selectedId == word.id {
                                Circle()
                                    .fill(Color.quackOrange)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        QuackIcon(name: .check, size: 13, color: .white, strokeWidth: 2)
                                    )
                                    .padding(8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }
}

// MARK: - Snap corner brackets
private struct SnapCornerBrackets: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let br: CGFloat = 24
                let lw: CGFloat = 3
                let pad: CGFloat = 16
                let corners: [(CGPoint, CGFloat, CGFloat)] = [
                    (CGPoint(x: pad, y: pad),                             1,  1),
                    (CGPoint(x: size.width - pad, y: pad),               -1,  1),
                    (CGPoint(x: pad, y: size.height - pad),               1, -1),
                    (CGPoint(x: size.width - pad, y: size.height - pad), -1, -1),
                ]
                for (origin, dx, dy) in corners {
                    var p = Path()
                    p.move(to: CGPoint(x: origin.x + dx * br, y: origin.y))
                    p.addLine(to: origin)
                    p.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * br))
                    ctx.stroke(p, with: .color(.quackOrange),
                               style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    SnapPhotoView()
        .environment(AppState())
}
