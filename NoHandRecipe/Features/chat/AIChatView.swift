import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()

    var body: some View {
        VStack(spacing: 12) {
            if let last = vm.messages.last, last.role == .system {
                Text(last.text).font(.footnote).foregroundStyle(.secondary)
            }
            List(vm.messages) { msg in
                HStack(alignment: .top) {
                    Text(label(for: msg.role)).font(.caption).frame(width: 60, alignment: .leading)
                    Text(msg.text)
                }
            }
            if let err = vm.errorMessage { Text(err).foregroundStyle(.red) }

            Button {
                vm.toggleMic()
            } label: {
                ZStack {
                    Circle().fill(vm.isListening ? .red : .blue).frame(width: 72, height: 72)
                    Image(systemName: vm.isListening ? "stop.fill" : "mic.fill")
                        .font(.title).foregroundStyle(.white)
                }
            }
            .disabled(vm.isProcessing || vm.availability != .available)
            .padding(.bottom, 8)

            if vm.isProcessing { ProgressView("AIが考え中…") }
        }
        .navigationTitle("音声チャット")
        .onAppear { vm.onAppear() }
        .padding(.horizontal)
    }

    private func label(for role: Role) -> String {
        switch role { case .user: "You"; case .assistant: "AI"; case .system: "System" }
    }
}
