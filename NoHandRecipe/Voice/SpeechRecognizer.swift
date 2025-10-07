import Foundation
import Speech
import AVFoundation

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))

    func requestAuthorization() async throws {
        try await withCheckedThrowingContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized: cont.resume()
                default: cont.resume(throwing: NSError(domain: "speech", code: 1))
                }
            }
        }
    }

    func start() throws {
        transcript = ""
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "speech", code: 2) }
        request.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
            self?.request?.append(buf)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let t = result?.bestTranscription.formattedString {
                DispatchQueue.main.async { self?.transcript = t }
            }
            if error != nil || (result?.isFinal ?? false) {
                self?.stop()
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
    }
}
