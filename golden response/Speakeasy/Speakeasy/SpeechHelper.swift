import AVFoundation
import SwiftUI
internal import Combine

@MainActor
class SpeechHelper: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    // Singleton instance for global access
    static let shared = SpeechHelper()
    
    @Published var isSpeaking: Bool = false  // Observable property to track speaking state
    
    private let synthesizer: AVSpeechSynthesizer
    private var completionHandler: (() -> Void)?
    
    // Private initializer to enforce singleton usage
    private override init() {
        self.synthesizer = AVSpeechSynthesizer()
        super.init()
        self.synthesizer.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Speaks the provided text with the specified pace.
    /// - Parameters:
    ///   - text: The text to be spoken.
    ///   - pace: The rate at which the text is spoken (default is normal rate).
    ///   - completion: Optional closure called when speaking is finished.
    func speak(_ text: String, pace: Float = AVSpeechUtteranceDefaultSpeechRate, completion: (() -> Void)? = nil) {
        guard !text.isEmpty else { return }
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Configure audio session to allow playing while other audio sessions are active
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = pace.clamped(to: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        self.completionHandler = completion
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    /// Stops any ongoing speech.
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate Methods
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
            self?.completionHandler?()
            self?.completionHandler = nil
            
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.completionHandler = nil
            
            // Deactivate audio session
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Failed to deactivate audio session: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Float Extension for Clamping

extension Float {
    /// Clamps a floating-point value to the specified closed range.
    /// - Parameter limits: The closed range to which the value will be clamped.
    /// - Returns: The clamped value.
    func clamped(to limits: ClosedRange<Float>) -> Float {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
