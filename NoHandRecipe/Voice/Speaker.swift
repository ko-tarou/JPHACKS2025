import AVFoundation

final class Speaker {
    private let tts = AVSpeechSynthesizer()
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        tts.speak(u)
    }
    func stop() { tts.stopSpeaking(at: .immediate) }
}
