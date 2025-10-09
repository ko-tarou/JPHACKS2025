import SwiftUI

struct MessageRow: View {
    let message: Message
    let onSpeak: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
        
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                    .textSelection(.enabled)

                if message.role == .assistant, let onSpeak {
                    Button {
                        onSpeak()
                    } label: {
                        Label("読み上げ", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
    @ViewBuilder
    private func bubble(_ text: String, isUser: Bool = false) -> some View {
        Text(text)
            .padding(12)
            .background(isUser ? Color.blue : Color.gray.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(isUser ? .white : .primary)
    }
}
