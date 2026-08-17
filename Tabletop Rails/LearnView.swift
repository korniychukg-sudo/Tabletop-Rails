import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: RailStore

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    SectionHeader(title: "The Modeller's Handbook", subtitle: "How real railways work, chapter by chapter")
                    quizCard
                    ForEach(RailGuides.all) { guide in
                        NavigationLink(destination: GuideDetailView(guide: guide).environmentObject(store)) {
                            guideRow(guide)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    NavigationLink(destination: GlossaryView().environmentObject(store)) {
                        glossaryCard
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private var quizCard: some View {
        NavigationLink(destination: QuizView().environmentObject(store)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(RailTheme.pineDeep).frame(width: 52, height: 52)
                    RIcon(kind: .ribbon, size: 26, color: RailTheme.brassLight)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("The Permanent Way Exam")
                        .font(RailTheme.heading(16))
                        .foregroundColor(RailTheme.ink)
                    Text(store.stats.quizBest > 0 ? "Best score \(store.stats.quizBest) of 10 · \(store.stats.quizRounds) sittings" : "Ten fresh questions every sitting")
                        .font(RailTheme.body(12))
                        .foregroundColor(RailTheme.inkFaint)
                }
                Spacer()
                RIcon(kind: .chevronRight, size: 14, color: RailTheme.inkFaint)
            }
            .railCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func guideRow(_ guide: RailGuide) -> some View {
        let read = store.stats.guidesRead.contains(guide.id)
        return HStack(spacing: 12) {
            ArtImage(name: guide.plateArt)
                .frame(width: 78, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(guide.title)
                    .font(RailTheme.heading(15))
                    .foregroundColor(RailTheme.ink)
                Text(guide.subtitle)
                    .font(RailTheme.body(12))
                    .foregroundColor(RailTheme.inkFaint)
                    .lineLimit(2)
                if read {
                    HStack(spacing: 4) {
                        RIcon(kind: .check, size: 10, color: RailTheme.pine)
                        Text("Read")
                            .font(RailTheme.body(10))
                            .foregroundColor(RailTheme.pine)
                    }
                }
            }
            Spacer()
            RIcon(kind: .chevronRight, size: 13, color: RailTheme.inkFaint)
        }
        .railCard(padding: 12)
    }

    private var glossaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(RailTheme.brass.opacity(0.2)).frame(width: 52, height: 52)
                RIcon(kind: .book, size: 24, color: RailTheme.brassDark)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Railway Glossary")
                    .font(RailTheme.heading(16))
                    .foregroundColor(RailTheme.ink)
                Text("\(RailGlossary.terms.count) terms from ballast to works number")
                    .font(RailTheme.body(12))
                    .foregroundColor(RailTheme.inkFaint)
            }
            Spacer()
            RIcon(kind: .chevronRight, size: 14, color: RailTheme.inkFaint)
        }
        .railCard()
    }
}

struct GuideDetailView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    let guide: RailGuide

    var body: some View {
        ZStack {
            PaperBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        ArtImage(name: guide.plateArt)
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
                        Text(guide.title)
                            .font(RailTheme.title(25))
                            .foregroundColor(RailTheme.ink)
                        Text(guide.subtitle)
                            .font(RailTheme.body(14))
                            .foregroundColor(RailTheme.inkFaint)
                    }
                    ForEach(guide.paragraphs.indices, id: \.self) { idx in
                        Text(guide.paragraphs[idx])
                            .font(RailTheme.serif(16))
                            .foregroundColor(RailTheme.ink)
                            .lineSpacing(5)
                    }
                    RailDivider()
                    Text("Worth remembering")
                        .font(RailTheme.heading(16))
                        .foregroundColor(RailTheme.ink)
                    VStack(spacing: 8) {
                        ForEach(guide.facts.indices, id: \.self) { idx in
                            HStack(alignment: .top, spacing: 10) {
                                Circle().fill(RailTheme.brass).frame(width: 6, height: 6).padding(.top, 6)
                                Text(guide.facts[idx])
                                    .font(RailTheme.body(14))
                                    .foregroundColor(RailTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .railCard(padding: 12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.recordGuideRead(guide.id)
        }
    }
}

struct GlossaryView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    @State private var search = ""

    var filtered: [GlossaryTerm] {
        let trimmed = search.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmed.isEmpty { return RailGlossary.terms }
        return RailGlossary.terms.filter { $0.term.lowercased().contains(trimmed) || $0.definition.lowercased().contains(trimmed) }
    }

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .chevronRight, size: 15, color: RailTheme.inkSoft)
                            .rotationEffect(.degrees(180))
                            .padding(9)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                    Text("Railway Glossary")
                        .font(RailTheme.title(20))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                TextField("Search terms", text: $search)
                    .font(RailTheme.body(15))
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 12).fill(RailTheme.paper))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RailTheme.ink.opacity(0.1), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                ScrollView {
                    VStack(spacing: 9) {
                        ForEach(filtered) { term in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(term.term)
                                    .font(RailTheme.heading(15))
                                    .foregroundColor(RailTheme.ink)
                                Text(term.definition)
                                    .font(RailTheme.body(13))
                                    .foregroundColor(RailTheme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .railCard(padding: 13)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 90)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct QuizView: View {
    @EnvironmentObject var store: RailStore
    @Environment(\.presentationMode) var presentationMode
    @State private var questions: [QuizQuestion] = []
    @State private var index = 0
    @State private var score = 0
    @State private var picked: Int?
    @State private var finished = false

    var body: some View {
        ZStack {
            PaperBackdrop()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        RIcon(kind: .close, size: 14, color: RailTheme.inkSoft)
                            .padding(9)
                            .background(Circle().fill(RailTheme.ink.opacity(0.07)))
                    }
                    Text("Permanent Way Exam")
                        .font(RailTheme.title(19))
                        .foregroundColor(RailTheme.ink)
                    Spacer()
                    if !finished && !questions.isEmpty {
                        Text("\(index + 1)/\(questions.count)")
                            .font(RailTheme.mono(13))
                            .foregroundColor(RailTheme.inkSoft)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                if finished {
                    resultView
                } else if questions.isEmpty {
                    Spacer()
                    Button {
                        startRound()
                    } label: {
                        Text("Begin the exam")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
                    Text("Ten questions drawn fresh from the handbook, the glossary and the depot ledger.")
                        .font(RailTheme.body(13))
                        .foregroundColor(RailTheme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 12)
                    Spacer()
                } else {
                    questionView
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func startRound() {
        questions = RailQuiz.makeRound()
        index = 0
        score = 0
        picked = nil
        finished = false
    }

    private var questionView: some View {
        let q = questions[index]
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ProgressBar(progress: Double(index) / Double(questions.count), color: RailTheme.pine, height: 6)
                Text(q.prompt)
                    .font(RailTheme.heading(17))
                    .foregroundColor(RailTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                ForEach(q.options.indices, id: \.self) { idx in
                    Button {
                        guard picked == nil else { return }
                        picked = idx
                        if idx == q.correctIndex {
                            score += 1
                            RailHaptics.success()
                        } else {
                            RailHaptics.warning()
                        }
                    } label: {
                        HStack {
                            Text(q.options[idx])
                                .font(RailTheme.body(14))
                                .foregroundColor(optionColor(idx, q: q))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if let picked = picked {
                                if idx == q.correctIndex {
                                    RIcon(kind: .check, size: 14, color: RailTheme.pine)
                                } else if idx == picked {
                                    RIcon(kind: .close, size: 12, color: RailTheme.signalRed)
                                }
                            }
                        }
                        .padding(13)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(optionBackground(idx, q: q))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(optionBorder(idx, q: q), lineWidth: 1.4)
                        )
                    }
                    .disabled(picked != nil)
                }
                if picked != nil {
                    Text(q.explanation)
                        .font(RailTheme.serif(14))
                        .foregroundColor(RailTheme.inkSoft)
                        .lineSpacing(4)
                        .padding(13)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 13).fill(RailTheme.brass.opacity(0.10)))
                    Button {
                        if index + 1 < questions.count {
                            index += 1
                            picked = nil
                        } else {
                            store.recordQuiz(score: score, of: questions.count)
                            finished = true
                        }
                    } label: {
                        Text(index + 1 < questions.count ? "Next question" : "See the result")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 60)
        }
    }

    private func optionColor(_ idx: Int, q: QuizQuestion) -> Color {
        guard picked != nil else { return RailTheme.ink }
        if idx == q.correctIndex { return RailTheme.pineDeep }
        return RailTheme.inkFaint
    }

    private func optionBackground(_ idx: Int, q: QuizQuestion) -> Color {
        guard let picked = picked else { return RailTheme.paper }
        if idx == q.correctIndex { return RailTheme.pine.opacity(0.10) }
        if idx == picked { return RailTheme.signalRed.opacity(0.08) }
        return RailTheme.paper
    }

    private func optionBorder(_ idx: Int, q: QuizQuestion) -> Color {
        guard let picked = picked else { return RailTheme.ink.opacity(0.08) }
        if idx == q.correctIndex { return RailTheme.pine.opacity(0.5) }
        if idx == picked { return RailTheme.signalRed.opacity(0.4) }
        return RailTheme.ink.opacity(0.05)
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                ProgressRing(progress: Double(score) / 10.0, size: 110, lineWidth: 11, color: score >= 7 ? RailTheme.pine : RailTheme.brass)
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(RailTheme.title(36))
                        .foregroundColor(RailTheme.ink)
                    Text("of 10")
                        .font(RailTheme.body(12))
                        .foregroundColor(RailTheme.inkFaint)
                }
            }
            Text(verdict)
                .font(RailTheme.serif(16))
                .foregroundColor(RailTheme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if score >= store.stats.quizBest && score > 0 {
                Text("A new personal best")
                    .font(RailTheme.heading(13))
                    .foregroundColor(RailTheme.brassDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(RailTheme.brass.opacity(0.15)))
            }
            Button {
                startRound()
            } label: {
                Text("Sit it again")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 60)
            Spacer()
        }
    }

    private var verdict: String {
        switch score {
        case 10: return "A perfect paper. The examiner shakes your hand and mutters about a job in the signal box."
        case 8...9: return "A fine pass. The permanent way is safe in your hands."
        case 6...7: return "A solid showing, with a chapter or two worth another read by lamplight."
        case 4...5: return "The examiner nods kindly and slides the handbook back across the desk."
        default: return "The wonderful thing about this exam is that the answers are all on the shelf behind you."
        }
    }
}
