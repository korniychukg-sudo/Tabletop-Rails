import SwiftUI

struct OrdersView: View {
    @EnvironmentObject var store: RailStore

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ForEach(RailOrderBook.chapters) { chapter in
                        chapterSection(chapter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "The Order Book", subtitle: "Commissions from the little world around the line")
            let done = store.stats.ordersDone.count
            let total = RailOrderBook.orders.count
            HStack(spacing: 12) {
                ProgressRing(progress: Double(done) / Double(total), size: 46, lineWidth: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(done) of \(total) orders complete")
                        .font(RailTheme.heading(15))
                        .foregroundColor(RailTheme.ink)
                    Text("Each order pays experience toward your next rank.")
                        .font(RailTheme.body(12))
                        .foregroundColor(RailTheme.inkFaint)
                }
            }
            .railCard(padding: 14)
        }
    }

    private func chapterSection(_ chapter: OrderChapter) -> some View {
        let orders = RailOrderBook.orders.filter { $0.chapter == chapter.id }
        let doneCount = orders.filter { store.stats.ordersDone.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                ArtImage(name: chapter.banner)
                    .frame(height: 92)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                LinearGradient(colors: [.clear, Color.black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.name)
                        .font(RailTheme.title(17))
                        .foregroundColor(.white)
                    Text(chapter.motto)
                        .font(RailTheme.serif(12))
                        .italic()
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(12)
            }
            .frame(height: 92)
            .overlay(
                Text("\(doneCount)/\(orders.count)")
                    .font(RailTheme.mono(12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .padding(10),
                alignment: .topTrailing)
            ForEach(orders) { order in
                NavigationLink(destination: OrderDetailView(order: order).environmentObject(store)) {
                    orderRow(order)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func orderRow(_ order: RailOrder) -> some View {
        let done = store.stats.ordersDone.contains(order.id)
        let ready = !done && order.satisfied(store)
        let fraction = order.fraction(store)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(done ? RailTheme.pine.opacity(0.14) : (ready ? RailTheme.brass.opacity(0.2) : RailTheme.ink.opacity(0.05)))
                    .frame(width: 40, height: 40)
                if done {
                    RIcon(kind: .check, size: 16, color: RailTheme.pine)
                } else if ready {
                    RIcon(kind: .star, size: 17, color: RailTheme.brassDark)
                } else {
                    Text("\(Int(fraction * 100))%")
                        .font(RailTheme.mono(10))
                        .foregroundColor(RailTheme.inkSoft)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(order.title)
                    .font(RailTheme.heading(15))
                    .foregroundColor(done ? RailTheme.inkFaint : RailTheme.ink)
                Text("From \(order.client) · \(order.rewardXP) XP")
                    .font(RailTheme.body(11))
                    .foregroundColor(RailTheme.inkFaint)
                if !done {
                    ProgressBar(progress: fraction, color: ready ? RailTheme.brass : RailTheme.pine.opacity(0.6), height: 5)
                        .padding(.top, 3)
                }
            }
            Spacer()
            RIcon(kind: .chevronRight, size: 13, color: RailTheme.inkFaint)
        }
        .railCard(padding: 13)
        .opacity(done ? 0.75 : 1)
    }
}

struct OrderDetailView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let order: RailOrder
    @State private var celebrate = false

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                        Text("\(order.rewardXP) XP")
                            .font(RailTheme.heading(13))
                            .foregroundColor(RailTheme.brassDark)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(RailTheme.brass.opacity(0.15)))
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(order.title)
                            .font(RailTheme.title(25))
                            .foregroundColor(RailTheme.ink)
                        Text("An order from \(order.client)")
                            .font(RailTheme.body(13))
                            .foregroundColor(RailTheme.inkFaint)
                    }
                    Text(order.brief)
                        .font(RailTheme.serif(16))
                        .foregroundColor(RailTheme.ink)
                        .lineSpacing(5)
                    RailDivider()
                    Text("What the order asks")
                        .font(RailTheme.heading(16))
                        .foregroundColor(RailTheme.ink)
                    VStack(spacing: 10) {
                        ForEach(order.reqs.indices, id: \.self) { idx in
                            let (fraction, text) = order.reqs[idx].progress(store)
                            HStack(spacing: 10) {
                                if fraction >= 1 {
                                    RIcon(kind: .check, size: 14, color: RailTheme.pine)
                                        .frame(width: 20)
                                } else {
                                    Circle()
                                        .stroke(RailTheme.inkFaint, lineWidth: 1.5)
                                        .frame(width: 13, height: 13)
                                        .frame(width: 20)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(text)
                                        .font(RailTheme.body(13))
                                        .foregroundColor(RailTheme.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                    ProgressBar(progress: fraction, color: fraction >= 1 ? RailTheme.pine : RailTheme.brass, height: 5)
                                }
                            }
                            .railCard(padding: 12)
                        }
                    }
                    if store.stats.ordersDone.contains(order.id) {
                        HStack(spacing: 8) {
                            RIcon(kind: .check, size: 16, color: RailTheme.pine)
                            Text("Order complete. The client is delighted.")
                                .font(RailTheme.heading(14))
                                .foregroundColor(RailTheme.pine)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(RailTheme.pine.opacity(0.1)))
                    } else if order.satisfied(store) {
                        Button {
                            store.completeOrder(order)
                            celebrate = true
                        } label: {
                            Text("Deliver the order")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: RailTheme.brassDark))
                    } else {
                        Text("Keep building and running — progress counts everything you do on any board.")
                            .font(RailTheme.body(12))
                            .foregroundColor(RailTheme.inkFaint)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
            if celebrate {
                ConfettiView(seed: UInt64(abs(order.id.hashValue % 1000)))
            }
        }
        .navigationBarHidden(true)
    }
}
