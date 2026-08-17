import SwiftUI

enum OrderReq {
    case trackTotal(Int)
    case kindCount(TrackKind, Int)
    case sceneryTotal(Int)
    case sceneryKind(SceneryKind, Int)
    case closedLoop
    case distance(Double)
    case stops(Int)
    case twoTrainSeconds(Double)
    case wagonDistance(Double)
    case locosRun(Int)
    case guidesRead(Int)
    case quizBest(Int)
    case nightSeconds(Double)
    case trainWagons(Int)

    func progress(_ store: RailStore) -> (Double, String) {
        let layout = store.layout
        let s = store.stats
        switch self {
        case .trackTotal(let n):
            return (Double(layout.trackCount) / Double(n), "Track pieces on this board: \(layout.trackCount) of \(n)")
        case .kindCount(let kind, let n):
            let c = layout.count(of: kind)
            return (Double(c) / Double(n), "\(kind.displayName) pieces placed: \(c) of \(n)")
        case .sceneryTotal(let n):
            return (Double(layout.scenery.count) / Double(n), "Scenery on this board: \(layout.scenery.count) of \(n)")
        case .sceneryKind(let kind, let n):
            let c = layout.sceneryCount(of: kind)
            return (Double(c) / Double(n), "\(kind.displayName): \(c) of \(n)")
        case .closedLoop:
            return (layout.hasClosedLoop ? 1 : 0, layout.hasClosedLoop ? "A train can run a full circuit" : "No unbroken circuit yet")
        case .distance(let n):
            return (s.distance / n, "Lifetime distance: \(Int(s.distance)) of \(Int(n)) sleepers")
        case .stops(let n):
            return (Double(s.stationStops) / Double(n), "Station calls made: \(s.stationStops) of \(n)")
        case .twoTrainSeconds(let n):
            return (s.twoTrainSeconds / n, "Two trains running together: \(Int(s.twoTrainSeconds)) of \(Int(n)) s")
        case .wagonDistance(let n):
            return (s.wagonDistance / n, "Wagon-distance hauled: \(Int(s.wagonDistance)) of \(Int(n))")
        case .locosRun(let n):
            return (Double(s.locosRun.count) / Double(n), "Different engines run: \(s.locosRun.count) of \(n)")
        case .guidesRead(let n):
            return (Double(s.guidesRead.count) / Double(n), "Handbook chapters read: \(s.guidesRead.count) of \(n)")
        case .quizBest(let n):
            return (Double(s.quizBest) / Double(n), "Best exam score: \(s.quizBest) of \(n)")
        case .nightSeconds(let n):
            return (s.nightSeconds / n, "Evening running: \(Int(s.nightSeconds)) of \(Int(n)) s")
        case .trainWagons(let n):
            let best = layout.trains.map { $0.wagonIDs.count }.max() ?? 0
            return (Double(best) / Double(n), "Longest consist on this board: \(best) of \(n) wagons")
        }
    }
}

struct RailOrder: Identifiable {
    let id: String
    let chapter: Int
    let title: String
    let client: String
    let brief: String
    let reqs: [OrderReq]
    let rewardXP: Int

    func satisfied(_ store: RailStore) -> Bool {
        reqs.allSatisfy { $0.progress(store).0 >= 1.0 }
    }

    func fraction(_ store: RailStore) -> Double {
        guard !reqs.isEmpty else { return 0 }
        let total = reqs.map { min(1.0, $0.progress(store).0) }.reduce(0, +)
        return total / Double(reqs.count)
    }
}

struct OrderChapter: Identifiable {
    let id: Int
    let name: String
    let motto: String
    let banner: String
}

enum RailOrderBook {
    static let chapters: [OrderChapter] = [
        OrderChapter(id: 0, name: "First Spikes", motto: "Every railway begins with one straight piece.", banner: "banner_ch1"),
        OrderChapter(id: 1, name: "The Working Line", motto: "A railway earns its keep by stopping.", banner: "banner_ch2"),
        OrderChapter(id: 2, name: "Growing the Town", motto: "Trains need somewhere worth going.", banner: "banner_ch3"),
        OrderChapter(id: 3, name: "Double Duty", motto: "Two trains, one table, no arguments.", banner: "banner_ch4"),
        OrderChapter(id: 4, name: "The Night Shift", motto: "The best running happens after the lamps come on.", banner: "banner_ch5"),
        OrderChapter(id: 5, name: "Master of the Table", motto: "A finished layout is never finished.", banner: "banner_ch6"),
    ]

    static let orders: [RailOrder] = ordersA + ordersB + ordersC

    private static let ordersA: [RailOrder] = [
        RailOrder(
            id: "o01", chapter: 0, title: "Lay the First Rails",
            client: "The Keeper of the Table",
            brief: "Every empty board is a promise. Put eight pieces of track on the baseboard and the promise starts to look like a railway.",
            reqs: [.trackTotal(8)], rewardXP: 30),
        RailOrder(
            id: "o02", chapter: 0, title: "Close the Circle",
            client: "Pip, probably",
            brief: "A line that ends must be reversed along; a line that circles can be ridden forever. Build one unbroken loop a train can run without stopping.",
            reqs: [.closedLoop], rewardXP: 50),
        RailOrder(
            id: "o03", chapter: 0, title: "First Steam",
            client: "The Keeper of the Table",
            brief: "Rails are only furniture until something moves on them. Run a train a good distance around your board, two hundred sleepers' worth.",
            reqs: [.distance(200)], rewardXP: 40),
        RailOrder(
            id: "o04", chapter: 0, title: "Somewhere to Stand",
            client: "The Imaginary Passengers",
            brief: "The imaginary passengers are tired of jumping aboard at speed. Give the line a station platform, and let a bit of green soften the view: three trees or more.",
            reqs: [.kindCount(.station, 1), .sceneryTotal(3)], rewardXP: 45),
        RailOrder(
            id: "o05", chapter: 1, title: "The Milk Timetable",
            client: "Marigold Dairy",
            brief: "Milk waits for nobody. Make twelve station calls so the churns are always met, and the village breakfast is safe.",
            reqs: [.stops(12)], rewardXP: 55),
        RailOrder(
            id: "o06", chapter: 1, title: "A Proper Siding",
            client: "Harlan, Yard Diesel",
            brief: "A railway with no siding is a corridor, not a railway. Add a switch and a buffer stop so wagons can be tucked away out of the running line.",
            reqs: [.kindCount(.switchRight, 1), .kindCount(.buffer, 1)], rewardXP: 55),
        RailOrder(
            id: "o07", chapter: 1, title: "Goods Must Roll",
            client: "The Gravel Consortium",
            brief: "Passengers wave, but freight pays. Haul wagons a combined three hundred sleepers of wagon-distance behind your engines.",
            reqs: [.wagonDistance(300)], rewardXP: 60),
        RailOrder(
            id: "o08", chapter: 1, title: "Second Engine",
            client: "The Depot Ledger",
            brief: "One engine is a hobby; two engines are an allocation problem, which is the true joy of railways. Run two different locomotives from the depot.",
            reqs: [.locosRun(2)], rewardXP: 50),
    ]

    private static let ordersB: [RailOrder] = [
        RailOrder(
            id: "o09", chapter: 2, title: "Cottages by the Line",
            client: "The Parish Council",
            brief: "People like watching trains from their gardens, and trains like being watched. Raise two cottages and plant a proper little wood of five trees.",
            reqs: [.sceneryKind(.house, 2), .sceneryTotal(8)], rewardXP: 60),
        RailOrder(
            id: "o10", chapter: 2, title: "Water for the Fields",
            client: "Fern Hollow Farm",
            brief: "A farm needs a pond, a fence to argue about, and a barn full of last year's hay. Set all three near the line.",
            reqs: [.sceneryKind(.pond, 1), .sceneryKind(.fence, 1), .sceneryKind(.barn, 1)], rewardXP: 65),
        RailOrder(
            id: "o11", chapter: 2, title: "Twin Platforms",
            client: "The Imaginary Passengers",
            brief: "One station makes a stop; two stations make a journey. Give the board a second platform and make twenty-five calls between them.",
            reqs: [.kindCount(.station, 2), .stops(25)], rewardXP: 70),
        RailOrder(
            id: "o12", chapter: 2, title: "The Long Way Round",
            client: "The Keeper of the Table",
            brief: "A good board rewards the scenic route. Grow the permanent way to twenty-four pieces of track, bridge included if you can manage it.",
            reqs: [.trackTotal(24), .kindCount(.bridge, 1)], rewardXP: 75),
        RailOrder(
            id: "o13", chapter: 3, title: "Two at Once",
            client: "The Signal Box",
            brief: "The real test of a layout is two trains sharing it without meeting nose to nose. Keep two running together for a full minute of table time.",
            reqs: [.twoTrainSeconds(60)], rewardXP: 80),
        RailOrder(
            id: "o14", chapter: 3, title: "The Full Consist",
            client: "Old Bram",
            brief: "Bram has been muttering about the old days of proper trains. Marshal a consist of four wagons behind one engine.",
            reqs: [.trainWagons(4)], rewardXP: 70),
        RailOrder(
            id: "o15", chapter: 3, title: "Crossing Keeper",
            client: "The Signal Box",
            brief: "Where lines cross, care lives. Lay a crossing, guard it with a signal post, and keep the trains rolling three hundred more sleepers.",
            reqs: [.kindCount(.cross, 1), .sceneryKind(.signalPost, 1), .distance(500)], rewardXP: 85),
        RailOrder(
            id: "o16", chapter: 3, title: "Both Hands Full",
            client: "The Depot Ledger",
            brief: "The depot wants its stable exercised. Run four different locomotives, each earning its day's bread on the line.",
            reqs: [.locosRun(4)], rewardXP: 80),
    ]

    private static let ordersC: [RailOrder] = [
        RailOrder(
            id: "o17", chapter: 4, title: "Lamps On",
            client: "The Night Owl",
            brief: "The table is at its best when the room goes dim and the little windows light. Run trains for three minutes of evening time.",
            reqs: [.nightSeconds(180)], rewardXP: 80),
        RailOrder(
            id: "o18", chapter: 4, title: "Light the Platforms",
            client: "The Imaginary Passengers",
            brief: "Nobody should wait for the last train in the dark. Put up three lamp posts and let the watchman's tower keep an eye on things.",
            reqs: [.sceneryKind(.lampPost, 3), .sceneryKind(.watchtower, 1)], rewardXP: 85),
        RailOrder(
            id: "o19", chapter: 4, title: "The Sleeper Service",
            client: "The Night Owl",
            brief: "A proper sleeper train is long, quiet, and punctual. Marshal five wagons behind one engine and make forty station calls lifetime.",
            reqs: [.trainWagons(5), .stops(40)], rewardXP: 90),
        RailOrder(
            id: "o20", chapter: 4, title: "Studied by Lamplight",
            client: "The Lectern",
            brief: "Winter evenings are for the handbook. Read five chapters and score at least seven on the Permanent Way Exam.",
            reqs: [.guidesRead(5), .quizBest(7)], rewardXP: 90),
        RailOrder(
            id: "o21", chapter: 5, title: "The Grand Layout",
            client: "The Keeper of the Table",
            brief: "This is the board you would show a visitor first. Forty pieces of track, two switches, and a scene dressed with fifteen pieces of scenery.",
            reqs: [.trackTotal(40), .kindCount(.switchRight, 2), .sceneryTotal(15)], rewardXP: 110),
        RailOrder(
            id: "o22", chapter: 5, title: "A Thousand Sleepers",
            client: "The Ledger of Record",
            brief: "Distance is the honest measure of a railway's life. Roll a lifetime total of one thousand sleepers under your trains.",
            reqs: [.distance(1000)], rewardXP: 100),
        RailOrder(
            id: "o23", chapter: 5, title: "The Whole Stable",
            client: "The Depot Ledger",
            brief: "Every engine deserves its day. Run seven different locomotives from the depot roster.",
            reqs: [.locosRun(7)], rewardXP: 110),
        RailOrder(
            id: "o24", chapter: 5, title: "Master's Certificate",
            client: "The Brass Plaque Committee",
            brief: "The committee awards its plaque for a life in miniature: a perfect exam, every chapter read, and five minutes of two-train running.",
            reqs: [.quizBest(10), .guidesRead(10), .twoTrainSeconds(300)], rewardXP: 150),
    ]
}
