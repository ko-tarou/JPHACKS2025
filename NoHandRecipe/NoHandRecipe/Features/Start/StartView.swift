import SwiftUI

struct StartView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("No-Hand Recipe").font(.largeTitle).bold()
            NavigationLink {
                AIChatView()
            } label: {
                Text("Apple Intelligence")
                    .font(.headline)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .navigationTitle("Start")
    }
}
