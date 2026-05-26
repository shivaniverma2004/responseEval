//
//  TextProcessingView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import AVFoundation
@preconcurrency import Vision

private struct IdentifiableString: Identifiable, Equatable {
    let id = UUID()
    let value: String
}

struct TextProcessingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let images: [UIImage]
    var projectImage: ProjectImageEntity?
    
    @StateObject private var coreData = CoreDataManager.shared
    @StateObject private var speechHelper = SpeechHelper.shared
    @StateObject private var backendService = BackendService.shared
    
    @State private var recognizedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    
    @State private var fontSize: CGFloat = 18
    @State private var letterSpacing: CGFloat = 0
    @State private var lineHeight: CGFloat = 1.5
    @State private var textAlignment: TextAlignment = .leading
    @State private var theme: Theme = .system
    
    @State private var speechRate: Float = 0.5
    @State private var isSpeaking: Bool = false
    
    @State private var selectedWord: String = ""
    @State private var showWordOptions: Bool = false
    @State private var selectedWordItem: IdentifiableString?
    
    @State private var showAIFeatures = false
    @State private var aiTask: AITask?
    @State private var aiResult: String?
    @State private var isLoadingAI = false
    @State private var showControls = false
    @State private var showReaderHero = true
    @State private var hasAttemptedAutoExtraction = false
    
    enum TextAlignment: String, CaseIterable {
        case leading = "Left"
        case center = "Center"
        case justified = "Justified"
    }
    
    enum Theme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        case highContrast = "High Contrast"
    }
    
    enum AITask: String, CaseIterable {
        case summarize = "Summarize"
        case simplify = "Simplify"
        case quiz = "Generate Quiz"
        case grammar = "Explain Grammar"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let contentWidth = SpeakEasyLayout.readableContentWidth(
                containerWidth: geometry.size.width,
                maxWidthRegular: 820,
                maxWidthCompact: 680,
                horizontalSizeClass: horizontalSizeClass
            )

            ZStack {
                themeBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isProcessing {
                        readerStatusView(
                            icon: "doc.text.viewfinder",
                            title: "Extracting Text",
                            message: "SpeakEasy is preparing a cleaner reading layout from your images.",
                            showsProgress: true
                        )
                    } else if !recognizedText.isEmpty {
                        VStack(spacing: 14) {
                            if showReaderHero {
                                readerHero
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            ReaderView(
                                text: $recognizedText,
                                fontSize: fontSize,
                                letterSpacing: letterSpacing,
                                lineHeight: lineHeight,
                                alignment: textAlignment,
                                theme: theme,
                                onWordTap: { word in
                                    selectedWord = word
                                    selectedWordItem = IdentifiableString(value: word)
                                    showWordOptions = true
                                }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            readerControlBar
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                    } else if let error = errorMessage {
                        readerStatusView(
                            icon: "exclamationmark.triangle.fill",
                            title: "Couldn’t Read This Page",
                            message: error,
                            tint: .orange,
                            buttonTitle: "Try Again",
                            buttonIcon: "arrow.clockwise",
                            action: performTextRecognition
                        )
                    } else {
                        readerStatusView(
                            icon: "sparkles.rectangle.stack",
                            title: "Preparing Your Reader",
                            message: "SpeakEasy starts extraction automatically so you can move straight into reading.",
                            showsProgress: true
                        )
                    }
                }
            }
        }
        .navigationTitle("Reader")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedWordItem) { item in
            WordOptionsPopup(word: item.value)
        }
        .sheet(isPresented: $showAIFeatures) {
            AIFeaturesView(text: recognizedText, task: $aiTask, result: $aiResult, isLoading: $isLoadingAI)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onDisappear {
            stopSpeechIfNeeded()
        }
        .onAppear {
            guard !hasAttemptedAutoExtraction else { return }
            hasAttemptedAutoExtraction = true

            // Always OCR from the UIImage(s) passed in — never trust cached `extractedText` alone.
            // Stale or wrongly-associated Core Data text (e.g. from an older bug) would otherwise keep showing.
            if images.isEmpty {
                if let projectImage = projectImage,
                   let text = projectImage.extractedText,
                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    recognizedText = text
                }
            } else {
                performTextRecognition()
            }
        }
    }

    private var readerHero: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reader")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SpeakEasyPalette.ink)
                    Text("Tap any word to hear it, save it, or practice it.")
                        .font(.subheadline)
                        .foregroundStyle(SpeakEasyPalette.mutedInk)
                }

                Spacer()

                HStack(spacing: 10) {
                    Text("\(recognizedText.split(whereSeparator: \.isNewline).count) lines")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SpeakEasyPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(readerButtonBackground, in: Capsule())

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            showReaderHero = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                            .frame(width: 26, height: 26)
                            .background(readerButtonBackground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hide reader summary")
                }
            }
        }
    }

    private var readerControlBar: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    formatButton
                    listenButton
                    aiButton
                }

                VStack(spacing: 12) {
                    formatButton
                    listenButton
                    aiButton
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if showControls {
                Divider()
                    .padding(.horizontal, 14)

                ScrollView {
                    VStack(spacing: 20) {
                        readerSliderRow(
                            title: "Font Size",
                            systemImage: "textformat.size",
                            valueLabel: "\(Int(fontSize))"
                        ) {
                            Slider(value: $fontSize, in: 14...30, step: 1)
                        }

                        readerSliderRow(
                            title: "Letter Spacing",
                            systemImage: "textformat.abc",
                            valueLabel: String(format: "%.1f", letterSpacing)
                        ) {
                            Slider(value: $letterSpacing, in: -2...5, step: 0.5)
                        }

                        readerSliderRow(
                            title: "Line Height",
                            systemImage: "text.linefirst.and.arrowtriangle",
                            valueLabel: String(format: "%.1f", lineHeight)
                        ) {
                            Slider(value: $lineHeight, in: 1...3, step: 0.1)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Alignment", systemImage: "text.alignleft")
                                .font(.subheadline.bold())
                                .foregroundStyle(SpeakEasyPalette.ink)
                            Picker("Alignment", selection: $textAlignment) {
                                ForEach(TextAlignment.allCases, id: \.self) { alignment in
                                    Text(alignment.rawValue).tag(alignment)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Theme", systemImage: "paintpalette")
                                .font(.subheadline.bold())
                                .foregroundStyle(SpeakEasyPalette.ink)
                            Picker("Theme", selection: $theme) {
                                ForEach(Theme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        readerSliderRow(
                            title: "Speech Rate",
                            systemImage: "gauge",
                            valueLabel: String(format: "%.1f", speechRate)
                        ) {
                            Slider(value: $speechRate, in: 0.3...0.7, step: 0.1)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(readerPanelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(readerPanelBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(resolvedTheme == .dark ? 0.24 : 0.08), radius: 20, y: 14)
    }

    private var formatButton: some View {
        readerIconButton(
            icon: "slider.horizontal.3",
            title: "Format",
            tint: .accentColor
        ) {
            withAnimation(.spring(response: 0.3)) {
                showControls.toggle()
            }
        }
    }

    private var listenButton: some View {
        readerIconButton(
            icon: isSpeaking ? "stop.fill" : "speaker.wave.2.fill",
            title: isSpeaking ? "Stop" : "Listen",
            tint: isSpeaking ? .red : .accentColor
        ) {
            toggleReadAloud()
        }
    }

    private var aiButton: some View {
        readerIconButton(
            icon: "sparkles",
            title: "AI",
            tint: .accentColor
        ) {
            showAIFeatures = true
        }
    }

    private func readerIconButton(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(readerButtonBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private var resolvedTheme: Theme {
        switch theme {
        case .system:
            return colorScheme == .dark ? .dark : .light
        default:
            return theme
        }
    }

    private var readerButtonBackground: Color {
        resolvedTheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.6)
    }

    private var readerPanelBackground: some ShapeStyle {
        resolvedTheme == .dark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(.regularMaterial)
    }

    private var readerPanelBorder: Color {
        resolvedTheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.58)
    }

    private func readerSliderRow<Control: View>(title: String, systemImage: String, valueLabel: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(SpeakEasyPalette.ink)
                Spacer()
                Text(valueLabel)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
            }
            control()
        }
    }

    @ViewBuilder
    private func readerStatusView(icon: String, title: String, message: String, tint: Color = .accentColor, showsProgress: Bool = false, buttonTitle: String? = nil, buttonIcon: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack {
            Spacer()
            GlassCard {
                VStack(spacing: 18) {
                    if showsProgress {
                        ProgressView()
                            .scaleEffect(1.15)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(tint)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundStyle(SpeakEasyPalette.ink)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(SpeakEasyPalette.mutedInk)
                            .multilineTextAlignment(.center)
                    }

                    if let buttonTitle, let action {
                        Button(action: action) {
                            Label(buttonTitle, systemImage: buttonIcon ?? "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: 420)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var themeBackground: Color {
        switch resolvedTheme {
        case .light:
            return SpeakEasyPalette.backgroundTop
        case .dark:
            return Color(red: 0.07, green: 0.09, blue: 0.12)
        case .system:
            return SpeakEasyPalette.backgroundBottom
        case .highContrast:
            return .white
        }
    }
    
    private func performTextRecognition() {
        recognizedText = ""
        isProcessing = true
        errorMessage = nil

        let imagesToProcess = images
        let projectImage = projectImage

        DispatchQueue.global(qos: .userInitiated).async {
            var combined = ""
            var firstVisionError: Error?

            for image in imagesToProcess {
                autoreleasepool {
                    guard let cgImage = image.cgImage else { return }
                    do {
                        let piece = try Self.recognizeTextSynchronously(from: cgImage)
                        if !piece.isEmpty {
                            if !combined.isEmpty { combined.append("\n") }
                            combined.append(piece)
                        }
                    } catch {
                        if firstVisionError == nil {
                            firstVisionError = error
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                if let error = firstVisionError {
                    self.errorMessage = "Text recognition error: \(error.localizedDescription)"
                    self.isProcessing = false
                    return
                }

                let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self.errorMessage = "No text found in images."
                } else {
                    self.recognizedText = combined
                    if let projectImage {
                        self.coreData.updateImageText(projectImage, text: combined)
                    }
                }
                self.isProcessing = false
            }
        }
    }

    /// Runs one Vision request per image so results stay aligned with the UIImage order and the request object is never reused across images.
    private static func recognizeTextSynchronously(from cgImage: CGImage) throws -> String {
        var lines: [String] = []
        var recognitionError: Error?

        let request = VNRecognizeTextRequest { request, error in
            if let error {
                recognitionError = error
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            for observation in observations {
                if let top = observation.topCandidates(1).first {
                    lines.append(top.string)
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        if let recognitionError {
            throw recognitionError
        }

        return lines.joined(separator: "\n")
    }
    
    private func toggleReadAloud() {
        if isSpeaking {
            speechHelper.stop()
            isSpeaking = false
        } else {
            isSpeaking = true
            speechHelper.speak(recognizedText, pace: speechRate) {
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
}

// MARK: - Reader View

struct ReaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    let fontSize: CGFloat
    let letterSpacing: CGFloat
    let lineHeight: CGFloat
    let alignment: TextProcessingView.TextAlignment
    let theme: TextProcessingView.Theme
    let onWordTap: (String) -> Void

    @State private var selectedWord = ""
    @State private var showWordOptions = false
    @State private var selectedWordItem: IdentifiableString?

    private var resolvedTheme: TextProcessingView.Theme {
        switch theme {
        case .system:
            return colorScheme == .dark ? .dark : .light
        default:
            return theme
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                TextViewWrapper(
                    text: $text,
                    fontSize: .constant(fontSize),
                    lineSpacing: .constant(lineHeight),
                    selectedWord: $selectedWord,
                    showWordOptions: $showWordOptions,
                    letterSpacing: letterSpacing,
                    alignment: alignment,
                    theme: theme,
                    onWordTap: { word in
                        selectedWord = word
                        selectedWordItem = IdentifiableString(value: word)
                        onWordTap(word)
                    }
                )
                .frame(
                    minHeight: geometry.size.height * 0.90
                )
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    resolvedTheme == .dark ? Color(red: 0.13, green: 0.16, blue: 0.19) : Color.white.opacity(0.86),
                                    resolvedTheme == .dark ? Color(red: 0.10, green: 0.12, blue: 0.15) : Color.white.opacity(0.62)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(resolvedTheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: .black.opacity(resolvedTheme == .dark ? 0.24 : 0.08), radius: 18, y: 10)
                .padding(.horizontal, 2)
                .padding(.bottom, 6)
                .textSelection(.enabled)
                .accessibilityLabel("Reader text")
                .accessibilityHint("Swipe through the extracted text. Double tap a word to open word actions.")
            }
        }
    }
}

// MARK: - AI Features View

struct AIFeaturesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let text: String
    @Binding var task: TextProcessingView.AITask?
    @Binding var result: String?
    @Binding var isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backendService = BackendService.shared

    private var isShowingResult: Bool {
        task != nil || result != nil || isLoading
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let contentWidth = SpeakEasyLayout.readableContentWidth(
                    containerWidth: geometry.size.width,
                    maxWidthRegular: 680,
                    maxWidthCompact: 560,
                    horizontalSizeClass: horizontalSizeClass
                )

                ZStack {
                    LinearGradient(
                        colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 20) {
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Processing...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let result = result {
                            ScrollView {
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        if let task = task {
                                            HStack {
                                                Image(systemName: iconForTask(task))
                                                    .foregroundStyle(Color.accentColor)
                                                Text(task.rawValue)
                                                    .font(.headline)
                                            }
                                        }
                                        Text(result)
                                            .font(.body)
                                            .foregroundStyle(SpeakEasyPalette.ink)
                                    }
                                }
                                .frame(maxWidth: contentWidth, alignment: .leading)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 24)
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 16) {
                                    GlassCard {
                                        VStack(spacing: 8) {
                                            Text("These features require an internet connection")
                                                .font(.subheadline)
                                                .foregroundStyle(SpeakEasyPalette.mutedInk)
                                                .multilineTextAlignment(.center)

                                            Text("Choose a tool to work with the text already extracted in the reader.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }

                                    VStack(spacing: 12) {
                                        ForEach(TextProcessingView.AITask.allCases, id: \.self) { aiTask in
                                            Button {
                                                performAITask(aiTask)
                                            } label: {
                                                GlassCard {
                                                    HStack {
                                                        Image(systemName: iconForTask(aiTask))
                                                            .font(.title3)
                                                            .foregroundStyle(Color.accentColor)
                                                        Text(aiTask.rawValue)
                                                            .font(.headline)
                                                            .foregroundStyle(SpeakEasyPalette.ink)
                                                        Spacer()
                                                        Image(systemName: "arrow.right")
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                            }
                                            .accessibilityLabel(aiTask.rawValue)
                                            .accessibilityHint("Runs \(aiTask.rawValue.lowercased()) on the current extracted text")
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
                    }
                }
            }
            .navigationTitle("AI Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isShowingResult {
                        Button {
                            resetToTaskList()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel("Back")
                        .accessibilityHint("Return to the list of AI tools")
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isShowingResult {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    private func performAITask(_ aiTask: TextProcessingView.AITask) {
        task = aiTask
        isLoading = true
        result = nil
        
        Task {
            do {
                let resultText: String
                switch aiTask {
                case .summarize:
                    resultText = try await backendService.summarizeText(text)
                case .simplify:
                    resultText = try await backendService.simplifyText(text)
                case .quiz:
                    resultText = try await backendService.generateQuiz(text)
                case .grammar:
                    resultText = try await backendService.explainGrammar(text)
                }
                
                await MainActor.run {
                    result = resultText
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    result = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func iconForTask(_ task: TextProcessingView.AITask) -> String {
        switch task {
        case .summarize: return "doc.text"
        case .simplify: return "text.bubble"
        case .quiz: return "questionmark.circle"
        case .grammar: return "text.book.closed"
        }
    }

    private func resetToTaskList() {
        task = nil
        result = nil
        isLoading = false
    }
}
