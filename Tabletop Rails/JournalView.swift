import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: RailStore
    @State private var showReset = false
    @State private var showPrivacy = false

    private var awardColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 78), spacing: 12)]
    }

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "The Keeper's Journal", subtitle: "Everything the table remembers")
                    statsGrid
                    streakCard
                    SectionHeader(title: "Awards", subtitle: "\(store.stats.awards.count) of \(RailAwards.all.count) earned")
                    LazyVGrid(columns: awardColumns, spacing: 12) {
                        ForEach(RailAwards.all) { award in
                            NavigationLink(destination: AwardDetailView(award: award).environmentObject(store)) {
                                VStack(spacing: 5) {
                                    AwardEmblem(index: award.emblem, earned: store.stats.awards.contains(award.id), size: 56)
                                    Text(award.name)
                                        .font(RailTheme.body(10))
                                        .foregroundColor(RailTheme.inkSoft)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 26)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    SectionHeader(title: "Workshop Settings")
                    settingsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            RailWebPanel(urlString: "https://tabletoprails.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatChip(icon: .gauge, value: "\(Int(store.stats.distance))", label: "Sleepers run")
                StatChip(icon: .flag, value: "\(store.stats.stationStops)", label: "Station calls")
                StatChip(icon: .clock, value: minutesLabel, label: "Time running")
            }
            HStack(spacing: 10) {
                StatChip(icon: .spanner, value: "\(store.stats.piecesPlaced)", label: "Track laid")
                StatChip(icon: .leaf, value: "\(store.stats.sceneryPlaced)", label: "Scenery set")
                StatChip(icon: .depot, value: "\(store.stats.locosRun.count)", label: "Engines run")
            }
        }
    }

    private var minutesLabel: String {
        let mins = Int(store.stats.runSeconds / 60)
        if mins >= 60 { return "\(mins / 60)h \(mins % 60)m" }
        return "\(mins)m"
    }

    private var streakCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(RailTheme.brass.opacity(0.18)).frame(width: 52, height: 52)
                Text("\(store.currentDayStreak)")
                    .font(RailTheme.title(20))
                    .foregroundColor(RailTheme.brassDark)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(store.currentDayStreak == 1 ? "1 day at the table" : "\(store.currentDayStreak) days at the table")
                    .font(RailTheme.heading(15))
                    .foregroundColor(RailTheme.ink)
                Text("Best run of days: \(store.stats.bestDayStreak) · Orders complete: \(store.stats.ordersDone.count)")
                    .font(RailTheme.body(12))
                    .foregroundColor(RailTheme.inkFaint)
            }
            Spacer()
        }
        .railCard()
    }

    private var settingsCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Room lamp")
                        .font(RailTheme.body(14))
                        .foregroundColor(RailTheme.ink)
                    Text("Follow the real clock, or force day or evening")
                        .font(RailTheme.body(11))
                        .foregroundColor(RailTheme.inkFaint)
                }
                Spacer()
                Picker("", selection: Binding(
                    get: { store.lampMode },
                    set: { store.lampMode = $0; store.scheduleSave() })) {
                    Text("Clock").tag("auto")
                    Text("Day").tag("day")
                    Text("Dusk").tag("night")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 168)
            }
            RailDivider()
            Toggle(isOn: Binding(
                get: { store.reduceMotion },
                set: { store.reduceMotion = $0; store.scheduleSave() })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calm the animations")
                        .font(RailTheme.body(14))
                        .foregroundColor(RailTheme.ink)
                    Text("Slows the table's ambient redrawing")
                        .font(RailTheme.body(11))
                        .foregroundColor(RailTheme.inkFaint)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: RailTheme.pine))
            RailDivider()
            Button {
                showPrivacy = true
            } label: {
                HStack {
                    Text("Privacy")
                        .font(RailTheme.body(14))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    RIcon(kind: .chevronRight, size: 12, color: RailTheme.inkFaint)
                }
            }
            RailDivider()
            Button {
                showReset = true
            } label: {
                HStack {
                    Text("Clear the table and start again")
                        .font(RailTheme.body(14))
                        .foregroundColor(RailTheme.signalRed)
                    Spacer()
                }
            }
        }
        .railCard()
        .alert(isPresented: $showReset) {
            Alert(
                title: Text("Start the whole railway again?"),
                message: Text("Every board, train, order and award goes back in the box. There is no way to undo this."),
                primaryButton: .destructive(Text("Start again")) {
                    store.resetAll()
                },
                secondaryButton: .cancel())
        }
    }
}

struct AwardDetailView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let award: RailAward

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 18) {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .chevronRight, size: 15, color: RailTheme.inkSoft)
                            .rotationEffect(.degrees(180))
                            .padding(9)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                Spacer()
                AwardEmblem(index: award.emblem, earned: store.stats.awards.contains(award.id), size: 148)
                Text(award.name)
                    .font(RailTheme.title(24))
                    .foregroundColor(RailTheme.ink)
                Text(award.blurb)
                    .font(RailTheme.serif(16))
                    .foregroundColor(RailTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                let (fraction, text) = award.progress(store)
                VStack(spacing: 8) {
                    ProgressBar(progress: fraction, color: store.stats.awards.contains(award.id) ? RailTheme.pine : RailTheme.brass)
                    Text(store.stats.awards.contains(award.id) ? "Earned and mounted in the journal" : text)
                        .font(RailTheme.body(13))
                        .foregroundColor(RailTheme.inkFaint)
                }
                .padding(.horizontal, 44)
                Spacer()
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
