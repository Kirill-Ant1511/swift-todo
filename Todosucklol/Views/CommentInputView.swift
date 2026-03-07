import SwiftUI

struct CommentInputView: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    @State private var commentText: String = ""
    @FocusState private var isFocused: Bool
    @State private var isSending = false
    
    private let currentUserId = UUID()
    
    var body: some View {
        HStack(spacing: 10) {
            TextField("Комментарий...", text: $commentText)
                .textFieldStyle(.plain)
                .font(.caption)
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .focused($isFocused)
                .onSubmit { addComment() }
                .submitLabel(.send)
                .disabled(isSending)
            
            Button {
                addComment()
            } label: {
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.blue)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(commentText.isEmpty ? .gray.opacity(0.5) : .blue)
                        .scaleEffect(commentText.isEmpty ? 1 : 1.1)
                        .animation(.easeInOut(duration: 0.1), value: commentText.isEmpty)
                }
            }
            .buttonStyle(.plain)
            .disabled(commentText.isEmpty || isSending)
        }
        .padding(.vertical, 2)
    }
    
    private func addComment() {
        guard !commentText.isEmpty else { return }
        
        isSending = true
        let content = commentText
        commentText = ""  // Очищаем поле сразу
        
        Task {
            await viewModel.addCommentToTask(taskId: task.id, content: content)
            await MainActor.run {
                isSending = false
            }
        }
    }
}

#Preview {
    CommentInputView(
        task: TaskItem(
            id: UUID(),
            createdAt: Date(),
            title: "Test",
            description: nil,
            ownerId: UUID(),
            ownerName: nil,
            performBy: nil,
            isDone: false,
            comments: []
        ),
        viewModel: TaskViewModel()
    )
}
