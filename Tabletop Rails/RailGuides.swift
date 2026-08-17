import SwiftUI

struct RailGuide: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let plateArt: String
    let paragraphs: [String]
    let facts: [String]
}

enum RailGuides {
    static let all: [RailGuide] = partOne + partTwo

    private static let partOne: [RailGuide] = [
        RailGuide(
            id: "g_gauge",
            title: "The Story of Gauge",
            subtitle: "Why all rails are a certain distance apart",
            plateArt: "guide_gauge",
            paragraphs: [
                "Gauge is the distance between the inner faces of the two rails, and it is the first promise a railway makes: every wheel that rolls here will fit. The most common spacing in the world, four feet eight and a half inches, is called standard gauge, and its odd number has collected a century of legends. The honest answer is that early English wagonways were built roughly that wide because carts were roughly that wide, and once locomotives were running on it, changing meant rebuilding everything.",
                "Narrow gauge railways chose a smaller spacing on purpose. In mountains, forests and quarries, a narrow line could curve twice as sharply, climb on narrower shelves of rock, and be laid by smaller crews for less money. The trains were smaller too, which mattered little when the cargo was slate or logs. Broad gauges went the other way, promising steadier running and bigger boilers, and for thirty years one famous seven-foot gauge fought a polite war against standard gauge until practicality won.",
                "Model railways repeat the whole story in miniature. Every scale has its own agreed gauge so that any maker's wagon rolls on any maker's track, and the moment you place two rails on your tabletop you are honouring the same promise those first wagonways made: keep the spacing true, and everything that fits will roll.",
            ],
            facts: [
                "Standard gauge, used by about six in ten of the world's railways, is 1,435 mm across.",
                "Some countries deliberately chose a different gauge from their neighbours as a defence against invading trains.",
                "On a model table, gauge errors of even half a millimetre can drop a wheel between the rails.",
            ]),
        RailGuide(
            id: "g_switch",
            title: "How a Switch Works",
            subtitle: "The moving rails that choose a train's path",
            plateArt: "guide_switch",
            paragraphs: [
                "A switch, also called a turnout or a set of points, is the only place on a railway where the track itself makes a decision. Two tapered movable rails, the point blades, pivot together between two positions. Lying one way, they guide the wheels straight on; lying the other, they bend the train smoothly onto the diverging route. The blades are machined to a knife edge so the wheel crosses from one rail to the next without a jolt.",
                "Further along sits the frog, the crossing piece where one rail must pass through another. A wheel rolling over the frog briefly finds a gap under its flange, and check rails on the opposite side hold the wheelset firmly so it cannot wander into the wrong slot. Every derailment-free passage over a switch is a small mechanical miracle performed thousands of times a day.",
                "Direction matters. A train approaching from the single-track end is facing the points, and the blade position decides its future. A train arriving from either of the two branches is trailing through, and will be funnelled onto the single track no matter how the blades lie. On your tabletop the brass lever beside each switch throws the blades, and a train already past the frog no longer cares what you choose.",
            ],
            facts: [
                "Full-size point blades can be five metres long and are moved by levers, motors, or a signalman's full body weight.",
                "The frog earned its name because early railwaymen thought the casting looked like a sitting frog.",
                "Yard shunters may throw a hundred switches in a single shift.",
            ]),
        RailGuide(
            id: "g_signals",
            title: "Signals and the Block",
            subtitle: "How railways keep trains apart",
            plateArt: "guide_signals",
            paragraphs: [
                "Trains cannot swerve and take a long time to stop, so the whole craft of railway safety comes down to one rule: never let two trains occupy the same stretch of track at the same time. The line is divided into blocks, and a signal stands guard at the entrance to each. Only when the train ahead has cleared a block may the signal behind it show clear.",
                "The oldest signals were men with flags and lamps. Then came the semaphore, a pivoting wooden arm on a post: raised or lowered for danger and clear, its shape readable through rain and coal smoke long before colour-light signals arrived. At night a lamp shone through coloured spectacles bolted to the arm, so the same arm spoke a second language after dark.",
                "The signal box tied it all together. Long rows of heavy levers moved points and signals through miles of steel wire and rodding, and mechanical interlocking between the levers made contradictory settings physically impossible: a signalman simply could not clear two conflicting routes at once. On your table the signals by the line drop their arms as a train passes, remembering the block rule in miniature.",
            ],
            facts: [
                "A loaded freight train can need more than a mile to stop from full speed.",
                "Semaphore arms were angled so a broken wire would swing them to danger, never to clear.",
                "Some mechanical signal boxes still work today, levers, wires, bells and all.",
            ]),
        RailGuide(
            id: "g_steam",
            title: "Inside a Steam Locomotive",
            subtitle: "Fire, water, and the machine between them",
            plateArt: "guide_steam",
            paragraphs: [
                "A steam locomotive is a rolling kettle with ambitions. In the firebox at the back, coal burns fiercely; the hot gases rush forward through dozens of tubes running the length of the boiler, boiling the water that surrounds them. The steam gathers in the dome, the highest point, where it is driest, and waits for the driver's hand on the regulator.",
                "Opened, the regulator sends steam to the cylinders, where it shoves pistons back and forth. Connecting rods turn that shove into the spin of the driving wheels, and coupling rods share it along every driving axle. The exhausted steam then blasts up the chimney, and this blast is the secret of the whole machine: it drags the fire harder the faster the engine works, so a steam locomotive literally breathes in rhythm with its own effort. That is the chuff.",
                "Everything else serves the cycle. The tender carries coal and water; injectors force fresh water into the boiler against its own pressure; the safety valve lifts before the pressure grows dangerous; and the fireman's shovel keeps the whole performance fed. A good crew ran their engine like a shared instrument, reading the fire's colour and the boiler's sounds the way sailors read the sea.",
            ],
            facts: [
                "Express engines could evaporate over 100 litres of water every minute at full cry.",
                "The white plume above a chimney is mostly condensed water vapour; coal smoke is the grey and black.",
                "Drivers' whistles had personal styles that stationmasters could recognise from miles away.",
            ]),
        RailGuide(
            id: "g_diesel",
            title: "Diesel and Electric Days",
            subtitle: "How the modern engines took the line",
            plateArt: "guide_diesel",
            paragraphs: [
                "The diesel locomotive won the railways with a button. Where a steam engine needed hours of fire-raising before it could move, a diesel started like a truck and was ready in minutes, with one driver instead of a crew of two and no water towers, coal stages or ash pits to maintain. Most diesels are really diesel-electrics: the engine spins a generator, and electric motors on the axles do the actual pulling, which is why they haul so smoothly from a standstill.",
                "Electric locomotives go one step further and leave the power station at home. Drawing current from an overhead wire through the sprung frame of a pantograph, or from an electrified third rail, they carry no fuel at all: just motors, and as much power as the wire can feed them. That is why electrics conquered the mountains first, hauling loads up gradients that made steam engines gasp, then filling tunnels and cities where smoke was unwelcome.",
                "Steam did not vanish because it was unloved; it vanished because it was labour. Yet every preserved line that lights a fire on a Sunday morning proves the affection survived the arithmetic, and a model table is allowed to ignore the arithmetic entirely. Here, steam, diesel and electric share the rails in permanent, peaceful anachronism.",
            ],
            facts: [
                "A diesel-electric's engine never connects to the wheels directly; electricity is the gearbox.",
                "Pantographs press against the wire with roughly the force of a hand resting on a shoulder.",
                "Some electric locomotives return power to the wire when braking downhill.",
            ]),
    ]

    private static let partTwo: [RailGuide] = [
        RailGuide(
            id: "g_couplings",
            title: "Couplings and the Consist",
            subtitle: "How a train holds together",
            plateArt: "guide_couplings",
            paragraphs: [
                "A train is a negotiation between vehicles, and the coupling is the handshake. The oldest kind was three loose links of chain: simple, cheap, and terrible, because every start yanked the slack out wagon by wagon down the whole train like a cracked whip. Shunters slipped between moving wagons with a pole to drop the link over the hook, a job that demanded either great skill or great luck.",
                "The screw coupling tamed the snatch by letting crews wind the vehicles snugly together, and buffers, the sprung pads on each end, kept them politely apart. Elsewhere in the world the automatic knuckle coupler took over: two steel hands that clasp on contact, joining wagons with a shove instead of a shunter's arm. Modern passenger stock goes further still, joining brakes, electrics and doors in one motion.",
                "The order of vehicles is called the consist, and it is a craft of its own. Heavy wagons marshal near the engine so the snatch of starting does not run through light ones; the brake van rode at the tail with the guard watching for trouble; and the observation car, where one runs at all, goes last by unarguable tradition, because the whole point of it is the view of where you have been.",
            ],
            facts: [
                "A knuckle coupler joins on impact but needs a lifted pin to let go.",
                "Buffer heights are standardised so a coach from one country can visit another politely.",
                "The guard's van gave its crew a stove, a desk, and the best-earned tea on the railway.",
            ]),
        RailGuide(
            id: "g_timetable",
            title: "The Working Timetable",
            subtitle: "A railway's day, written down to the minute",
            plateArt: "guide_timetable",
            paragraphs: [
                "Passengers see the public timetable; the railway runs on a stricter document, the working timetable, where every train that turns a wheel has a number, a path, and a purpose, including the ones no passenger may board: empty stock movements, engineering trains, the small-hours mail. A path is a train's reserved slice of track and time, and pathing is the art of threading fast expresses between slow freights so that nobody has to wait longer than the arithmetic demands.",
                "Recovery time hides inside good timetables: a spare minute salted here and there so a late train can quietly become a punctual one. Dwell time, the pause at each station, is measured honestly, because doors, luggage and human beings refuse to hurry past a certain point. The finest timetables feel inevitable, as if the trains simply belong where they are.",
                "A tabletop railway deserves the same dignity. When your train pauses at a platform, that is dwell; when it sets off again on its endless circuit, it is keeping a path only you can see. Model railway clubs run whole operating sessions to a miniature clock, delivering imaginary goods to imaginary merchants on schedule, and report that it is among the deepest pleasures the hobby offers.",
            ],
            facts: [
                "Some famous expresses kept the same departure minute for over a century.",
                "Mail trains once sorted letters at speed, snatching mailbags from lineside nets without stopping.",
                "Model operating sessions often run a fast clock where one real minute counts as four.",
            ]),
        RailGuide(
            id: "g_freight",
            title: "The Goods Trade",
            subtitle: "What the wagons carried, and why it mattered",
            plateArt: "guide_freight",
            paragraphs: [
                "Passenger trains made railways famous, but goods trains made them rich. Coal filled more wagons than everything else combined, feeding home fires, gasworks and factory boilers. Around it rolled the whole economy in miniature: milk in churns and later in glass-lined tanks, running overnight so cities could have breakfast; fish vans packed with ice racing inland from the ports; cattle wagons, timber flats, and vans of everything a shop could shelve.",
                "Each cargo shaped its own wagon. Perishables demanded ventilation or ice bunkers; liquids took tanks; minerals took hoppers that emptied through their own floors; and anything too tall or too wide rode a well wagon, slung low between the wheels to duck under bridges. Reading an old goods train wagon by wagon is reading a region's whole economy rolling past at walking pace.",
                "The daily ritual was the pickup goods: a small engine ambling down the line, pausing at every siding to leave two wagons here and collect one there, its crew keeping accounts in chalk and memory. It was slow, sociable, unprofitable, and universally mourned when it vanished. On a model table it is the finest operation there is: every siding a customer, every wagon an errand.",
            ],
            facts: [
                "A single loaded coal train could heat a small town for a week.",
                "Ice vans were white to reflect sunlight, a livery chosen by thermometer.",
                "Chalk marks on wagon doors told crews a wagon's destination at a glance.",
            ]),
        RailGuide(
            id: "g_scenery",
            title: "The Art of the Baseboard",
            subtitle: "Making a table look like a world",
            plateArt: "guide_scenery",
            paragraphs: [
                "A model railway becomes a model world the moment something beside the track has no job to do. A cottage, a pond, three sheep in a crooked pen: none of them move a single wagon, and that is exactly the point. Scenery gives trains somewhere to be from and somewhere to be going, and the eye reads the whole table differently once it arrives.",
                "The old masters of the craft built landscape from whatever the house could spare: dyed sawdust for grass, lichen and rubberised horsehair for hedges, plaster bandage over chicken wire for hills, and a mirror laid flat for a pond, its edges hidden by reeds. Trees were twisted wire dipped in scatter; rock faces were carved cork bark painted with washes of grey and umber.",
                "Composition matters more than expense. A view blocker, a hill, a bridge or a wood, keeps the eye from taking in the whole circuit at once, so the train can leave one scene and genuinely arrive in another. Odd numbers group better than even; a path should lead somewhere, even if somewhere is behind a hill; and every model village needs at least one resident doing something faintly inexplicable, because every real village has one too.",
            ],
            facts: [
                "Scale trees are commonly built from twisted florist's wire and ground foam.",
                "A pocket mirror laid flat has served as a pond on tables for a hundred years.",
                "Some exhibition layouts carry more hours of scenery work than track work by ten to one.",
            ]),
        RailGuide(
            id: "g_history",
            title: "A Short History of Small Trains",
            subtitle: "From tinplate toys to a craft of patience",
            plateArt: "guide_history",
            paragraphs: [
                "The first toy trains were pull-along tin and wood, sold within a few years of the first real railways, because children demanded miniature versions of the marvel immediately. Clockwork followed, then live steam in miniature, spirit-fired brass boilers that occasionally set fire to the nursery rug, and by the turn of the century the tinplate makers were selling entire railway empires with stations, signals and staff.",
                "The hobby grew up when it moved from the floor to the table. Smaller scales let a whole landscape fit on a baseboard; electric motors gave fine control instead of a clockwork sprint; and makers agreed on standard scales and gauges so that one family's engines could visit another family's layout. Somewhere in those years the toy became a craft: adults were building rivet-counted locomotives and modelling particular stations on particular summer afternoons in particular decades.",
                "What survives through every era is the moment this app is built around: the lamp lit, the room quiet, a small train setting off around a world one pair of hands made. Whether the rails are tin on a nursery floor or hand-laid nickel silver on a museum-grade layout, the spell is identical, and it has not weakened in a hundred and fifty years.",
            ],
            facts: [
                "Early tinplate stations came with miniature porters, luggage, and a stationmaster mid-shout.",
                "Live steam models small enough for a tabletop still run on butane and distilled water today.",
                "The oldest model railway club in the world has met continuously since 1910.",
            ]),
    ]
}
