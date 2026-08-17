import SwiftUI

struct DepotView: View {
    @EnvironmentObject var store: RailStore

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 156), spacing: 12)]
    }

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    rankCard
                    SectionHeader(title: "Engine Roster", subtitle: "Every locomotive the workshop has ever catalogued")
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(RailContent.locomotives) { loco in
                            NavigationLink(destination: LocoDetailView(loco: loco).environmentObject(store)) {
                                LocoCard(loco: loco, unlocked: store.isLocoUnlocked(loco), hasRun: store.stats.locosRun.contains(loco.id))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    SectionHeader(title: "Wagon Works", subtitle: "Rolling stock for every trade")
                        .padding(.top, 6)
                    VStack(spacing: 9) {
                        ForEach(RailContent.wagons) { wagon in
                            NavigationLink(destination: WagonDetailView(wagon: wagon).environmentObject(store)) {
                                WagonCard(wagon: wagon, unlocked: store.isWagonUnlocked(wagon))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private var rankCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.rank.name)
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    if let next = store.nextRank {
                        Text("\(next.xp - store.stats.xp) XP to \(next.name)")
                            .font(RailTheme.body(12))
                            .foregroundColor(RailTheme.inkFaint)
                    } else {
                        Text("The highest honour the table bestows")
                            .font(RailTheme.body(12))
                            .foregroundColor(RailTheme.inkFaint)
                    }
                }
                Spacer()
                ZStack {
                    ProgressRing(progress: store.rankProgress, size: 54, lineWidth: 6)
                    Text("\(store.stats.xp)")
                        .font(RailTheme.mono(11))
                        .foregroundColor(RailTheme.inkSoft)
                        .minimumScaleFactor(0.6)
                        .frame(width: 38)
                }
            }
            ProgressBar(progress: store.rankProgress)
            Text("Earn XP by running trains, calling at stations, completing orders and passing the exam. New engines, wagons and scenery join the shelves at every rank.")
                .font(RailTheme.body(12))
                .foregroundColor(RailTheme.inkFaint)
        }
        .railCard()
    }
}

struct LocoCard: View {
    let loco: Locomotive
    let unlocked: Bool
    let hasRun: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RailTheme.parchment)
                ArtImage(name: loco.plateArt)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .opacity(unlocked ? 1 : 0.35)
                if !unlocked {
                    RIcon(kind: .lock, size: 22, color: RailTheme.inkSoft)
                }
            }
            .frame(height: 108)
            .clipped()
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(loco.name)
                        .font(RailTheme.heading(15))
                        .foregroundColor(RailTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if hasRun {
                        Circle().fill(RailTheme.pine).frame(width: 6, height: 6)
                    }
                }
                Text(loco.locoClass.label)
                    .font(RailTheme.body(11))
                    .foregroundColor(RailTheme.inkFaint)
                if !unlocked {
                    LockBadge(rankName: RailStore.ranks[loco.unlockRank].name)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RailTheme.paper)
                .shadow(color: RailTheme.cardShadow, radius: 5, x: 0, y: 2)
        )
    }
}

struct WagonCard: View {
    let wagon: WagonType
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 5)
                .fill(wagon.body)
                .frame(width: 44, height: 22)
                .overlay(RoundedRectangle(cornerRadius: 4).fill(wagon.roof).padding(5))
                .opacity(unlocked ? 1 : 0.35)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(wagon.name)
                        .font(RailTheme.heading(14))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    if !unlocked {
                        LockBadge(rankName: RailStore.ranks[wagon.unlockRank].name)
                    }
                }
                Text(wagon.note)
                    .font(RailTheme.body(12))
                    .foregroundColor(RailTheme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .railCard(padding: 12)
    }
}

struct WagonDetailView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let wagon: WagonType

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        ArtImage(name: "wagon_\(wagon.id)")
                            .frame(maxWidth: .infinity)
                            .frame(height: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(RailTheme.oakDark.opacity(0.4), lineWidth: 1.5)
                            )
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            RIcon(kind: .chevronRight, size: 15, color: RailTheme.cream)
                                .rotationEffect(.degrees(180))
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        .padding(12)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wagon.name)
                            .font(RailTheme.title(26))
                            .foregroundColor(RailTheme.ink)
                        Text(wagon.kind)
                            .font(RailTheme.body(14))
                            .foregroundColor(RailTheme.inkFaint)
                    }
                    if !store.isWagonUnlocked(wagon) {
                        HStack(spacing: 8) {
                            RIcon(kind: .lock, size: 15, color: RailTheme.brassDark)
                            Text("Joins the wagon works at the rank of \(RailStore.ranks[wagon.unlockRank].name).")
                                .font(RailTheme.body(13))
                                .foregroundColor(RailTheme.inkSoft)
                        }
                        .railCard(padding: 12)
                    }
                    RailDivider()
                    Text(wagon.note)
                        .font(RailTheme.serif(16))
                        .foregroundColor(RailTheme.ink)
                        .lineSpacing(5)
                    HStack(spacing: 8) {
                        RIcon(kind: .spanner, size: 15, color: RailTheme.pine)
                        Text("Couple it to any engine in the Trains panel on the Table tab.")
                            .font(RailTheme.body(13))
                            .foregroundColor(RailTheme.inkSoft)
                    }
                    .railCard(padding: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }
}

struct LocoDetailView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let loco: Locomotive

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        ArtImage(name: loco.plateArt)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(RailTheme.oakDark.opacity(0.4), lineWidth: 1.5)
                            )
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            RIcon(kind: .chevronRight, size: 15, color: RailTheme.cream)
                                .rotationEffect(.degrees(180))
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                        .padding(12)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loco.name)
                            .font(RailTheme.title(26))
                            .foregroundColor(RailTheme.ink)
                        Text("\(loco.workshopNumber) · \(loco.locoClass.label)")
                            .font(RailTheme.body(14))
                            .foregroundColor(RailTheme.inkFaint)
                        Text(loco.tagline)
                            .font(RailTheme.serif(15))
                            .italic()
                            .foregroundColor(RailTheme.inkSoft)
                            .padding(.top, 2)
                    }
                    HStack(spacing: 10) {
                        specChip(label: "Class", value: loco.locoClass.label)
                        specChip(label: "Top speed", value: speedLabel)
                        specChip(label: "Exhaust", value: smokeLabel)
                    }
                    if !store.isLocoUnlocked(loco) {
                        HStack(spacing: 8) {
                            RIcon(kind: .lock, size: 15, color: RailTheme.brassDark)
                            Text("Joins your depot at the rank of \(RailStore.ranks[loco.unlockRank].name).")
                                .font(RailTheme.body(13))
                                .foregroundColor(RailTheme.inkSoft)
                        }
                        .railCard(padding: 12)
                    }
                    RailDivider()
                    Text(loco.story)
                        .font(RailTheme.serif(16))
                        .foregroundColor(RailTheme.ink)
                        .lineSpacing(5)
                    HStack(spacing: 8) {
                        RIcon(kind: .flag, size: 15, color: RailTheme.pine)
                        Text("Best for: \(loco.bestFor)")
                            .font(RailTheme.body(13))
                            .foregroundColor(RailTheme.inkSoft)
                    }
                    .railCard(padding: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private var speedLabel: String {
        if loco.maxSpeed >= 2.5 { return "Express" }
        if loco.maxSpeed >= 2.1 { return "Fast" }
        if loco.maxSpeed >= 1.8 { return "Steady" }
        return "Gentle"
    }

    private var smokeLabel: String {
        switch loco.smoke {
        case .steam: return "Steam"
        case .diesel: return "Diesel"
        case .none: return "None"
        }
    }

    private func specChip(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(RailTheme.heading(13))
                .foregroundColor(RailTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(RailTheme.body(10))
                .foregroundColor(RailTheme.inkFaint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 11).fill(RailTheme.cream))
    }
}
