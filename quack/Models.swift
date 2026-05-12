import SwiftUI

struct Question: Identifiable {
    let id = UUID()
    let character: String
    let pinyin: String
    let english: String
    let options: [String]   // first item is always the correct answer
}

struct Mission: Identifiable {
    let id: Int
    let emoji: String
    let title: String
    let chineseTitle: String
    let color: Color
    let questions: [Question]
    var isUnlocked: Bool
    var progress: Double    // 0‥1

    static let all: [Mission] = [
        Mission(
            id: 0, emoji: "🐾", title: "Animals", chineseTitle: "动物",
            color: .quOrange,
            questions: [
                Question(character: "鸭", pinyin: "yā",   english: "duck",   options: ["duck",   "cat",    "dog",    "bird"]),
                Question(character: "猫", pinyin: "māo",  english: "cat",    options: ["cat",    "dog",    "fish",   "bird"]),
                Question(character: "狗", pinyin: "gǒu",  english: "dog",    options: ["dog",    "pig",    "cat",    "bear"]),
                Question(character: "鱼", pinyin: "yú",   english: "fish",   options: ["fish",   "bird",   "frog",   "snake"]),
                Question(character: "鸟", pinyin: "niǎo", english: "bird",   options: ["bird",   "duck",   "horse",  "rabbit"]),
            ],
            isUnlocked: true, progress: 0.4
        ),
        Mission(
            id: 1, emoji: "🔢", title: "Numbers", chineseTitle: "数字",
            color: .quBlue,
            questions: [
                Question(character: "一", pinyin: "yī",  english: "one",   options: ["one",   "two",   "three", "four"]),
                Question(character: "二", pinyin: "èr",  english: "two",   options: ["two",   "one",   "five",  "six"]),
                Question(character: "三", pinyin: "sān", english: "three", options: ["three", "four",  "one",   "two"]),
                Question(character: "四", pinyin: "sì",  english: "four",  options: ["four",  "three", "seven", "eight"]),
                Question(character: "五", pinyin: "wǔ",  english: "five",  options: ["five",  "six",   "nine",  "ten"]),
            ],
            isUnlocked: true, progress: 0.0
        ),
        Mission(
            id: 2, emoji: "🎨", title: "Colors", chineseTitle: "颜色",
            color: .quPurple,
            questions: [
                Question(character: "红", pinyin: "hóng",  english: "red",    options: ["red",    "blue",   "green",  "yellow"]),
                Question(character: "蓝", pinyin: "lán",   english: "blue",   options: ["blue",   "red",    "purple", "black"]),
                Question(character: "黄", pinyin: "huáng", english: "yellow", options: ["yellow", "orange", "white",  "pink"]),
                Question(character: "绿", pinyin: "lǜ",    english: "green",  options: ["green",  "blue",   "black",  "brown"]),
                Question(character: "白", pinyin: "bái",   english: "white",  options: ["white",  "grey",   "red",    "pink"]),
            ],
            isUnlocked: false, progress: 0.0
        ),
        Mission(
            id: 3, emoji: "🍎", title: "Food", chineseTitle: "食物",
            color: .quGreen,
            questions: [
                Question(character: "饭",   pinyin: "fàn",    english: "rice",   options: ["rice",   "noodle", "bread",  "soup"]),
                Question(character: "水",   pinyin: "shuǐ",   english: "water",  options: ["water",  "milk",   "juice",  "tea"]),
                Question(character: "果",   pinyin: "guǒ",    english: "fruit",  options: ["fruit",  "meat",   "fish",   "egg"]),
                Question(character: "肉",   pinyin: "ròu",    english: "meat",   options: ["meat",   "fish",   "rice",   "bread"]),
                Question(character: "奶",   pinyin: "nǎi",    english: "milk",   options: ["milk",   "water",  "tea",    "juice"]),
            ],
            isUnlocked: false, progress: 0.0
        ),
        Mission(
            id: 4, emoji: "👨‍👩‍👧", title: "Family", chineseTitle: "家人",
            color: .quYellow,
            questions: [
                Question(character: "妈",   pinyin: "mā",    english: "mom",     options: ["mom",     "dad",     "sister",  "brother"]),
                Question(character: "爸",   pinyin: "bà",    english: "dad",     options: ["dad",     "mom",     "grandpa", "uncle"]),
                Question(character: "哥",   pinyin: "gē",    english: "brother", options: ["brother", "sister",  "cousin",  "uncle"]),
                Question(character: "姐",   pinyin: "jiě",   english: "sister",  options: ["sister",  "brother", "aunt",    "grandma"]),
                Question(character: "奶奶", pinyin: "nǎinai", english: "grandma", options: ["grandma", "grandpa", "mom",     "aunt"]),
            ],
            isUnlocked: false, progress: 0.0
        ),
    ]
}
