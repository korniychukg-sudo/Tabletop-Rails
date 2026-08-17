import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: RailStore
    @State private var page = 0

    private let pages: [(art: String, title: String, text: String)] = [
        ("onboard_1", "A railway on your table", "Lay track piece by piece on a wooden baseboard: straights, curves, switches, bridges and buffer stops. Dress the world with cottages, pines, ponds and lamp posts until it feels lived in."),
        ("onboard_2", "Then bring it to life", "Couple engines to their wagons and let them run. Trains call at platforms, smoke drifts from chimneys, switches clunk under your finger, and when the evening comes the little windows light."),
        ("onboard_3", "A workshop that grows", "Fill orders from the order book, earn ranks that unlock new engines and scenery, pass the Permanent Way Exam, and keep it all in the keeper's journal. Everything stays on this device."),
    ]

    var body: some View {
        ZStack {
            PaperBackdrop(tone: RailTheme.cream)
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { idx in
                        VStack(spacing: 22) {
                            ArtImage(name: pages[idx].art)
                                .frame(maxWidth: 480)
                                .frame(height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(RailTheme.oakDark.opacity(0.35), lineWidth: 1.5)
                                )
                                .padding(.horizontal, 26)
                            VStack(spacing: 10) {
                                Text(pages[idx].title)
                                    .font(RailTheme.title(26))
                                    .foregroundColor(RailTheme.ink)
                                    .multilineTextAlignment(.center)
                                Text(pages[idx].text)
                                    .font(RailTheme.serif(16))
                                    .foregroundColor(RailTheme.inkSoft)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(5)
                                    .padding(.horizontal, 34)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 30)
                        .tag(idx)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { idx in
                        Capsule()
                            .fill(idx == page ? RailTheme.pine : RailTheme.ink.opacity(0.15))
                            .frame(width: idx == page ? 22 : 7, height: 7)
                            .animation(.easeOut(duration: 0.2), value: page)
                    }
                }
                .padding(.bottom, 18)
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        store.onboardingDone = true
                        store.scheduleSave()
                        RailHaptics.success()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "To the table")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 34)
                if page < pages.count - 1 {
                    Button {
                        store.onboardingDone = true
                        store.scheduleSave()
                    } label: {
                        Text("Skip")
                            .font(RailTheme.body(14))
                            .foregroundColor(RailTheme.inkFaint)
                    }
                    .padding(.top, 10)
                } else {
                    Color.clear.frame(height: 30)
                }
                Spacer(minLength: 20)
            }
        }
    }
}
