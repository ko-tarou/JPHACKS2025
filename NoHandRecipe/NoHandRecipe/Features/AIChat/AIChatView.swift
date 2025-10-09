import SwiftUI

struct AIChatView: View {
    @State private var vm = AIChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("状態: \(vm.availabilityText)")
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
                    if vm.isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
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


