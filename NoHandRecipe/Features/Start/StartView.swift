import SwiftUI

struct StartView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("No-Hand Recipe")
                .font(.largeTitle).bold()
            NavigationLink("Apple Intelligence と会話をはじめる") {
                AIChatView()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
