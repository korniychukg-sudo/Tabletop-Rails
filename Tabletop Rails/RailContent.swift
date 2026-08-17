import SwiftUI

enum SmokeKind: String, Codable {
    case steam, diesel, none
}

enum LocoClass: String, Codable {
    case tank, tender, diesel, electric, railcar

    var label: String {
        switch self {
        case .tank: return "Tank Engine"
        case .tender: return "Tender Engine"
        case .diesel: return "Diesel"
        case .electric: return "Electric"
        case .railcar: return "Railcar"
        }
    }
}

struct Locomotive: Identifiable {
    let id: String
    let name: String
    let workshopNumber: String
    let locoClass: LocoClass
    let smoke: SmokeKind
    let maxSpeed: CGFloat
    let unlockRank: Int
    let body: Color
    let roof: Color
    let accent: Color
    let tagline: String
    let story: String
    let bestFor: String
    let plateArt: String
}

struct WagonType: Identifiable {
    let id: String
    let name: String
    let kind: String
    let body: Color
    let roof: Color
    let accent: Color
    let unlockRank: Int
    let note: String
}

enum RailContent {
    static let vehicleSpacing: CGFloat = 0.34

    static func locomotive(_ id: String) -> Locomotive {
        locomotives.first { $0.id == id } ?? locomotives[0]
    }

    static func wagon(_ id: String) -> WagonType {
        wagons.first { $0.id == id } ?? wagons[0]
    }

    static let locomotives: [Locomotive] = locoGroupA + locoGroupB + locoGroupC + locoGroupD

    private static let locoGroupA: [Locomotive] = [
        Locomotive(
            id: "pip",
            name: "Pip",
            workshopNumber: "Works No. 1",
            locoClass: .tank,
            smoke: .steam,
            maxSpeed: 1.7,
            unlockRank: 0,
            body: Color(red: 0.18, green: 0.36, blue: 0.27),
            roof: Color(red: 0.13, green: 0.13, blue: 0.13),
            accent: Color(red: 0.85, green: 0.68, blue: 0.32),
            tagline: "The little green engine every table starts with.",
            story: "Every workshop keeps one engine that never lets you down, and on this table that engine is Pip. A stubby green tank engine with brass trim and a copper-capped chimney, Pip was the first model the old keeper ever set on the baseboard, and the paint on the buffer beam is worn silver from years of gentle shunting. Tank engines carry their water in side tanks hugging the boiler, so Pip needs no tender and can trundle backwards just as happily as forwards, which is exactly what a small layout asks of a locomotive.",
            bestFor: "Short passenger runs and learning the table.",
            plateArt: "loco_pip"),
        Locomotive(
            id: "juniper",
            name: "Juniper",
            workshopNumber: "Works No. 4",
            locoClass: .tank,
            smoke: .steam,
            maxSpeed: 1.8,
            unlockRank: 0,
            body: Color(red: 0.55, green: 0.20, blue: 0.16),
            roof: Color(red: 0.15, green: 0.13, blue: 0.12),
            accent: Color(red: 0.90, green: 0.83, blue: 0.62),
            tagline: "A cheerful oxide-red shunter with a tall brass dome.",
            story: "Juniper came to the table secondhand, traded at a swap meet for a box of couplings and a bag of pine trees, and turned out to be the bargain of the decade. Painted the oxide red of old goods yards, with a disproportionately grand brass dome that catches the lamp light, Juniper is the engine you reach for when wagons need sorting. Shunting engines live their whole lives below walking pace in full-size railways, but on a tabletop Juniper is allowed the occasional gallop when nobody official is watching.",
            bestFor: "Sorting wagons around yards and sidings.",
            plateArt: "loco_juniper"),
        Locomotive(
            id: "duchess",
            name: "Duchess of Fir",
            workshopNumber: "Works No. 7",
            locoClass: .tender,
            smoke: .steam,
            maxSpeed: 2.4,
            unlockRank: 1,
            body: Color(red: 0.16, green: 0.22, blue: 0.38),
            roof: Color(red: 0.12, green: 0.12, blue: 0.14),
            accent: Color(red: 0.83, green: 0.66, blue: 0.30),
            tagline: "The express pride of the table, in midnight blue.",
            story: "When the Duchess of Fir glides past the water tower with her coaches swaying behind, conversations at the table stop. She is a proper express engine in midnight blue lined with gold, long-boilered and long-legged, and she was saved up for over a whole winter. Full-size express engines pulled trains of ten coaches at over a hundred miles an hour, and their drivers knew every gradient by heart. The Duchess asks only for a clear road, wide curves, and an audience.",
            bestFor: "Fast passenger laps on big loops.",
            plateArt: "loco_duchess"),
        Locomotive(
            id: "bram",
            name: "Old Bram",
            workshopNumber: "Works No. 3",
            locoClass: .tender,
            smoke: .steam,
            maxSpeed: 1.6,
            unlockRank: 1,
            body: Color(red: 0.16, green: 0.15, blue: 0.14),
            roof: Color(red: 0.10, green: 0.10, blue: 0.10),
            accent: Color(red: 0.72, green: 0.32, blue: 0.22),
            tagline: "A soot-black freight veteran that never hurries.",
            story: "Old Bram is the freight engine, black as a kettle and about as glamorous, with red coupling rods that flash as the wheels turn. Bram hauls anything: hoppers of pretend coal, flatbeds of matchstick timber, milk vans running late. Full-size freight engines traded speed for pulling power, with small wheels turning slowly but with enormous force. Bram's motto, if engines had mottoes, would be that everything arrives eventually, and nothing has ever been left behind.",
            bestFor: "Long, heavy goods trains.",
            plateArt: "loco_bram"),
    ]

    private static let locoGroupB: [Locomotive] = [
        Locomotive(
            id: "wren",
            name: "Wren",
            workshopNumber: "Works No. 11",
            locoClass: .railcar,
            smoke: .diesel,
            maxSpeed: 2.0,
            unlockRank: 2,
            body: Color(red: 0.62, green: 0.45, blue: 0.18),
            roof: Color(red: 0.82, green: 0.78, blue: 0.70),
            accent: Color(red: 0.30, green: 0.25, blue: 0.18),
            tagline: "A single-car railbus that goes everywhere alone.",
            story: "Wren is a railbus, a single self-propelled coach in butterscotch and cream that needs no locomotive at all. On quiet branch lines the full-size versions replaced whole trains, one driver and one car pottering between villages with the post, a few passengers, and a crate of chickens. On the table, Wren is what you run when you want movement without spectacle, a small life passing the cottage windows on schedule while bigger engines rest in the sidings.",
            bestFor: "Quiet branch line service without wagons.",
            plateArt: "loco_wren"),
        Locomotive(
            id: "harlan",
            name: "Harlan",
            workshopNumber: "Works No. 9",
            locoClass: .diesel,
            smoke: .diesel,
            maxSpeed: 1.9,
            unlockRank: 2,
            body: Color(red: 0.23, green: 0.34, blue: 0.36),
            roof: Color(red: 0.15, green: 0.18, blue: 0.19),
            accent: Color(red: 0.85, green: 0.72, blue: 0.28),
            tagline: "A slate-teal diesel shunter with wasp stripes.",
            story: "Harlan arrived in a plain box marked surplus and smelled faintly of real engine oil, which earned him immediate respect. He is a diesel shunter, slab-sided in slate teal with yellow wasp stripes across both ends so nobody steps behind him without looking. Diesel shunters ended the age of steam in the goods yards because they could be started with a button instead of a three-hour fire. Harlan starts instantly, works all day, and has never once been romantic.",
            bestFor: "All-day yard work and reliable mixed trains.",
            plateArt: "loco_harlan"),
        Locomotive(
            id: "comet",
            name: "Silver Comet",
            workshopNumber: "Works No. 14",
            locoClass: .diesel,
            smoke: .diesel,
            maxSpeed: 2.6,
            unlockRank: 3,
            body: Color(red: 0.72, green: 0.72, blue: 0.74),
            roof: Color(red: 0.45, green: 0.45, blue: 0.48),
            accent: Color(red: 0.70, green: 0.24, blue: 0.18),
            tagline: "A streamlined silver racer with a scarlet nose.",
            story: "The Silver Comet is what happened when railways discovered wind. A streamlined diesel in brushed silver with a scarlet bullet nose, she is modelled on the record-breakers that flew between cities before the war, engines shaped in wind tunnels when most trains were still shaped like sheds. The Comet dislikes tight curves, adores long straights, and produces a low whistling hum at speed that the whole table has learned to listen for.",
            bestFor: "Speed runs and expresses on wide layouts.",
            plateArt: "loco_comet"),
        Locomotive(
            id: "greta",
            name: "Greta",
            workshopNumber: "Works No. 17",
            locoClass: .electric,
            smoke: .none,
            maxSpeed: 2.3,
            unlockRank: 3,
            body: Color(red: 0.44, green: 0.26, blue: 0.42),
            roof: Color(red: 0.20, green: 0.16, blue: 0.20),
            accent: Color(red: 0.88, green: 0.84, blue: 0.75),
            tagline: "A plum-purple electric with twin pantographs.",
            story: "Greta is the modern one, a box-cab electric in deep plum with two delicate pantographs folded on her roof like resting insects. There are no wires strung over this table, a detail Greta has agreed to overlook. Electric locomotives changed mountain railways forever, pulling loads up gradients that made steam engines gasp, all in near silence. Greta runs smooth and quiet and clean, and the cat can sleep through her busiest timetable.",
            bestFor: "Silent, smooth service at any hour.",
            plateArt: "loco_greta"),
    ]

    private static let locoGroupC: [Locomotive] = [
        Locomotive(
            id: "moss",
            name: "Little Moss",
            workshopNumber: "Works No. 6",
            locoClass: .tank,
            smoke: .steam,
            maxSpeed: 1.5,
            unlockRank: 4,
            body: Color(red: 0.35, green: 0.42, blue: 0.25),
            roof: Color(red: 0.16, green: 0.15, blue: 0.12),
            accent: Color(red: 0.78, green: 0.60, blue: 0.28),
            tagline: "A narrow-gauge midget from the quarry line.",
            story: "Little Moss is a narrow-gauge engine, built for rails half the proper width, and stands barely taller than the fence posts. Engines like Moss worked slate quarries and forest tramways, squeezing around corners no main-line engine could dream of, hauling ore in trains of tiny tipping wagons. On the table Moss is everyone's favourite underdog, doing honest work with a chimney no bigger than a thimble and a whistle that sounds like a kettle deciding.",
            bestFor: "Tight corners and charming small trains.",
            plateArt: "loco_moss"),
        Locomotive(
            id: "atlas",
            name: "Atlas",
            workshopNumber: "Works No. 19",
            locoClass: .tender,
            smoke: .steam,
            maxSpeed: 2.0,
            unlockRank: 4,
            body: Color(red: 0.24, green: 0.20, blue: 0.16),
            roof: Color(red: 0.13, green: 0.12, blue: 0.11),
            accent: Color(red: 0.62, green: 0.68, blue: 0.70),
            tagline: "A heavy mountain engine with silver boiler bands.",
            story: "Atlas was built, in miniature as in legend, to carry weight. He is a heavy mountain engine in umber and iron, silver-banded, with eight coupled wheels and a snowplough that has never once met snow indoors. Mountain locomotives were the strongmen of steam, dragging trains up passes where the air thinned and the gradients doubled. Atlas takes the long way around the pond as if it were an alpine ascent and expects the water tower to be treated as base camp.",
            bestFor: "Hauling anything, anywhere, with dignity.",
            plateArt: "loco_atlas"),
        Locomotive(
            id: "nightowl",
            name: "Night Owl",
            workshopNumber: "Works No. 21",
            locoClass: .diesel,
            smoke: .diesel,
            maxSpeed: 2.2,
            unlockRank: 5,
            body: Color(red: 0.13, green: 0.17, blue: 0.26),
            roof: Color(red: 0.09, green: 0.11, blue: 0.16),
            accent: Color(red: 0.90, green: 0.78, blue: 0.42),
            tagline: "The sleeper-train diesel that owns the small hours.",
            story: "Some trains belong to the night, and the Night Owl is their engine: a long diesel in deepest navy with a golden owl painted on each flank and headlights that seem warmer after dark. Sleeper trains once crossed whole countries while their passengers dreamed, arriving with the milk at dawn platforms. When the room lamp goes out and the table runs by night, the Night Owl comes into her own, gliding past lit cottage windows with the day's last wagons.",
            bestFor: "Evening running under the room lamps.",
            plateArt: "loco_nightowl"),
    ]

    private static let locoGroupD: [Locomotive] = [
        Locomotive(
            id: "magnolia",
            name: "Magnolia",
            workshopNumber: "Works No. 23",
            locoClass: .tender,
            smoke: .steam,
            maxSpeed: 2.2,
            unlockRank: 6,
            body: Color(red: 0.36, green: 0.44, blue: 0.40),
            roof: Color(red: 0.14, green: 0.14, blue: 0.13),
            accent: Color(red: 0.86, green: 0.62, blue: 0.60),
            tagline: "An elegant excursion engine in eau-de-nil and rose.",
            story: "Magnolia pulled excursion trains in her imagined former life, seaside specials and blossom-season charters, and her eau-de-nil paintwork with rose lining still smells faintly of holidays. Excursion engines were kept polished for the public eye, chosen for grace as much as power. On the table Magnolia hauls the observation car on Sunday afternoons, pausing at every station whether the timetable requires it or not, because passengers, even imaginary ones, deserve the view.",
            bestFor: "Scenic laps and special occasions.",
            plateArt: "loco_magnolia"),
        Locomotive(
            id: "foreman",
            name: "The Foreman",
            workshopNumber: "Works No. 25",
            locoClass: .diesel,
            smoke: .diesel,
            maxSpeed: 1.8,
            unlockRank: 7,
            body: Color(red: 0.65, green: 0.40, blue: 0.14),
            roof: Color(red: 0.25, green: 0.20, blue: 0.14),
            accent: Color(red: 0.20, green: 0.20, blue: 0.20),
            tagline: "A burly orange road-switcher that runs the yard.",
            story: "The Foreman is a road-switcher, the do-everything diesel of the modern age, safety orange with a black chevron and a horn that means business. Road-switchers were designed to go anywhere and pull anything, equally happy on a main line or nosing down a weedy spur to a lonely shed. The Foreman treats the whole table as one big yard to be kept in order, and the other engines have quietly accepted the arrangement.",
            bestFor: "Mixed freight and running the whole railway.",
            plateArt: "loco_foreman"),
        Locomotive(
            id: "empress",
            name: "Empress of Dawn",
            workshopNumber: "Works No. 28",
            locoClass: .tender,
            smoke: .steam,
            maxSpeed: 2.6,
            unlockRank: 7,
            body: Color(red: 0.48, green: 0.16, blue: 0.14),
            roof: Color(red: 0.16, green: 0.12, blue: 0.11),
            accent: Color(red: 0.88, green: 0.72, blue: 0.34),
            tagline: "The crimson flagship, streamlined head to tail.",
            story: "The Empress of Dawn is the flagship, the engine kept under a cloth and revealed to guests. Streamlined in deep crimson with gold speed whiskers flowing from her nose to her tender, she is modelled on the final glory of steam, engines built when designers knew the diesels were coming and decided to go out magnificently. The Empress does not shunt. The Empress does not do branch lines. The Empress runs the crack express at dawn, and the whole table rises for it.",
            bestFor: "The fastest, grandest expresses.",
            plateArt: "loco_empress"),
    ]

    static let wagons: [WagonType] = [
        WagonType(id: "coach_cherry", name: "Cherry Coach", kind: "Passenger Coach", body: Color(red: 0.52, green: 0.22, blue: 0.18), roof: Color(red: 0.82, green: 0.79, blue: 0.72), accent: Color(red: 0.85, green: 0.70, blue: 0.35), unlockRank: 0, note: "A varnished cherry-red coach with cream window bands, the backbone of every passenger train on the table."),
        WagonType(id: "coach_teak", name: "Teak Coach", kind: "Passenger Coach", body: Color(red: 0.45, green: 0.32, blue: 0.18), roof: Color(red: 0.75, green: 0.73, blue: 0.68), accent: Color(red: 0.80, green: 0.68, blue: 0.40), unlockRank: 0, note: "Panelled like the grand teak expresses of old, warm brown with gold lining and imaginary lamplight inside."),
        WagonType(id: "boxcar", name: "Goods Van", kind: "Covered Van", body: Color(red: 0.42, green: 0.30, blue: 0.22), roof: Color(red: 0.30, green: 0.28, blue: 0.26), accent: Color(red: 0.20, green: 0.18, blue: 0.16), unlockRank: 0, note: "A plain planked van for everything that must stay dry, doors chalked with destinations long since rubbed out."),
        WagonType(id: "hopper", name: "Coal Hopper", kind: "Open Hopper", body: Color(red: 0.24, green: 0.24, blue: 0.26), roof: Color(red: 0.15, green: 0.15, blue: 0.16), accent: Color(red: 0.50, green: 0.48, blue: 0.46), unlockRank: 0, note: "Heaped with glittering pretend coal that never runs out, the honest weight behind Old Bram's living."),
        WagonType(id: "flatbed", name: "Timber Flat", kind: "Flat Wagon", body: Color(red: 0.50, green: 0.38, blue: 0.24), roof: Color(red: 0.55, green: 0.42, blue: 0.28), accent: Color(red: 0.35, green: 0.26, blue: 0.16), unlockRank: 1, note: "A low flat wagon stacked with tiny logs, lashed with thread and smelling faintly of pencil shavings."),
        WagonType(id: "tanker", name: "Milk Tanker", kind: "Tank Wagon", body: Color(red: 0.80, green: 0.80, blue: 0.78), roof: Color(red: 0.60, green: 0.60, blue: 0.58), accent: Color(red: 0.30, green: 0.40, blue: 0.50), unlockRank: 1, note: "A gleaming silver churn on wheels; milk trains once ran overnight so the cities could have breakfast."),
        WagonType(id: "mailvan", name: "Mail Van", kind: "Mail Van", body: Color(red: 0.55, green: 0.16, blue: 0.14), roof: Color(red: 0.35, green: 0.30, blue: 0.28), accent: Color(red: 0.85, green: 0.72, blue: 0.30), unlockRank: 2, note: "Royal red with a brass horn painted on each side, carrying letters between stations that share one postbox."),
        WagonType(id: "fridge", name: "Ice Van", kind: "Refrigerated Van", body: Color(red: 0.78, green: 0.82, blue: 0.80), roof: Color(red: 0.55, green: 0.58, blue: 0.57), accent: Color(red: 0.25, green: 0.45, blue: 0.50), unlockRank: 3, note: "White-painted to throw off the sun, once packed with real ice at the docks; the fish inside are strictly wooden."),
        WagonType(id: "gondola", name: "Gravel Gondola", kind: "Open Wagon", body: Color(red: 0.35, green: 0.38, blue: 0.32), roof: Color(red: 0.25, green: 0.27, blue: 0.23), accent: Color(red: 0.60, green: 0.58, blue: 0.52), unlockRank: 3, note: "Low-sided and loaded with real gravel from the garden path, the heaviest thing on the table by far."),
        WagonType(id: "observation", name: "Observation Car", kind: "Observation Coach", body: Color(red: 0.30, green: 0.38, blue: 0.36), roof: Color(red: 0.80, green: 0.77, blue: 0.70), accent: Color(red: 0.85, green: 0.68, blue: 0.32), unlockRank: 5, note: "The rounded rear car with the big windows, always marshalled last so its imaginary passengers keep the view."),
        WagonType(id: "caboose", name: "Guard's Van", kind: "Brake Van", body: Color(red: 0.48, green: 0.28, blue: 0.16), roof: Color(red: 0.28, green: 0.24, blue: 0.20), accent: Color(red: 0.72, green: 0.32, blue: 0.22), unlockRank: 4, note: "The little house at the end of goods trains where the guard kept his stove, his lamp, and his opinions."),
        WagonType(id: "wellwagon", name: "Well Wagon", kind: "Heavy Hauler", body: Color(red: 0.30, green: 0.30, blue: 0.32), roof: Color(red: 0.22, green: 0.22, blue: 0.24), accent: Color(red: 0.65, green: 0.55, blue: 0.30), unlockRank: 6, note: "Dropped low between its wheels to carry the loads too tall for tunnels; today it cradles a spare boiler."),
    ]
}
