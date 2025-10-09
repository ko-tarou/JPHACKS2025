import SwiftUI

struct MessageRow: View {
    let message: Message
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
                bubble(message.text, isUser: true)
            } else {
                bubble(message.text)
                Spacer(minLength: 40)
            }
        }
        .padding(.vertical, 4)
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
