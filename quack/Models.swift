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

// MARK: - AppState
@Observable
final class AppState {
    var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "quack.name") }
    }
    var age: Int {
        didSet { UserDefaults.standard.set(age, forKey: "quack.age") }
    }
    var gender: Gender {
        get { Gender(rawValue: UserDefaults.standard.string(forKey: "quack.gender") ?? "") ?? .boy }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "quack.gender") }
    }
    var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "quack.streak") }
    }
    var dailyProgress: Int = 0
    var dailyGoal: Int = 3
    var learned: [String] {
        didSet { saveLearned() }
    }
    var todayMission: TodayMission

    init() {
        let ud = UserDefaults.standard
        name          = ud.string(forKey: "quack.name") ?? "Alex"
        age           = ud.integer(forKey: "quack.age").nonZero ?? 8
        streak        = ud.integer(forKey: "quack.streak")
        learned       = (try? JSONDecoder().decode([String].self,
                          from: ud.data(forKey: "quack.learned") ?? Data())) ?? []
        todayMission  = TodayMission.defaultMission()
        dailyProgress = min(learned.count, 99)
    }

    func addLearned(_ id: String) {
        guard !learned.contains(id) else { return }
        learned.append(id)
        dailyProgress = min(dailyProgress + 1, 99)
    }

    func resetProgress() {
        learned = []
        dailyProgress = 0
        streak = 0
    }

    private func saveLearned() {
        let data = (try? JSONEncoder().encode(learned)) ?? Data()
        UserDefaults.standard.set(data, forKey: "quack.learned")
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
