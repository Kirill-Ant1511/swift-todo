import SwiftUI

struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    @FocusState private var isTitleFocused: Bool
    
    private let currentUserId = UUID()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название задачи", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .focused($isTitleFocused)
                } header: {
                    Text("Задача")
                        .foregroundColor(.blue)
                }
                .onAppear {
                    isTitleFocused = true
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .padding(4)
                } header: {
                    Text("Описание")
                        .foregroundColor(.blue)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Новая задача")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : .blue)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func addTask() {
        guard !title.isEmpty else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        viewModel.createTask(title: title, description: description)
        
        dismiss()
    }
}

#Preview {
    AddTaskView(viewModel: TaskViewModel())
}
