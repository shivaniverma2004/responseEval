//
//  PronunciationPracticeView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI
import AVFoundation
internal import Combine

struct PronunciationPracticeView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let word: String
    var onPracticeCompleted: ((Int) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var coreData = CoreDataManager.shared
    @StateObject private var speechHelper = SpeechHelper.shared
    @StateObject private var evaluator = PronunciationEvaluator()
    
    @State private var isSpeaking: Bool = false
    @State private var speechRate: Float = 0.5
    @State private var isRecording: Bool = false
    @State private var score: Int?
    @State private var feedback: String?
    
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
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            GlassCard {
                                VStack(spacing: 16) {
                                    Text(word.capitalized)
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                    
                                    if let score = score {
                                        HStack(spacing: 8) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                            Text("\(score)%")
                                                .font(.title2.bold())
                                        }
                                    }
                                    
                                    if let feedback = feedback {
                                        Text(feedback)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text("Listen first, then record yourself and compare your pronunciation.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }

                            GlassCard {
                                VStack(spacing: 16) {
                                    ViewThatFits(in: .horizontal) {
                                        HStack(spacing: 12) {
                                            speechButton
                                            recordingButton
                                        }

                                        VStack(spacing: 12) {
                                            speechButton
                                            recordingButton
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Speech Rate")
                                                .font(.caption.bold())
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(speechRateLabel)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Slider(value: $speechRate, in: 0.3...0.7, step: 0.1)
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
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onDisappear {
                stopAllAudio()
            }
        }
    }

    private var speechButton: some View {
        Button {
            toggleSpeech()
        } label: {
            HStack {
                Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                Text(isSpeaking ? "Stop" : "Hear Pronunciation")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.white)
        }
    }

    private var recordingButton: some View {
        Button {
            toggleRecording()
        } label: {
            HStack {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                Text(isRecording ? "Stop Recording" : "Practice Pronunciation")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRecording ? Color.red : Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .foregroundStyle(.primary)
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
    
    private func toggleSpeech() {
        if isSpeaking {
            speechHelper.stop()
            isSpeaking = false
        } else {
            stopRecordingIfNeeded()
            isSpeaking = true
            speechHelper.speak(word, pace: speechRate) {
                isSpeaking = false
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            evaluator.stopRecording()
            evaluatePronunciation()
            isRecording = false
        } else {
            stopSpeechIfNeeded()
            score = nil
            feedback = nil
            evaluator.reset()
            evaluator.startRecording()
            if evaluator.errorMessage == nil {
                isRecording = true
            } else {
                feedback = evaluator.errorMessage
            }
        }
    }
    
    private func evaluatePronunciation() {
        let accuracy = evaluator.evaluatePronunciation(for: word)
        let percentage = Int(accuracy * 100)
        score = percentage
        
        // Save the latest score for the word so detail screens and lists can reflect it.
        coreData.updateWordScore(word, score: percentage)
        onPracticeCompleted?(percentage)
        
        // Provide feedback
        switch accuracy {
        case 0.8...1.0:
            feedback = "Excellent! You've mastered this word."
        case 0.5..<0.8:
            feedback = "Good job! Keep practicing."
        default:
            feedback = "Keep trying! You'll get it."
        }
    }
    
    private func stopSpeechIfNeeded() {
        if isSpeaking {
            speechHelper.stop()
            isSpeaking = false
        }
    }
    
    private func stopRecordingIfNeeded() {
        if isRecording {
            evaluator.stopRecording()
            isRecording = false
        }
    }
    
    private func stopAllAudio() {
        stopSpeechIfNeeded()
        stopRecordingIfNeeded()
    }
}
