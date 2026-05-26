//
//  WordOptionsPopup.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
internal import Combine

struct WordOptionsPopup: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let word: String
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var coreData = CoreDataManager.shared
    @StateObject private var backendService = BackendService.shared
    @StateObject private var speechHelper = SpeechHelper.shared
    
    @State private var showPronunciationPractice = false
    @State private var dictionaryResult: DictionaryResponse?
    @State private var isLoadingDictionary = false
    @State private var dictionaryError: String?
    @State private var isWordInBasket: Bool = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let contentWidth = SpeakEasyLayout.readableContentWidth(
                    containerWidth: geometry.size.width,
                    maxWidthRegular: 680,
                    maxWidthCompact: 560,
                    horizontalSizeClass: horizontalSizeClass
                )

                ScrollView {
                    VStack(spacing: 24) {
                        GlassCard {
                            VStack(spacing: 10) {
                                Text("WORD")
                                    .font(.caption.weight(.bold))
                                    .tracking(1.2)
                                    .foregroundStyle(SpeakEasyPalette.mutedInk)
                                Text(word.capitalized)
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(SpeakEasyPalette.ink)
                                    .multilineTextAlignment(.center)
                                Text("Tap below to hear it, save it, or open practice.")
                                    .font(.subheadline)
                                    .foregroundStyle(SpeakEasyPalette.mutedInk)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        GlassCard {
                            VStack(spacing: 12) {
                                popupActionButton(
                                    title: "Get Meaning",
                                    icon: "book.fill",
                                    tint: .accentColor,
                                    trailingProgress: isLoadingDictionary
                                ) {
                                    loadDictionary()
                                }
                                .disabled(isLoadingDictionary)

                                popupActionButton(
                                    title: "Hear Pronunciation",
                                    icon: "speaker.wave.2.fill",
                                    tint: .accentColor
                                ) {
                                    speechHelper.speak(word)
                                }

                                popupActionButton(
                                    title: "Practice Pronunciation",
                                    icon: "mic.fill",
                                    tint: SpeakEasyPalette.ink
                                ) {
                                    showPronunciationPractice = true
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        if !isWordInBasket {
                                            _ = coreData.addWordToBasket(word)
                                            isWordInBasket = true
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: isWordInBasket ? "checkmark.circle.fill" : "basket.fill")
                                        Text(isWordInBasket ? "Added to Basket" : "Add to Word Basket")
                                        Spacer()
                                        if isWordInBasket {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        isWordInBasket
                                            ? Color.green.opacity(0.18)
                                            : Color.white.opacity(0.62),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    )
                                    .foregroundStyle(isWordInBasket ? .green : SpeakEasyPalette.ink)
                                }
                            }
                        }

                        if let dictionaryResult = dictionaryResult {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "book.closed.fill")
                                            .foregroundStyle(Color.accentColor)
                                        Text("Meaning")
                                            .font(.headline)
                                            .foregroundStyle(SpeakEasyPalette.ink)
                                    }

                                    ForEach(Array(dictionaryResult.definitions.enumerated()), id: \.offset) { index, definition in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(definition.partOfSpeech.capitalized)
                                                .font(.caption.bold())
                                                .foregroundStyle(SpeakEasyPalette.mutedInk)
                                                .textCase(.uppercase)

                                            Text(definition.meaning)
                                                .font(.body)
                                                .foregroundStyle(SpeakEasyPalette.ink)

                                            if let example = definition.example {
                                                Text("\"\(example)\"")
                                                    .font(.subheadline)
                                                    .foregroundStyle(SpeakEasyPalette.mutedInk)
                                                    .italic()
                                                    .padding(.leading, 8)
                                            }
                                        }
                                        .padding(.vertical, 8)

                                        if index < dictionaryResult.definitions.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        } else if let error = dictionaryError {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.orange)
                                        Text("Dictionary")
                                            .font(.headline)
                                            .foregroundStyle(SpeakEasyPalette.ink)
                                    }
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundStyle(SpeakEasyPalette.mutedInk)
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
                .background(
                    LinearGradient(
                        colors: [SpeakEasyPalette.backgroundTop, SpeakEasyPalette.backgroundBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .navigationTitle("Word Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPronunciationPractice) {
                PronunciationPracticeView(word: word)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                checkBasketStatus()
            }
        }
    }

    private func popupActionButton(title: String, icon: String, tint: Color, trailingProgress: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                if trailingProgress {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(tint)
        }
    }
    
    private func checkBasketStatus() {
        let words = coreData.fetchWordEntries()
        isWordInBasket = words.contains { $0.word?.lowercased() == word.lowercased() }
    }
    
    private func loadDictionary() {
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
