import SwiftUI

struct RailAward: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let emblem: Int
    let check: (RailStore) -> Bool
    let progress: (RailStore) -> (Double, String)
}

enum RailAwards {
    static let all: [RailAward] = groupA + groupB + groupC

    private static func countAward(id: String, name: String, blurb: String, emblem: Int, value: @escaping (RailStore) -> Double, target: Double, unit: String) -> RailAward {
        RailAward(id: id, name: name, blurb: blurb, emblem: emblem,
                  check: { value($0) >= target },
                  progress: { store in
                      let v = value(store)
                      return (min(1, v / target), "\(Int(min(v, target))) of \(Int(target)) \(unit)")
                  })
    }

    private static let groupA: [RailAward] = [
        countAward(id: "a_spike", name: "First Spike", blurb: "Place your first piece of track on the baseboard.", emblem: 0,
                   value: { Double($0.stats.piecesPlaced) }, target: 1, unit: "pieces"),
        countAward(id: "a_ganger", name: "The Ganger", blurb: "Place one hundred pieces of track across your boards, lifetime.", emblem: 1,
                   value: { Double($0.stats.piecesPlaced) }, target: 100, unit: "pieces"),
        RailAward(id: "a_loop", name: "Closed Circuit", blurb: "Build an unbroken loop a train can circle forever.", emblem: 2,
                  check: { $0.layouts.contains { $0.hasClosedLoop } },
                  progress: { store in (store.layouts.contains { $0.hasClosedLoop } ? 1 : 0, "Build one unbroken loop") }),
        countAward(id: "a_gardener", name: "Table Gardener", blurb: "Plant and place forty pieces of scenery, lifetime.", emblem: 3,
                   value: { Double($0.stats.sceneryPlaced) }, target: 40, unit: "pieces"),
        RailAward(id: "a_decorator", name: "Set Dresser", blurb: "Use ten different kinds of scenery on your boards.", emblem: 4,
                  check: { $0.stats.sceneryKindsUsed.count >= 10 },
                  progress: { (min(1, Double($0.stats.sceneryKindsUsed.count) / 10), "\($0.stats.sceneryKindsUsed.count) of 10 kinds") }),
        countAward(id: "a_rolling", name: "Wheels Turning", blurb: "Run your trains a lifetime distance of 300 sleepers.", emblem: 5,
                   value: { $0.stats.distance }, target: 300, unit: "sleepers"),
        countAward(id: "a_longhaul", name: "The Long Haul", blurb: "Run a lifetime distance of 2,000 sleepers.", emblem: 6,
                   value: { $0.stats.distance }, target: 2000, unit: "sleepers"),
    ]

    private static let groupB: [RailAward] = [
        countAward(id: "a_porter", name: "Platform Porter", blurb: "Make twenty station calls.", emblem: 7,
                   value: { Double($0.stats.stationStops) }, target: 20, unit: "calls"),
        countAward(id: "a_stationmaster", name: "Whistle and Flag", blurb: "Make one hundred station calls, lifetime.", emblem: 8,
                   value: { Double($0.stats.stationStops) }, target: 100, unit: "calls"),
        countAward(id: "a_freight", name: "Freight Receipts", blurb: "Haul 1,000 sleepers of wagon-distance.", emblem: 9,
                   value: { $0.stats.wagonDistance }, target: 1000, unit: "wagon-sleepers"),
        countAward(id: "a_nightowl", name: "Lamplighter", blurb: "Run trains for ten minutes of evening time.", emblem: 10,
                   value: { $0.stats.nightSeconds }, target: 600, unit: "seconds"),
        countAward(id: "a_dispatcher", name: "The Dispatcher", blurb: "Keep two trains running together for five minutes, lifetime.", emblem: 11,
                   value: { $0.stats.twoTrainSeconds }, target: 300, unit: "seconds"),
        RailAward(id: "a_roster", name: "Full Roster", blurb: "Run six different locomotives from the depot.", emblem: 12,
                  check: { $0.stats.locosRun.count >= 6 },
                  progress: { (min(1, Double($0.stats.locosRun.count) / 6), "\($0.stats.locosRun.count) of 6 engines") }),
        RailAward(id: "a_gentle", name: "Gentle Hands", blurb: "Accumulate thirty minutes of running time on the table.", emblem: 13,
                  check: { $0.stats.runSeconds >= 1800 },
                  progress: { (min(1, $0.stats.runSeconds / 1800), "\(Int($0.stats.runSeconds / 60)) of 30 minutes") }),
    ]

    private static let groupC: [RailAward] = [
        RailAward(id: "a_scholar", name: "Handbook Scholar", blurb: "Read every chapter of the Modeller's Handbook.", emblem: 14,
                  check: { $0.stats.guidesRead.count >= RailGuides.all.count },
                  progress: { (min(1, Double($0.stats.guidesRead.count) / Double(RailGuides.all.count)), "\($0.stats.guidesRead.count) of \(RailGuides.all.count) chapters") }),
        RailAward(id: "a_examiner", name: "Permanent Way Exam", blurb: "Score a perfect ten on the exam.", emblem: 15,
                  check: { $0.stats.quizBest >= 10 },
                  progress: { (Double($0.stats.quizBest) / 10, "Best score \($0.stats.quizBest) of 10") }),
        RailAward(id: "a_orders1", name: "Working to Orders", blurb: "Complete eight orders from the order book.", emblem: 16,
                  check: { $0.stats.ordersDone.count >= 8 },
                  progress: { (min(1, Double($0.stats.ordersDone.count) / 8), "\($0.stats.ordersDone.count) of 8 orders") }),
        RailAward(id: "a_orders2", name: "The Whole Book", blurb: "Complete every order in the order book.", emblem: 17,
                  check: { $0.stats.ordersDone.count >= RailOrderBook.orders.count },
                  progress: { (min(1, Double($0.stats.ordersDone.count) / Double(RailOrderBook.orders.count)), "\($0.stats.ordersDone.count) of \(RailOrderBook.orders.count) orders") }),
        RailAward(id: "a_streak", name: "Daily Departure", blurb: "Visit the table on three days in a row.", emblem: 18,
                  check: { $0.stats.bestDayStreak >= 3 },
                  progress: { (min(1, Double($0.stats.bestDayStreak) / 3), "Best streak \($0.stats.bestDayStreak) of 3 days") }),
        RailAward(id: "a_master", name: "Grand Master", blurb: "Reach the highest rank the table can bestow.", emblem: 19,
                  check: { $0.rankIndex >= RailStore.ranks.count - 1 },
                  progress: { (Double($0.rankIndex) / Double(RailStore.ranks.count - 1), $0.rank.name) }),
    ]
}
