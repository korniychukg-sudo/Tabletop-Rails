import SwiftUI

struct GlossaryTerm: Identifiable {
    var id: String { term }
    let term: String
    let definition: String
}

enum RailGlossary {
    static let terms: [GlossaryTerm] = [
        GlossaryTerm(term: "Ballast", definition: "The bed of crushed stone that holds the sleepers in place, spreads the weight of trains, and drains rainwater away from the track."),
        GlossaryTerm(term: "Baseboard", definition: "The table or board a model railway is built on; the modeller's entire world, edge to edge."),
        GlossaryTerm(term: "Block", definition: "A stretch of line that only one train may occupy at a time, guarded by a signal at its entrance."),
        GlossaryTerm(term: "Boiler", definition: "The great water-filled barrel of a steam locomotive, where fire tubes turn water into working steam."),
        GlossaryTerm(term: "Buffer", definition: "The sprung pads on the ends of vehicles that keep them politely apart; also the fixed stop at the end of a siding."),
        GlossaryTerm(term: "Consist", definition: "The makeup and order of vehicles in a train, decided by weight, destination and tradition."),
        GlossaryTerm(term: "Coupling", definition: "The link that joins one vehicle to the next, from three loose chain links to automatic steel knuckles."),
        GlossaryTerm(term: "Coupling rod", definition: "The side rod that ties a locomotive's driving wheels together so they all push as one."),
        GlossaryTerm(term: "Dome", definition: "The raised chamber on top of a boiler where the driest steam is collected for the cylinders."),
        GlossaryTerm(term: "Dwell time", definition: "The scheduled pause a train spends standing at a station while passengers and goods are exchanged."),
        GlossaryTerm(term: "Fireman", definition: "The crew member who feeds the fire, watches the water, and keeps a steam locomotive breathing."),
        GlossaryTerm(term: "Frog", definition: "The crossing piece of a switch where one rail passes through another, named for its squat shape."),
        GlossaryTerm(term: "Gauge", definition: "The distance between the inner faces of the two rails; standard gauge is 1,435 mm."),
        GlossaryTerm(term: "Guard's van", definition: "The vehicle at the tail of a goods train where the guard rode with a stove, a lamp and a brake."),
        GlossaryTerm(term: "Headcode", definition: "Lamps or discs on a locomotive's front that told signalmen what kind of train was approaching."),
        GlossaryTerm(term: "Interlocking", definition: "The mechanism in a signal box that makes it physically impossible to set conflicting routes at once."),
        GlossaryTerm(term: "Livery", definition: "The paint scheme and lining a railway dresses its engines and coaches in; its costume and its flag."),
        GlossaryTerm(term: "Narrow gauge", definition: "Track laid closer together than standard, letting light railways curve sharply through mountains and forests."),
        GlossaryTerm(term: "Pantograph", definition: "The sprung frame on an electric locomotive's roof that presses gently against the overhead wire to draw power."),
        GlossaryTerm(term: "Path", definition: "A train's reserved slice of track and time in the working timetable."),
        GlossaryTerm(term: "Permanent way", definition: "The railway's own name for the finished track: rails, sleepers, ballast and all."),
        GlossaryTerm(term: "Pickup goods", definition: "The slow local freight train that called at every siding, leaving and collecting wagons like a rolling errand."),
        GlossaryTerm(term: "Point blades", definition: "The tapered movable rails of a switch that pivot together to choose a train's route."),
        GlossaryTerm(term: "Regulator", definition: "The driver's main control on a steam locomotive, opening the flow of steam to the cylinders."),
        GlossaryTerm(term: "Semaphore", definition: "A signal that speaks with a pivoting arm by day and coloured lamplight by night."),
        GlossaryTerm(term: "Shunting", definition: "The patient work of sorting wagons between sidings to build trains; called switching across the Atlantic."),
        GlossaryTerm(term: "Siding", definition: "A dead-end or loop of track off the running line where vehicles wait, load, or sleep."),
        GlossaryTerm(term: "Sleeper", definition: "The cross-beam under the rails that holds them to gauge; called a tie across the Atlantic."),
        GlossaryTerm(term: "Tender", definition: "The dedicated vehicle behind a steam locomotive carrying its coal and water."),
        GlossaryTerm(term: "Turnout", definition: "The proper engineering name for a switch: the junction where one track becomes two."),
        GlossaryTerm(term: "Well wagon", definition: "A freight wagon with its floor slung low between the wheels to carry tall loads under bridges."),
        GlossaryTerm(term: "Works number", definition: "The serial number a locomotive factory stamps on every engine it builds, carried for life on a brass plate."),
    ]
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

enum RailQuiz {
    static func makeRound(seed: UInt64? = nil) -> [QuizQuestion] {
        var rng = SeededRandom(seed: seed ?? UInt64(Date().timeIntervalSince1970 * 1000))
        var questions: [QuizQuestion] = []
        var usedTerms: Set<String> = []
        var usedLocos: Set<String> = []

        for _ in 0..<4 {
            if let q = glossaryQuestion(&rng, used: &usedTerms) { questions.append(q) }
        }
        for _ in 0..<2 {
            if let q = reverseGlossaryQuestion(&rng, used: &usedTerms) { questions.append(q) }
        }
        for _ in 0..<2 {
            if let q = locoQuestion(&rng, used: &usedLocos) { questions.append(q) }
        }
        questions.append(contentsOf: factQuestions(&rng, count: 2))
        while questions.count > 10 { questions.removeLast() }
        var shuffled: [QuizQuestion] = []
        var pool = questions
        while !pool.isEmpty {
            let idx = rng.nextInt(pool.count)
            shuffled.append(pool.remove(at: idx))
        }
        return shuffled
    }

    private static func pickDistinct(_ rng: inout SeededRandom, count: Int, upper: Int, avoiding: Int? = nil) -> [Int] {
        var picks: Set<Int> = []
        var guardCount = 0
        while picks.count < count && guardCount < 200 {
            guardCount += 1
            let v = rng.nextInt(upper)
            if v != avoiding { picks.insert(v) }
        }
        return Array(picks)
    }

    private static func glossaryQuestion(_ rng: inout SeededRandom, used: inout Set<String>) -> QuizQuestion? {
        let pool = RailGlossary.terms.enumerated().filter { !used.contains($0.element.term) }
        guard pool.count >= 4 else { return nil }
        let pick = pool[rng.nextInt(pool.count)]
        used.insert(pick.element.term)
        var options = [pick.element.term]
        let wrongs = pickDistinct(&rng, count: 3, upper: RailGlossary.terms.count, avoiding: pick.offset)
        for w in wrongs { options.append(RailGlossary.terms[w].term) }
        guard options.count == 4 else { return nil }
        var shuffledOptions: [String] = []
        var tmp = options
        while !tmp.isEmpty { shuffledOptions.append(tmp.remove(at: rng.nextInt(tmp.count))) }
        guard let correct = shuffledOptions.firstIndex(of: pick.element.term) else { return nil }
        return QuizQuestion(
            prompt: "Which term does the handbook define as: \u{201C}\(pick.element.definition)\u{201D}",
            options: shuffledOptions,
            correctIndex: correct,
            explanation: "\(pick.element.term): \(pick.element.definition)")
    }

    private static func reverseGlossaryQuestion(_ rng: inout SeededRandom, used: inout Set<String>) -> QuizQuestion? {
        let pool = RailGlossary.terms.enumerated().filter { !used.contains($0.element.term) }
        guard pool.count >= 4 else { return nil }
        let pick = pool[rng.nextInt(pool.count)]
        used.insert(pick.element.term)
        let wrongs = pickDistinct(&rng, count: 3, upper: RailGlossary.terms.count, avoiding: pick.offset)
        var options = [pick.element.definition]
        for w in wrongs { options.append(RailGlossary.terms[w].definition) }
        guard options.count == 4 else { return nil }
        var shuffledOptions: [String] = []
        var tmp = options
        while !tmp.isEmpty { shuffledOptions.append(tmp.remove(at: rng.nextInt(tmp.count))) }
        guard let correct = shuffledOptions.firstIndex(of: pick.element.definition) else { return nil }
        return QuizQuestion(
            prompt: "What is the meaning of \u{201C}\(pick.element.term)\u{201D}?",
            options: shuffledOptions,
            correctIndex: correct,
            explanation: "\(pick.element.term): \(pick.element.definition)")
    }

    private static func locoQuestion(_ rng: inout SeededRandom, used: inout Set<String>) -> QuizQuestion? {
        let pool = RailContent.locomotives.enumerated().filter { !used.contains($0.element.id) }
        guard pool.count >= 4 else { return nil }
        let pick = pool[rng.nextInt(pool.count)]
        used.insert(pick.element.id)
        if rng.next() > 0.5 {
            let wrongs = pickDistinct(&rng, count: 3, upper: RailContent.locomotives.count, avoiding: pick.offset)
            var options = [pick.element.name]
            for w in wrongs { options.append(RailContent.locomotives[w].name) }
            guard options.count == 4 else { return nil }
            var shuffledOptions: [String] = []
            var tmp = options
            while !tmp.isEmpty { shuffledOptions.append(tmp.remove(at: rng.nextInt(tmp.count))) }
            guard let correct = shuffledOptions.firstIndex(of: pick.element.name) else { return nil }
            return QuizQuestion(
                prompt: "Which engine in the depot roster is described as: \u{201C}\(pick.element.tagline)\u{201D}",
                options: shuffledOptions,
                correctIndex: correct,
                explanation: "\(pick.element.name), \(pick.element.workshopNumber), is \(pick.element.tagline.lowercased().dropLast())." )
        } else {
            let classes: [LocoClass] = [.tank, .tender, .diesel, .electric, .railcar]
            let correctLabel = pick.element.locoClass.label
            var options = [correctLabel]
            for c in classes where c != pick.element.locoClass && options.count < 4 {
                options.append(c.label)
            }
            guard options.count == 4 else { return nil }
            var shuffledOptions: [String] = []
            var tmp = options
            while !tmp.isEmpty { shuffledOptions.append(tmp.remove(at: rng.nextInt(tmp.count))) }
            guard let correct = shuffledOptions.firstIndex(of: correctLabel) else { return nil }
            return QuizQuestion(
                prompt: "What kind of locomotive is \(pick.element.name), \(pick.element.workshopNumber)?",
                options: shuffledOptions,
                correctIndex: correct,
                explanation: "\(pick.element.name) is a \(correctLabel.lowercased()). \(pick.element.tagline)")
        }
    }

    private static let factBank: [(String, String, [String], String)] = [
        ("Standard gauge measures how far apart the rails sit. How wide is it?", "1,435 mm", ["1,000 mm", "1,600 mm", "2,000 mm"], "Standard gauge is 1,435 mm, four feet eight and a half inches."),
        ("What does the blast of exhaust steam up a locomotive's chimney do?", "Draws the fire harder as the engine works harder", ["Cools the boiler down", "Warns the signalman ahead", "Cleans the fire tubes"], "The exhaust blast pulls air through the fire, so a steam engine breathes in rhythm with its own effort."),
        ("Why did diesel locomotives replace steam in the goods yards?", "They started in minutes instead of hours", ["They were quieter at night", "They looked more modern", "They were easier to paint"], "A diesel starts like a truck; a steam engine needed hours of fire-raising and a crew to tend it."),
        ("Where does an electric locomotive usually get its power?", "From an overhead wire through a pantograph", ["From a fuel tank behind the cab", "From batteries under the floor", "From a small boiler"], "Electric locomotives draw current from an overhead wire, or sometimes an electrified third rail."),
        ("What was the job of the guard's van at the tail of goods trains?", "Housing the guard, his stove and his brake", ["Carrying the most fragile goods", "Powering the train's lamps", "Feeding the locomotive coal"], "The guard rode at the tail with a stove, a lamp, a desk and a brake handle."),
        ("Which cargo filled more railway wagons than everything else combined?", "Coal", ["Milk", "Timber", "Fish"], "Coal fed home fires, gasworks and factory boilers, and filled more wagons than every other cargo combined."),
        ("What is a train's reserved slice of track and time called?", "A path", ["A berth", "A slot lease", "A right of rail"], "In the working timetable every train occupies a path, threaded between the paths of others."),
        ("Why are ice vans traditionally painted white?", "To reflect sunlight and keep the load cold", ["To be visible at night", "To show they were empty", "White paint was cheapest"], "White throws off the sun; the livery was chosen by thermometer."),
        ("What keeps a wheelset safely guided over the gap at a switch frog?", "Check rails holding the opposite wheel", ["A magnet under the track", "The driver steering gently", "Extra weight in the wagon"], "Check rails grip the back of the opposite wheel so the flange cannot wander into the wrong slot."),
        ("What did early modellers traditionally use for a pond?", "A mirror laid flat with hidden edges", ["A saucer of real water", "Blue candle wax", "A sheet of tin"], "A pocket mirror laid flat has served as a pond for a hundred years, its edges hidden by reeds."),
        ("Which way were semaphore signals designed to fail if a wire broke?", "To danger, never to clear", ["To clear, never to danger", "Halfway between the two", "They dropped off the post"], "The arms were weighted so any failure swung them to danger, keeping trains apart."),
        ("What does 'dwell time' mean in a timetable?", "The pause a train spends standing at a station", ["The time an engine spends in the shed", "The gap between two trains", "Time lost to bad weather"], "Dwell is the scheduled standing time at each station for passengers and goods."),
    ]

    private static func factQuestions(_ rng: inout SeededRandom, count: Int) -> [QuizQuestion] {
        var result: [QuizQuestion] = []
        var usedIdx: Set<Int> = []
        var guardCount = 0
        while result.count < count && guardCount < 60 {
            guardCount += 1
            let idx = rng.nextInt(factBank.count)
            guard !usedIdx.contains(idx) else { continue }
            usedIdx.insert(idx)
            let fact = factBank[idx]
            var options = [fact.1] + fact.2
            var shuffledOptions: [String] = []
            while !options.isEmpty { shuffledOptions.append(options.remove(at: rng.nextInt(options.count))) }
            guard let correct = shuffledOptions.firstIndex(of: fact.1) else { continue }
            result.append(QuizQuestion(prompt: fact.0, options: shuffledOptions, correctIndex: correct, explanation: fact.3))
        }
        return result
    }
}
