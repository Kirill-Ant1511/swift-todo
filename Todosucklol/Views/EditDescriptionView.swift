import SwiftUI

struct EditDescriptionView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var description: String
    @State private var isLoading = false
    
    init(task: TaskItem, viewModel: TaskViewModel) {
        self.task = task
        self.viewModel = viewModel
        self._description = State(initialValue: task.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 180)
                        .padding(4)
                        .disabled(isLoading)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Описание")
            .disabled(isLoading)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView("Сохранение...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        save()
                    }
                    .disabled(description.isEmpty || isLoading)
                    .foregroundColor(description.isEmpty || isLoading ? .gray : .blue)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .disabled(isLoading)
                }
            }
        }
    }
    
    private func save() {
        isLoading = true
        
        let updatedTask = TaskItem(
            id: task.id,
            createdAt: task.createdAt,
            title: task.title,
            description: description.isEmpty ? nil : description,
            ownerId: task.ownerId,
            ownerName: task.ownerName,
            performBy: task.performBy,
            isDone: task.isDone,
            comments: task.comments
        )
        
        viewModel.updateTask(updatedTask)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    EditDescriptionView(
        task: TaskItem(
            id: UUID(),
            createdAt: Date(),
            title: "Test",
            description: "Test Description",
            ownerId: UUID(),
            ownerName: nil,
            performBy: nil,
            isDone: false,
            comments: []
        ),
        viewModel: TaskViewModel()
    )
}
