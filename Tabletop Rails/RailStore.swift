import SwiftUI
import Combine

struct RailRank {
    let name: String
    let xp: Int
}

struct RailStats: Codable {
    var xp: Int = 0
    var distance: Double = 0
    var wagonDistance: Double = 0
    var stationStops: Int = 0
    var runSeconds: Double = 0
    var nightSeconds: Double = 0
    var bumpCount: Int = 0
    var piecesPlaced: Int = 0
    var sceneryPlaced: Int = 0
    var runsStarted: Int = 0
    var twoTrainSeconds: Double = 0
    var quizBest: Int = 0
    var quizRounds: Int = 0
    var quizCorrectTotal: Int = 0
    var sceneryKindsUsed: Set<String> = []
    var locosRun: Set<String> = []
    var guidesRead: Set<String> = []
    var ordersDone: Set<String> = []
    var awards: Set<String> = []
    var playDays: Set<String> = []
    var bestDayStreak: Int = 0
}

struct RailSave: Codable {
    var layouts: [RailLayout]?
    var currentLayout: Int?
    var stats: RailStats?
    var onboardingDone: Bool?
    var lampMode: String?
    var reduceMotion: Bool?
}

final class RailStore: ObservableObject {
    static let saveKey = "tabletop_rails_save_v1"

    @Published var layouts: [RailLayout]
    @Published var currentLayout: Int
    @Published var stats: RailStats
    @Published var onboardingDone: Bool
    @Published var lampMode: String
    @Published var reduceMotion: Bool
    @Published var celebration: String?

    private var saveWork: DispatchWorkItem?

    static let ranks: [RailRank] = [
        RailRank(name: "Junior Modeller", xp: 0),
        RailRank(name: "Track Layer", xp: 150),
        RailRank(name: "Yard Hand", xp: 400),
        RailRank(name: "Signal Keeper", xp: 800),
        RailRank(name: "Stationmaster", xp: 1400),
        RailRank(name: "Line Engineer", xp: 2200),
        RailRank(name: "Table Director", xp: 3200),
        RailRank(name: "Grand Master of the Table", xp: 4600),
    ]

    init() {
        var loadedLayouts: [RailLayout] = []
        var loadedCurrent = 0
        var loadedStats = RailStats()
        var loadedOnboarding = false
        var loadedLamp = "auto"
        var loadedReduce = false
        if let data = UserDefaults.standard.data(forKey: RailStore.saveKey),
           let save = try? JSONDecoder().decode(RailSave.self, from: data) {
            loadedLayouts = save.layouts ?? []
            loadedCurrent = save.currentLayout ?? 0
            loadedStats = save.stats ?? RailStats()
            loadedOnboarding = save.onboardingDone ?? false
            loadedLamp = save.lampMode ?? "auto"
            loadedReduce = save.reduceMotion ?? false
        }
        if loadedLayouts.isEmpty {
            loadedLayouts = [RailLayout.starter(), RailLayout(name: "Second Board"), RailLayout(name: "Third Board")]
        }
        while loadedLayouts.count < 3 {
            loadedLayouts.append(RailLayout(name: loadedLayouts.count == 1 ? "Second Board" : "Third Board"))
        }
        layouts = loadedLayouts
        currentLayout = min(loadedCurrent, loadedLayouts.count - 1)
        stats = loadedStats
        onboardingDone = loadedOnboarding
        lampMode = loadedLamp
        reduceMotion = loadedReduce
        touchPlayDay()
    }

    var layout: RailLayout {
        get { layouts[currentLayout] }
        set {
            layouts[currentLayout] = newValue
            scheduleSave()
        }
    }

    var rankIndex: Int {
        var idx = 0
        for (i, rank) in RailStore.ranks.enumerated() where stats.xp >= rank.xp { idx = i }
        return idx
    }

    var rank: RailRank { RailStore.ranks[rankIndex] }

    var nextRank: RailRank? {
        rankIndex + 1 < RailStore.ranks.count ? RailStore.ranks[rankIndex + 1] : nil
    }

    var rankProgress: Double {
        guard let next = nextRank else { return 1 }
        let base = RailStore.ranks[rankIndex].xp
        return Double(stats.xp - base) / Double(next.xp - base)
    }

    func isLocoUnlocked(_ loco: Locomotive) -> Bool { loco.unlockRank <= rankIndex }
    func isWagonUnlocked(_ wagon: WagonType) -> Bool { wagon.unlockRank <= rankIndex }
    func isSceneryUnlocked(_ kind: SceneryKind) -> Bool { kind.unlockRank <= rankIndex }

    var unlockedLocos: [Locomotive] { RailContent.locomotives.filter { isLocoUnlocked($0) } }

    func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        let before = rankIndex
        stats.xp += amount
        if rankIndex > before {
            celebration = "Promoted to \(rank.name)!"
            RailHaptics.success()
        }
        scheduleSave()
    }

    func touchPlayDay() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        let today = fmt.string(from: Date())
        if !stats.playDays.contains(today) {
            stats.playDays.insert(today)
            var streak = 1
            var day = Date()
            while true {
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
                let key = fmt.string(from: prev)
                if stats.playDays.contains(key) {
                    streak += 1
                    day = prev
                } else {
                    break
                }
            }
            stats.bestDayStreak = max(stats.bestDayStreak, streak)
            scheduleSave()
        }
    }

    var currentDayStreak: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        var streak = 0
        var day = Date()
        while stats.playDays.contains(fmt.string(from: day)) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    func absorb(_ delta: RailRunEngine.RunStatsDelta, night: Double) {
        stats.distance += Double(delta.distance)
        stats.wagonDistance += Double(delta.wagonDistance)
        stats.stationStops += delta.stops
        stats.runSeconds += delta.seconds
        if night > 0.4 { stats.nightSeconds += delta.seconds }
        stats.bumpCount += delta.bumps
        if delta.trainsRunning >= 2 { stats.twoTrainSeconds += delta.seconds }
        if delta.stops > 0 { addXP(delta.stops * 4) }
        xpAccumulator += Double(delta.distance)
        if xpAccumulator >= 10 {
            let gained = Int(xpAccumulator / 10)
            xpAccumulator -= Double(gained) * 10
            addXP(gained)
        }
        awardThrottle += delta.seconds
        if awardThrottle >= 3 || delta.stops > 0 || delta.bumps > 0 {
            awardThrottle = 0
            checkAwards()
        }
    }

    private var xpAccumulator: Double = 0
    private var awardThrottle: Double = 0

    func recordPiecePlaced() {
        stats.piecesPlaced += 1
        scheduleSave()
    }

    func recordSceneryPlaced(_ kind: SceneryKind) {
        stats.sceneryPlaced += 1
        stats.sceneryKindsUsed.insert(kind.rawValue)
        scheduleSave()
    }

    func recordRunStart() {
        stats.runsStarted += 1
        for train in layout.trains {
            stats.locosRun.insert(train.locoID)
        }
        touchPlayDay()
        scheduleSave()
    }

    func recordGuideRead(_ id: String) {
        if !stats.guidesRead.contains(id) {
            stats.guidesRead.insert(id)
            addXP(15)
            checkAwards()
        }
    }

    func recordQuiz(score: Int, of total: Int) {
        stats.quizRounds += 1
        stats.quizCorrectTotal += score
        if score > stats.quizBest { stats.quizBest = score }
        addXP(score * 6)
        checkAwards()
    }

    func completeOrder(_ order: RailOrder) {
        guard !stats.ordersDone.contains(order.id) else { return }
        stats.ordersDone.insert(order.id)
        addXP(order.rewardXP)
        celebration = "Order complete: \(order.title)"
        RailHaptics.success()
        checkAwards()
    }

    func checkAwards() {
        var earnedNew: RailAward?
        for award in RailAwards.all where !stats.awards.contains(award.id) {
            if award.check(self) {
                stats.awards.insert(award.id)
                earnedNew = award
            }
        }
        if let award = earnedNew {
            celebration = "Award earned: \(award.name)"
            RailHaptics.success()
        }
        scheduleSave()
    }

    func resetAll() {
        layouts = [RailLayout.starter(), RailLayout(name: "Second Board"), RailLayout(name: "Third Board")]
        currentLayout = 0
        stats = RailStats()
        onboardingDone = true
        scheduleSave()
    }

    func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    func saveNow() {
        let save = RailSave(
            layouts: layouts,
            currentLayout: currentLayout,
            stats: stats,
            onboardingDone: onboardingDone,
            lampMode: lampMode,
            reduceMotion: reduceMotion)
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: RailStore.saveKey)
        }
    }

    var nightFactor: Double {
        switch lampMode {
        case "day": return 0
        case "night": return 1
        default:
            let hour = Calendar.current.component(.hour, from: Date())
            let minute = Calendar.current.component(.minute, from: Date())
            let h = Double(hour) + Double(minute) / 60
            if h >= 21 || h < 5.5 { return 1 }
            if h >= 19 { return (h - 19) / 2 }
            if h < 7.5 { return 1 - (h - 5.5) / 2 }
            return 0
        }
    }
}
