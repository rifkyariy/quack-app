import Testing
@testable import quack

@Suite("AppState")
struct AppStateTests {
    @Test func addLearnedDeduplicates() {
        let s = AppState()
        s.addLearned("apple")
        s.addLearned("apple")
        #expect(s.learned.count == 1)
    }

    @Test func addLearnedIncrementsDailyProgress() {
        let s = AppState()
        let before = s.dailyProgress
        s.addLearned("cat")
        #expect(s.dailyProgress == before + 1)
    }

    @Test func resetProgressClearsLearned() {
        let s = AppState()
        s.addLearned("apple")
        s.resetProgress()
        #expect(s.learned.isEmpty)
        #expect(s.dailyProgress == 0)
        #expect(s.streak == 0)
    }

    @Test func vocabCoversAllCategories() {
        let cats = Set(VOCAB.map(\.cat))
        #expect(cats == Set(CATEGORIES.map(\.id)))
    }

    @Test func vocabCount() {
        #expect(VOCAB.count == 20)
    }

    @Test func todayMissionTargetInVocab() {
        let s = AppState()
        #expect(VOCAB.contains { $0.id == s.todayMission.target })
    }
}
