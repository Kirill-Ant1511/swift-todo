import SwiftUI

struct EditTaskView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var isLoading = false
    
    init(task: TaskItem, viewModel: TaskViewModel) {
        self.task = task
        self.viewModel = viewModel
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название задачи", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .disabled(isLoading)
                } header: {
                    Text("Задача")
                        .foregroundColor(.blue)
                }
                
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .padding(4)
                        .disabled(isLoading)
                } header: {
                    Text("Описание")
                        .foregroundColor(.blue)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Редактировать")
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
                    .disabled(title.isEmpty || isLoading)
                    .foregroundColor(title.isEmpty || isLoading ? .gray : .blue)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private func save() {
        guard !title.isEmpty else { return }
        
        isLoading = true
        
        let updatedTask = TaskItem(
            id: task.id,
            createdAt: task.createdAt,
            title: title,
            description: description.isEmpty ? nil : description,
            ownerId: task.ownerId,
            ownerName: task.ownerName,
            performBy: task.performBy,
            isDone: task.isDone,
            comments: task.comments
        )
        
        viewModel.updateTask(updatedTask)
        
        // Ждём обновления и закрываем
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    EditTaskView(
        task: TaskItem(
            id: UUID(),
            createdAt: Date(),
            title: "Test Task",
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
