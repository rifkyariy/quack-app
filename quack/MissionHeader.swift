import SwiftUI

// MARK: - MissionType
enum MissionType: String, CaseIterable, Identifiable {
    case camera, speak, match, story
    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: "Scan it"
        case .speak:  "Say it"
        case .match:  "Match it"
        case .story:  "Story time"
        }
    }

    var subtitle: String {
        switch self {
        case .camera: "Find the word in the world"
        case .speak:  "Repeat what Q says"
        case .match:  "Pick the right character"
        case .story:  "Read and listen"
        }
    }

    var icon: QuackIconName {
        switch self {
        case .camera: .camera
        case .speak:  .mic
        case .match:  .mission
        case .story:  .book
        }
    }

    var tone: Tone {
        switch self {
        case .camera: .orange
        case .speak:  .cobalt
        case .match:  .rose
        case .story:  .mint
        }
    }
}

// MARK: - MissionHeader
struct MissionHeader: View {
    let title: String
    var accent: Color = .quackOrange
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            BackBtn(action: onBack)
            Spacer()
            Text(title)
                .font(.display(17, weight: .heavy))
                .foregroundStyle(Color.ink)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

#Preview("MissionHeader") {
    VStack {
        MissionHeader(title: "Scan it", onBack: {})
        MissionHeader(title: "Say it", accent: .cobalt, onBack: {})
        Spacer()
    }
    .background(Color.cream)
}
