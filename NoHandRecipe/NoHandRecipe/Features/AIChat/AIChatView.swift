import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("状態: \(stateText(vm.availability))")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            List {
                ForEach(vm.messages) { MessageRow(message: msg($0)).listRowSeparator(.hidden) }
            }.listStyle(.plain)

            Divider()
            HStack(spacing: 8) {
                TextField("メッセージを入力", text: $vm.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit { Task { await vm.send() } }

                Button { Task { await vm.send() } } label: {
                    vm.isSending ? AnyView(ProgressView()) : AnyView(Image(systemName: "paperplane.fill"))
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isSending || vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12).background(.ultraThinMaterial)
        }
        .navigationTitle("Apple Intelligence")
        .onAppear { vm.onAppear() }
        .alert("エラー", isPresented: .constant(vm.errorMessage != nil), actions: {
            Button("OK") { vm.errorMessage = nil }
        }, message: { Text(vm.errorMessage ?? "") })
    }

    private func msg(_ m: Message) -> Message { m } // ForEachのクロージャ簡略
    private func stateText(_ s: AIAvailabilityState) -> String {
        switch s {
        case .available: "利用可能"
        case .deviceNotEligible: "非対応端末"
        case .notEnabled: "設定で有効化して下さい"
        case .modelNotReady: "モデル準備中"
        case .simulator: "シミュレーター（不可）"
        case .other(let t): t
        }
    }
}
