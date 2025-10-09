import AVFoundation

final class AVSpeechTTSService: NSObject, TTSService, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    func speak(_ text: String) {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }

        // 他音源と共存（必要なら .playback に変える）
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let uttr = AVSpeechUtterance(string: s)
        uttr.voice = AVSpeechSynthesisVoice(language: "ja-JP") // 必要に応じて "en-US" など
        uttr.rate  = AVSpeechUtteranceDefaultSpeechRate // デフォルトで十分
        synth.speak(uttr)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
