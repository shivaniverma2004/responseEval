import Foundation
import AVFoundation
import Speech
import SwiftUI
internal import Combine

@MainActor
class PronunciationEvaluator: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.defaultTaskHint = .confirmation
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            Task { @MainActor in
                switch authStatus {
                case .authorized:
                    break
                case .denied:
                    self.errorMessage = "Speech recognition authorization was denied."
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self.errorMessage = "Speech recognition authorization not determined."
                @unknown default:
                    self.errorMessage = "An unknown error occurred during authorization."
                }
            }
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        errorMessage = nil
        recognizedText = ""
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available at the moment."
            return
        }
        
        audioEngine = AVAudioEngine()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = request else {
            errorMessage = "Failed to create recognition request."
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        guard let inputNode = audioEngine?.inputNode else {
            errorMessage = "Audio engine has no input node."
            return
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    self.stopRecording()
                    return
                }
                
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0) // Ensure no taps are set before installing a new one
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        do {
            try audioEngine?.start()
            isRecording = true
        } catch {
            errorMessage = "Audio engine couldn't start: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
    }
    
    // MARK: - Pronunciation Evaluation
    
    func evaluatePronunciation(for targetWord: String) -> Double {
        let recognizedWord = recognizedText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let target = targetWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return calculateSimilarity(between: target, and: recognizedWord)
    }
    
    private func calculateSimilarity(between string1: String, and string2: String) -> Double {
        // If both strings are empty, return 1.0 (perfect match)
        if string1.isEmpty && string2.isEmpty {
            return 1.0
        }
        
        // Handle cases where one of the strings is empty
        if string1.isEmpty || string2.isEmpty {
            return 0.0
        }
        
        let distance = levenshteinDistance(string1, string2)
        let maxLength = max(string1.count, string2.count)
        return maxLength == 0 ? 1.0 : 1.0 - (Double(distance) / Double(maxLength))
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        let m = a.count
        let n = b.count
        
        // Handle cases where one of the strings is empty
        if m == 0 {
            return n
        }
        if n == 0 {
            return m
        }
        
        var dist = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dist[i][0] = i
        }
        
        for j in 0...n {
            dist[0][j] = j
        }
        
        // Use '<' instead of '...'
        for i in 1..<m + 1 {
            for j in 1..<n + 1 {
                if a[i - 1] == b[j - 1] {
                    dist[i][j] = dist[i - 1][j - 1]
                } else {
                    dist[i][j] = min(
                        dist[i - 1][j] + 1,     // Deletion
                        dist[i][j - 1] + 1,     // Insertion
                        dist[i - 1][j - 1] + 1  // Substitution
                    )
                }
            }
        }
        
        return dist[m][n]
    }
    
    func reset() {
        stopRecording()
        recognizedText = ""
        errorMessage = nil
    }
}
