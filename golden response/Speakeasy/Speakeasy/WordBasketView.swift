//
//  WordBasketView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import CoreData

struct WordBasketView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordEntryEntity.addedAt, ascending: false)],
        animation: .snappy
    ) private var allWordEntries: FetchedResults<WordEntryEntity>
    private let coreData = CoreDataManager.shared
    @State private var selectedWord: WordEntryEntity?
    @State private var showWordDetail = false
    @State private var sortOption: SortOption = .latest
    @State private var wordPendingDeletion: WordEntryEntity?
    
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case score = "Score"
        case difficulty = "Difficulty"
    }
    
    private var wordEntries: [WordEntryEntity] {
        let words = Array(allWordEntries)
        
        switch sortOption {
        case .latest:
            return words.sorted { ($0.addedAt ?? Date()) > ($1.addedAt ?? Date()) }
        case .score:
            return words.sorted { $0.lastScore > $1.lastScore }
        case .difficulty:
            return words.sorted { $0.lastScore < $1.lastScore }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 760,
                maxWidthCompact: 640,
                horizontalSizeClass: horizontalSizeClass
            )

            ZStack {
                LinearGradient(
                    colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
                if wordEntries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 72))
                            .foregroundStyle(.secondary.opacity(0.6))
                        
                        Text("Word Basket is empty")
                            .font(.title2.bold())
                        
                        Text("Tap words in your reading to add them here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        GlassCard {
                            Picker("Sort", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.top, 12)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(wordEntries, id: \.id) { wordEntry in
                                    Button {
                                        selectedWord = wordEntry
                                        showWordDetail = true
                                    } label: {
                                        WordBasketRow(wordEntry: wordEntry)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            wordPendingDeletion = wordEntry
                                        } label: {
                                            Label("Remove Word", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                        }
                    }
                    .frame(maxWidth: contentWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle("Word Basket")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showWordDetail) {
            if let selectedWord = selectedWord {
                WordDetailView(wordEntry: selectedWord)
            }
        }
        .confirmationDialog(
            "Remove this word?",
            isPresented: Binding(
                get: { wordPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        wordPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove Word", role: .destructive) {
                if let wordPendingDeletion {
                    coreData.deleteWordEntry(wordPendingDeletion)
                }
                wordPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                wordPendingDeletion = nil
            }
        } message: {
            Text("This removes the word and its practice history from your basket.")
        }
    }

}

// MARK: - Word Basket Row

struct WordBasketRow: View {
    let wordEntry: WordEntryEntity
    
    var body: some View {
        GlassCard {
            ViewThatFits(in: .horizontal) {
                rowContent(horizontal: true)
                rowContent(horizontal: false)
            }
        }
    }

    private func rowContent(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                HStack(spacing: 16) {
                    wordSummary
                    Spacer()
                    scoreSummary
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        wordSummary
                        Spacer()
                        scoreSummary
                    }

                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var wordSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wordEntry.word?.capitalized ?? "")
                .font(.title3.bold())
                .foregroundStyle(SpeakEasyPalette.ink)
            
            if wordEntry.attempts > 0 {
                HStack(spacing: 8) {
                    Label("\(wordEntry.attempts) attempt\(wordEntry.attempts == 1 ? "" : "s")", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(SpeakEasyPalette.mutedInk)
                }
            }
        }
    }

    @ViewBuilder
    private var scoreSummary: some View {
        if wordEntry.lastScore > 0 {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("\(wordEntry.lastScore)%")
                        .font(.headline)
                        .foregroundStyle(SpeakEasyPalette.ink)
                }
            }
        }
    }
}

// MARK: - Word Detail View

struct WordDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var wordEntry: WordEntryEntity
    @StateObject private var backendService = BackendService.shared
    @StateObject private var coreData = CoreDataManager.shared
    @StateObject private var speechHelper = SpeechHelper.shared
    
    @State private var dictionaryResult: DictionaryResponse?
    @State private var isLoadingDictionary = false
    @State private var dictionaryError: String?
    @State private var hasLoadedDictionary = false
    @State private var isMeaningExpanded = false
    @State private var isHistoryExpanded = false
    @State private var showPronunciationPractice = false
    
    @State private var isSpeaking: Bool = false
    @State private var speechRate: Float = 0.5
    @State private var score: Int?
    @State private var feedback: String?
    
    private var word: String {
        wordEntry.word?.capitalized ?? ""
    }
    
    private var practiceAttempts: [PracticeAttemptEntity] {
        (wordEntry.practiceAttempts?.allObjects as? [PracticeAttemptEntity]) ?? []
            .sorted {
                ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast)
            }
    }

    private var displayedScore: Int? {
        if let score {
            return score
        }

        guard wordEntry.lastScore > 0 else { return nil }
        return Int(wordEntry.lastScore)
    }

    private var visiblePracticeAttempts: ArraySlice<PracticeAttemptEntity> {
        isHistoryExpanded ? practiceAttempts.prefix(practiceAttempts.count) : practiceAttempts.prefix(2)
    }

    private static let attemptTimestampFormatter: Date.FormatStyle =
        .dateTime
        .month(.abbreviated)
        .day()
        .hour()
        .minute()
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 760,
                maxWidthCompact: 640,
                horizontalSizeClass: horizontalSizeClass
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 18) {
                                detailHeaderSummary
                                Spacer()
                                detailHeaderScore
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                detailHeaderSummary
                                HStack {
                                    Spacer()
                                    detailHeaderScore
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(word). Word details")
                    .accessibilityValue(accessibilityScoreSummary)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(
                            icon: "waveform",
                            title: "Pronunciation",
                            subtitle: feedback ?? "Uses the same practice flow as selected words in the reader."
                        )

                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                compactActionButton(
                                    title: isSpeaking ? "Stop" : "Listen",
                                    icon: isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
                                    tint: .accentColor
                                ) {
                                    toggleSpeech()
                                }

                                compactActionButton(
                                    title: "Practice",
                                    icon: "mic.fill",
                                    tint: SpeakEasyPalette.ink
                                ) {
                                    stopSpeechIfNeeded()
                                    showPronunciationPractice = true
                                }
                            }

                            VStack(spacing: 10) {
                                compactActionButton(
                                    title: isSpeaking ? "Stop" : "Listen",
                                    icon: isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
                                    tint: .accentColor
                                ) {
                                    toggleSpeech()
                                }

                                compactActionButton(
                                    title: "Practice",
                                    icon: "mic.fill",
                                    tint: SpeakEasyPalette.ink
                                ) {
                                    stopSpeechIfNeeded()
                                    showPronunciationPractice = true
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Rate")
                                    .font(.caption.bold())
                                Spacer()
                                Text(speechRateLabel)
                                    .font(.caption)
                            }
                            .foregroundStyle(SpeakEasyPalette.mutedInk)

                            Slider(value: $speechRate, in: 0.3...0.7, step: 0.1)
                                .accessibilityLabel("Speech rate")
                                .accessibilityValue(speechRateLabel)
                        }
                    }
                }

                if isLoadingDictionary {
                    GlassCard {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Looking up meaning…")
                                .font(.subheadline)
                                .foregroundStyle(SpeakEasyPalette.mutedInk)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else if let dictionaryResult = dictionaryResult {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(
                                icon: "book.closed.fill",
                                title: "Meaning",
                                subtitle: isMeaningExpanded ? "Full dictionary details" : "A quick explanation first"
                            )

                            ForEach(Array(visibleDefinitions(from: dictionaryResult).enumerated()), id: \.offset) { _, definition in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(definition.partOfSpeech.capitalized)
                                        .font(.caption.bold())
                                        .foregroundStyle(SpeakEasyPalette.mutedInk)

                                    Text(definition.meaning)
                                        .font(.body)
                                        .foregroundStyle(SpeakEasyPalette.ink)
                                        .lineSpacing(3)
                                        .lineLimit(isMeaningExpanded ? nil : 3)

                                    if isMeaningExpanded, let example = definition.example {
                                        Text("\"\(example)\"")
                                            .font(.caption)
                                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                                            .italic()
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            if shouldShowMeaningToggle(for: dictionaryResult) {
                                Button {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                        isMeaningExpanded.toggle()
                                    }
                                } label: {
                                    Label(
                                        isMeaningExpanded ? "Show Less" : "View Full Meaning",
                                        systemImage: isMeaningExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill"
                                    )
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(isMeaningExpanded ? "Collapse the full dictionary meaning" : "Expand the full dictionary meaning")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if let error = dictionaryError {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dictionary")
                                .font(.headline)
                                .foregroundStyle(SpeakEasyPalette.ink)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(SpeakEasyPalette.mutedInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text("Meaning")
                                    .font(.headline)
                                    .foregroundStyle(SpeakEasyPalette.ink)
                            }

                            Text("Look up pronunciation guidance, definitions, and examples for this word.")
                                .font(.subheadline)
                                .foregroundStyle(SpeakEasyPalette.mutedInk)

                            actionButton(
                                title: "Get Meaning",
                                icon: "book.fill",
                                tint: .accentColor
                            ) {
                                loadDictionary()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if !practiceAttempts.isEmpty {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                sectionHeader(
                                    icon: "clock.arrow.circlepath",
                                    title: "Practice History",
                                    subtitle: "\(practiceAttempts.count) saved attempt\(practiceAttempts.count == 1 ? "" : "s")"
                                )

                                Spacer()

                                if practiceAttempts.count > 2 {
                                    Button {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                            isHistoryExpanded.toggle()
                                        }
                                } label: {
                                    Text(isHistoryExpanded ? "Less" : "More")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    .accessibilityLabel(isHistoryExpanded ? "Show less history" : "Show more history")
                                }
                            }

                            ForEach(Array(visiblePracticeAttempts.enumerated()), id: \.element.id) { index, attempt in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(index == 0 ? "Latest attempt" : "Attempt")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(SpeakEasyPalette.ink)

                                        if let timestamp = attempt.timestamp {
                                            Text(timestamp.formatted(Self.attemptTimestampFormatter))
                                                .font(.caption)
                                                .foregroundStyle(SpeakEasyPalette.mutedInk)
                                        }
                                    }

                                    Spacer()

                                    Text("\(attempt.score)%")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(scoreColor(for: Int(attempt.score)))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(scoreColor(for: Int(attempt.score)).opacity(0.14), in: Capsule())
                                }
                                .padding(.vertical, 6)

                                if attempt != visiblePracticeAttempts.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
                .frame(maxWidth: contentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Word Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            refreshWordEntry()
            if !hasLoadedDictionary && wordEntry.word != nil {
                hasLoadedDictionary = true
                loadDictionary()
            }
        }
        .onDisappear {
            stopAllAudio()
        }
        .sheet(
            isPresented: $showPronunciationPractice,
            onDismiss: refreshWordEntry
        ) {
            PronunciationPracticeView(word: wordEntry.word ?? "") { latestScore in
                score = latestScore
                feedback = feedbackText(for: latestScore)
                refreshWordEntry()
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var detailHeaderSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(word)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(SpeakEasyPalette.ink)

            if wordEntry.attempts > 0 {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        statPill(
                            text: "\(wordEntry.attempts) attempt\(wordEntry.attempts == 1 ? "" : "s")",
                            icon: "arrow.clockwise"
                        )
                        statPill(
                            text: "\(wordEntry.lastScore)% score",
                            icon: "star.fill"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        statPill(
                            text: "\(wordEntry.attempts) attempt\(wordEntry.attempts == 1 ? "" : "s")",
                            icon: "arrow.clockwise"
                        )
                        statPill(
                            text: "\(wordEntry.lastScore)% score",
                            icon: "star.fill"
                        )
                    }
                }
            }

            if let feedback = feedback {
                Text(feedback)
                    .font(.subheadline)
                    .foregroundStyle(SpeakEasyPalette.mutedInk)
                    .padding(.top, 2)
            } else if displayedScore == nil {
                Text("Record once to see your pronunciation score here.")
                    .font(.subheadline)
                    .foregroundStyle(SpeakEasyPalette.mutedInk)
                    .padding(.top, 2)
            }
        }
    }

    private var detailHeaderScore: some View {
        Group {
            if let displayedScore {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: 78, height: 78)
                    VStack(spacing: 1) {
                        Text("\(displayedScore)%")
                            .font(.headline.bold())
                            .foregroundStyle(SpeakEasyPalette.ink)
                        Text(score == nil ? "saved" : "latest")
                            .font(.caption2)
                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.68))
                        .frame(width: 78, height: 78)
                    Image(systemName: "waveform.badge.mic")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private var speechRateLabel: String {
        switch speechRate {
        case ..<0.4:
            return "Slow"
        case 0.4..<0.6:
            return "Natural"
        default:
            return "Fast"
        }
    }

    private func visibleDefinitions(from result: DictionaryResponse) -> [Definition] {
        isMeaningExpanded ? result.definitions : Array(result.definitions.prefix(1))
    }

    private func shouldShowMeaningToggle(for result: DictionaryResponse) -> Bool {
        guard let firstMeaning = result.definitions.first?.meaning else {
            return false
        }

        return result.definitions.count > 1 || firstMeaning.count > 130 || result.definitions.first?.example != nil
    }

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.68), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SpeakEasyPalette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SpeakEasyPalette.mutedInk)
            }
        }
    }

    private func statPill(text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(SpeakEasyPalette.mutedInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.56), in: Capsule())
    }

    private func actionButton(title: String, icon: String, tint: Color, filled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                filled
                    ? AnyShapeStyle(Color.red)
                    : AnyShapeStyle(Color.white.opacity(0.62)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .foregroundStyle(filled ? .white : tint)
        }
        .accessibilityLabel(title)
    }

    private func compactActionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(tint)
        }
        .accessibilityLabel(title)
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }
    
    private func toggleSpeech() {
        if isSpeaking {
            speechHelper.stop()
            isSpeaking = false
        } else {
            isSpeaking = true
            speechHelper.speak(wordEntry.word ?? "", pace: speechRate) {
                isSpeaking = false
            }
        }
    }
    
    private func stopSpeechIfNeeded() {
        if isSpeaking {
            speechHelper.stop()
            isSpeaking = false
        }
    }
    
    private func stopAllAudio() {
        stopSpeechIfNeeded()
    }

    private func refreshWordEntry() {
        wordEntry.managedObjectContext?.refresh(wordEntry, mergeChanges: true)
    }

    private func feedbackText(for score: Int) -> String {
        switch score {
        case 80...100:
            return "Excellent. Your latest attempt is saved."
        case 50..<80:
            return "Good progress. Your latest attempt is saved."
        default:
            return "Keep practicing. Your latest attempt is saved."
        }
    }

    private var accessibilityScoreSummary: String {
        if let displayedScore {
            return "\(wordEntry.attempts) attempts. Current score \(displayedScore) percent."
        }

        if wordEntry.attempts > 0 {
            return "\(wordEntry.attempts) attempts. No current score available."
        }

        return "No pronunciation attempts yet."
    }
    
    private func loadDictionary() {
        guard let word = wordEntry.word, !word.isEmpty else { return }
        
        isLoadingDictionary = true
        dictionaryError = nil
        
        Task {
            do {
                let result = try await backendService.lookupWord(word)
                await MainActor.run {
                    dictionaryResult = result
                    isLoadingDictionary = false
                }
            } catch {
                await MainActor.run {
                    dictionaryError = error.localizedDescription
                    isLoadingDictionary = false
                }
            }
        }
    }
}
