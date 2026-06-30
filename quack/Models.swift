import SwiftUI
import Observation

// MARK: - Vocab
struct VocabItem: Identifiable {
    let id: String
    let hanzi: String
    let pinyin: String
    let en: String
    let cat: String
    let tone: Tone
    let emoji: String
}

struct Category: Identifiable {
    let id: String
    let label: String
    let tone: Tone
}

let VOCAB: [VocabItem] = [
    // Fruits
    VocabItem(id: "apple",   hanzi: "苹果", pinyin: "píngguǒ",   en: "Apple",   cat: "fruits",    tone: .orange, emoji: "🍎"),
    VocabItem(id: "orange",  hanzi: "橘子", pinyin: "júzi",      en: "Orange",  cat: "fruits",    tone: .orange, emoji: "🍊"),
    VocabItem(id: "banana",  hanzi: "香蕉", pinyin: "xiāngjiāo", en: "Banana",  cat: "fruits",    tone: .yellow, emoji: "🍌"),
    VocabItem(id: "grape",   hanzi: "葡萄", pinyin: "pútáo",     en: "Grapes",  cat: "fruits",    tone: .lilac,  emoji: "🍇"),
    // Animals
    VocabItem(id: "cat",     hanzi: "猫",  pinyin: "māo",       en: "Cat",     cat: "animals",   tone: .yellow, emoji: "🐱"),
    VocabItem(id: "dog",     hanzi: "狗",  pinyin: "gǒu",       en: "Dog",     cat: "animals",   tone: .orange, emoji: "🐶"),
    VocabItem(id: "bird",    hanzi: "鸟",  pinyin: "niǎo",      en: "Bird",    cat: "animals",   tone: .cobalt, emoji: "🐦"),
    VocabItem(id: "fish",    hanzi: "鱼",  pinyin: "yú",        en: "Fish",    cat: "animals",   tone: .mint,   emoji: "🐟"),
    // Household
    VocabItem(id: "chair",   hanzi: "椅子", pinyin: "yǐzi",      en: "Chair",   cat: "household", tone: .cobalt, emoji: "🪑"),
    VocabItem(id: "book",    hanzi: "书",  pinyin: "shū",       en: "Book",    cat: "household", tone: .rose,   emoji: "📖"),
    VocabItem(id: "cup",     hanzi: "杯子", pinyin: "bēizi",     en: "Cup",     cat: "household", tone: .lilac,  emoji: "🥤"),
    VocabItem(id: "lamp",    hanzi: "灯",  pinyin: "dēng",      en: "Lamp",    cat: "household", tone: .yellow, emoji: "💡"),
    // Food
    VocabItem(id: "rice",    hanzi: "米饭", pinyin: "mǐfàn",     en: "Rice",    cat: "food",      tone: .cream,  emoji: "🍚"),
    VocabItem(id: "noodle",  hanzi: "面",  pinyin: "miàn",      en: "Noodles", cat: "food",      tone: .yellow, emoji: "🍜"),
    VocabItem(id: "egg",     hanzi: "蛋",  pinyin: "dàn",       en: "Egg",     cat: "food",      tone: .cream,  emoji: "🥚"),
    VocabItem(id: "tea",     hanzi: "茶",  pinyin: "chá",       en: "Tea",     cat: "food",      tone: .mint,   emoji: "🍵"),
    // Family
    VocabItem(id: "mom",     hanzi: "妈妈", pinyin: "māma",      en: "Mom",     cat: "family",    tone: .rose,   emoji: "👩"),
    VocabItem(id: "dad",     hanzi: "爸爸", pinyin: "bàba",      en: "Dad",     cat: "family",    tone: .cobalt, emoji: "👨"),
    VocabItem(id: "brother", hanzi: "哥哥", pinyin: "gēge",      en: "Brother", cat: "family",    tone: .orange, emoji: "🧒"),
    VocabItem(id: "sister",  hanzi: "姐姐", pinyin: "jiějie",    en: "Sister",  cat: "family",    tone: .lilac,  emoji: "👧"),
]

let CATEGORIES: [Category] = [
    Category(id: "fruits",    label: "Fruits",    tone: .orange),
    Category(id: "animals",   label: "Animals",   tone: .yellow),
    Category(id: "household", label: "Household", tone: .cobalt),
    Category(id: "food",      label: "Food",      tone: .mint),
    Category(id: "family",    label: "Family",    tone: .rose),
]

// MARK: - Gender
enum Gender: String, Codable {
    case boy = "boy"
    case girl = "girl"
}

// MARK: - TodayMission
struct TodayMission {
    var id: String
    var title: String
    var target: String

    static func defaultMission() -> TodayMission {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let month = calendar.component(.month, from: Date())
        let idx = (day + month * 3) % VOCAB.count
        let word = VOCAB[idx]
        return TodayMission(
            id: "today",
            title: "Find the \(word.en.lowercased())",
            target: word.id
        )
    }
}

// MARK: - Rarity
enum Rarity: String, Codable, CaseIterable {
    case common, rare, epic, legendary

    // Stable hash — hashValue is session-randomised in Swift
    static func make(for word: String) -> Rarity {
        var h: UInt64 = 5381
        for c in word.utf8 { h = h &* 31 &+ UInt64(c) }
        switch h % 100 {
        case 0..<2:  return .legendary
        case 2..<10: return .epic
        case 10..<30: return .rare
        default:     return .common
        }
    }

    var displayName: String { rawValue.uppercased() }
    var exp: Int { switch self { case .common: 10; case .rare: 25; case .epic: 50; case .legendary: 100 } }
    var stars: Int { switch self { case .common: 1; case .rare: 2; case .epic: 3; case .legendary: 4 } }

    var accentColor: Color {
        switch self {
        case .common:    return Color.inkMuted
        case .rare:      return Color.cobalt
        case .epic:      return Color.quackOrange
        case .legendary: return Color.quackYellow
        }
    }
    var headerBg: Color {
        switch self {
        case .common:    return Color.ink
        case .rare:      return Color(red: 0.08, green: 0.12, blue: 0.36)
        case .epic:      return Color(red: 0.42, green: 0.18, blue: 0.04)
        case .legendary: return Color(red: 0.36, green: 0.28, blue: 0.04)
        }
    }
}

// MARK: - Saved Collectible
struct SavedCollectible: Identifiable, Codable {
    let id: String
    let en: String
    let hanzi: String
    let pinyin: String
    let funFact: String
    let itemClass: String
    let rarity: Rarity
    let dateScanned: Date
    let imageName: String?  // filename in Documents

    var image: UIImage? {
        guard let name = imageName else { return nil }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        return UIImage(contentsOfFile: url.path)
    }

    static func make(from result: QuackGemma.ScanResult, image: UIImage?) -> SavedCollectible {
        let name: String? = image.flatMap { img in
            let n = UUID().uuidString + ".jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(n)
            guard let data = img.jpegData(compressionQuality: 0.75) else { return nil }
            try? data.write(to: url)
            return n
        }
        return SavedCollectible(id: UUID().uuidString, en: result.en, hanzi: result.hanzi,
                                pinyin: result.pinyin, funFact: result.funFact,
                                itemClass: result.itemClass,
                                rarity: Rarity.make(for: result.en),
                                dateScanned: Date(), imageName: name)
    }
}

// MARK: - Story
enum StoryMissionType: String, Codable {
    case scan, match, speak

    var displayName: String {
        switch self { case .scan: "Scan it"; case .match: "Match it"; case .speak: "Say it" }
    }
    var sfSymbol: String {
        switch self { case .scan: "camera.fill"; case .match: "flag.fill"; case .speak: "mic.fill" }
    }
}

struct AdventureStory {
    let title: String
    let setting: String     // page 1 — parent reads
    let challenge: String   // page 2 — why the word is needed
    let missionType: StoryMissionType
    let missionHint: String // shown to parent during mission
    let victory: String     // page 3 — after mission success

    // Curated offline fallbacks per category
    static func offline(target: VocabItem, name: String, gender: Gender) -> AdventureStory {
        let hero = name.isEmpty ? "Explorer" : name
        switch target.cat {
        case "fruits", "food":
            return AdventureStory(
                title: "The Chinese Market",
                setting: "\(hero) discovered a magical floating market where every merchant speaks only Mandarin! Colourful stalls drift past, piled high with treats from across China.",
                challenge: "A smiling baker holds out a fresh \(target.en.lowercased()), but shakes their head at English. To receive it, \(hero) must ask in Mandarin.",
                missionType: .scan,
                missionHint: "Point the camera at a real \(target.en.lowercased()) so Q can teach \(hero) the Chinese word.",
                victory: "'\(target.hanzi)!' (\(target.pinyin)) \(hero) says clearly. The baker beams, the market cheers, and the \(target.en.lowercased()) is theirs!"
            )
        case "animals":
            return AdventureStory(
                title: "The Whispering Jungle",
                setting: "Deep in the Whispering Jungle, every animal speaks Mandarin! \(hero) follows a trail of paw prints through the giant bamboo.",
                challenge: "A wise \(target.en.lowercased()) blocks the bridge and will only let through travellers who know its Chinese name.",
                missionType: .scan,
                missionHint: "Scan a picture or toy \(target.en.lowercased()) and Q will reveal the secret name.",
                victory: "'\(target.hanzi)!' The \(target.en.lowercased()) bows its head and the bridge lowers — adventure awaits on the other side!"
            )
        case "household":
            return AdventureStory(
                title: "The Mystery Mansion",
                setting: "\(hero) receives a mysterious invitation to a grand mansion in Beijing. Every door is locked, and each lock shows a Chinese character.",
                challenge: "The door ahead bears the character '\(target.hanzi)'. Somewhere in the room is the matching object — \(hero) must find it!",
                missionType: .match,
                missionHint: "Help \(hero) tap the correct picture that matches the Chinese character.",
                victory: "Click! The door swings open. '\(target.hanzi)' means \(target.en.lowercased()) — \(hero) earns the room's golden treasure!"
            )
        case "family":
            return AdventureStory(
                title: "The Grand Reunion",
                setting: "\(hero) receives a letter with a golden seal: they are invited to the biggest Chinese family reunion ever held! The gate is guarded by a friendly elder.",
                challenge: "To enter, every guest must greet in Mandarin. The elder smiles and says '\(target.hanzi)' — but what does it mean?",
                missionType: .speak,
                missionHint: "Help \(hero) say '\(target.hanzi)' (\(target.pinyin)) aloud — the microphone is listening!",
                victory: "The elder laughs with joy — '\(target.hanzi)' means \(target.en.lowercased())! The gates open wide and the feast begins!"
            )
        default:
            return AdventureStory(
                title: "Agent Q's Secret File",
                setting: "Headquarters has sent Agent \(hero) on a top-secret mission to Beijing. A sealed dossier sits on the desk — the code word is '\(target.hanzi)'.",
                challenge: "To decode the mission, \(hero) must figure out what '\(target.hanzi)' (\(target.pinyin)) means in English.",
                missionType: .match,
                missionHint: "Help Agent \(hero) tap the right meaning from the options.",
                victory: "Mission unlocked! '\(target.hanzi)' means \(target.en.lowercased()) — Agent \(hero) radios in success!"
            )
        }
    }
}

// MARK: - AppState
@Observable
final class AppState {
    var name: String { didSet { UserDefaults.standard.set(name, forKey: "quack.name") } }
    var codename: String { didSet { UserDefaults.standard.set(codename, forKey: "quack.codename") } }
    var age: Int { didSet { UserDefaults.standard.set(age, forKey: "quack.age") } }
    var gender: Gender {
        get { Gender(rawValue: UserDefaults.standard.string(forKey: "quack.gender") ?? "") ?? .boy }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "quack.gender") }
    }
    var streak: Int { didSet { UserDefaults.standard.set(streak, forKey: "quack.streak") } }
    var lastStreakDate: Date? { didSet { UserDefaults.standard.set(lastStreakDate, forKey: "quack.lastStreakDate") } }
    var dailyProgress: Int = 0 { didSet { saveDailyProgress() } }
    var dailyGoal: Int = 3 { didSet { UserDefaults.standard.set(dailyGoal, forKey: "quack.dailyGoal") } }
    var lastMissionStars: Int = 3  // set by each mission before calling onComplete
    var learned: [String] { didSet { saveLearned() } }
    var weekActivity: [String: [String]] = [:] { didSet { saveWeekActivity() } }
    var missionStats: [String: Int] = [:] { didSet { saveMissionStats() } }
    var hourActivity: [Int: Int] = [:] { didSet { saveHourActivity() } }
    var collectibles: [SavedCollectible] = [] { didSet { saveCollectibles() } }
    var todayMission: TodayMission
    var lastMissionTarget: String = ""  // avoids repeating same word

    // Screen time
    var screenTimeSeconds: Int = 0
    var screenTimeLimitSeconds: Int = 1800 { didSet { UserDefaults.standard.set(screenTimeLimitSeconds, forKey: "quack.screenTimeLimit") } }
    var screenTimeLimitReached = false
    private var sessionStart: Date?

    init() {
        let ud = UserDefaults.standard
        name           = ud.string(forKey: "quack.name") ?? "Alex"
        codename       = ud.string(forKey: "quack.codename") ?? "icon-agent-q"
        age            = ud.integer(forKey: "quack.age").nonZero ?? 8
        streak         = ud.integer(forKey: "quack.streak")
        lastStreakDate = ud.object(forKey: "quack.lastStreakDate") as? Date
        learned        = (try? JSONDecoder().decode([String].self, from: ud.data(forKey: "quack.learned") ?? Data())) ?? []
        weekActivity   = (try? JSONDecoder().decode([String: [String]].self, from: ud.data(forKey: "quack.weekActivity") ?? Data())) ?? [:]
        missionStats   = (try? JSONDecoder().decode([String: Int].self, from: ud.data(forKey: "quack.missionStats") ?? Data())) ?? [:]
        hourActivity   = (try? JSONDecoder().decode([Int: Int].self, from: ud.data(forKey: "quack.hourActivity") ?? Data())) ?? [:]
        collectibles   = (try? JSONDecoder().decode([SavedCollectible].self, from: ud.data(forKey: "quack.collectibles") ?? Data())) ?? []
        todayMission   = TodayMission.defaultMission()
        screenTimeLimitSeconds = max(60, ud.integer(forKey: "quack.screenTimeLimit").nonZero ?? 1800)
        dailyGoal = ud.integer(forKey: "quack.dailyGoal").nonZero ?? 3

        let today = Self.dateKey(Date())
        // Screen time: restore if same day
        if ud.string(forKey: "quack.screenTimeDate") == today {
            screenTimeSeconds = ud.integer(forKey: "quack.screenTimeSeconds")
        }
        // Daily progress: restore if same day, else reset
        dailyProgress = ud.string(forKey: "quack.dailyProgressDate") == today ? ud.integer(forKey: "quack.dailyProgress") : 0
    }

    func addLearned(_ id: String) {
        guard !learned.contains(id) else { return }
        learned.append(id)
        dailyProgress = min(dailyProgress + 1, 99)
        updateStreak()
        recordActivity(id)
    }

    private func updateStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Already credited a word today
        if let last = lastStreakDate, cal.isDateInToday(last) { return }
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        if let last = lastStreakDate, cal.startOfDay(for: last) == yesterday {
            streak += 1
        } else {
            streak = 1 // new or broken streak
        }
        lastStreakDate = Date()
    }

    func rotateToNextMission() {
        let pool = VOCAB.filter { $0.id != lastMissionTarget }
        let unlearned = pool.filter { !learned.contains($0.id) }
        let next = (unlearned.isEmpty ? pool : unlearned).randomElement() ?? VOCAB[0]
        lastMissionTarget = next.id
        todayMission = TodayMission(id: UUID().uuidString,
                                    title: "Find the \(next.en.lowercased())",
                                    target: next.id)
    }

    func recordMission(_ type: String) {
        missionStats[type, default: 0] += 1
    }

    private func recordActivity(_ id: String) {
        let key = Self.dateKey(Date())
        var act = weekActivity
        if !act[key, default: []].contains(id) { act[key, default: []].append(id) }
        weekActivity = act
        let hour = Calendar.current.component(.hour, from: Date())
        hourActivity[hour, default: 0] += 1
    }

    func seedDemoData() {
        let cal = Calendar.current

        // Seed 8 learned words
        let seedWords = ["apple","orange","cat","dog","bird","rice","mom","dad"]
        learned = seedWords

        // Past 7 days of activity (oldest → newest: Mon 3, Tue 1, Wed 4, Thu 0, Fri 2, Sat 3, today 1)
        let dayCounts = [3, 1, 4, 0, 2, 3, 1]
        let wordPool = Array(VOCAB.map(\.id).shuffled())
        var act: [String: [String]] = [:]
        for (offset, count) in dayCounts.enumerated() {
            guard count > 0 else { continue }
            let daysBack = dayCounts.count - 1 - offset
            let date = cal.date(byAdding: .day, value: -daysBack, to: Date())!
            let key = Self.dateKey(date)
            act[key] = Array(wordPool.prefix(count))
        }
        weekActivity = act

        // Streak of 5, last active yesterday
        streak = 5
        lastStreakDate = cal.date(byAdding: .day, value: -1, to: Date())

        // Daily progress: 1 word today
        dailyProgress = 1

        // Mission stats — realistic distribution
        missionStats = ["camera": 4, "speak": 5, "match": 3, "story": 2]

        // Hour activity — morning and evening peaks
        hourActivity = [8: 3, 9: 2, 10: 1, 19: 4, 20: 2, 21: 1]

        // Small screen time
        screenTimeSeconds = 12 * 60
    }

    func resetProgress() {
        learned = []
        dailyProgress = 0
        streak = 0
        lastStreakDate = nil
        weekActivity = [:]
        missionStats = [:]
        hourActivity = [:]
        collectibles = []
        codename = "icon-agent-q"
        screenTimeSeconds = 0
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "quack.screenTimeSeconds")
        ud.removeObject(forKey: "quack.screenTimeDate")
        ud.removeObject(forKey: "quack.dailyProgress")
        ud.removeObject(forKey: "quack.dailyProgressDate")
    }

    // MARK: - Screen time
    func appDidBecomeActive() {
        let today = Self.dateKey(Date())
        let ud = UserDefaults.standard
        if ud.string(forKey: "quack.screenTimeDate") != today {
            screenTimeSeconds = 0
            screenTimeLimitReached = false
            ud.set(0, forKey: "quack.screenTimeSeconds")
            ud.set(today, forKey: "quack.screenTimeDate")
        }
        sessionStart = Date()
    }

    func appDidBackground() {
        guard let start = sessionStart else { return }
        screenTimeSeconds += Int(Date().timeIntervalSince(start))
        sessionStart = nil
        UserDefaults.standard.set(screenTimeSeconds, forKey: "quack.screenTimeSeconds")
        checkLimit()
    }

    func tickScreenTime() {
        guard let start = sessionStart else { return }
        let live = screenTimeSeconds + Int(Date().timeIntervalSince(start))
        if live >= screenTimeLimitSeconds && !screenTimeLimitReached {
            screenTimeLimitReached = true
        }
    }

    private func checkLimit() {
        if screenTimeSeconds >= screenTimeLimitSeconds { screenTimeLimitReached = true }
    }

    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    private func saveLearned() {
        UserDefaults.standard.set((try? JSONEncoder().encode(learned)) ?? Data(), forKey: "quack.learned")
    }

    private func saveWeekActivity() {
        UserDefaults.standard.set((try? JSONEncoder().encode(weekActivity)) ?? Data(), forKey: "quack.weekActivity")
    }

    private func saveMissionStats() {
        UserDefaults.standard.set((try? JSONEncoder().encode(missionStats)) ?? Data(), forKey: "quack.missionStats")
    }

    private func saveHourActivity() {
        UserDefaults.standard.set((try? JSONEncoder().encode(hourActivity)) ?? Data(), forKey: "quack.hourActivity")
    }

    private func saveCollectibles() {
        UserDefaults.standard.set((try? JSONEncoder().encode(collectibles)) ?? Data(), forKey: "quack.collectibles")
    }

    private func saveDailyProgress() {
        let ud = UserDefaults.standard
        ud.set(dailyProgress, forKey: "quack.dailyProgress")
        ud.set(Self.dateKey(Date()), forKey: "quack.dailyProgressDate")
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
