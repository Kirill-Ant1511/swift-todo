import SwiftUI
import Foundation
struct TaskRow: View {
    let task: TaskItem
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingEdit = false
    @State private var showingEditDescription = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    viewModel.toggleTaskDone(task)
                } label: {
                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isDone ? .green : .gray)
                        .scaleEffect(task.isDone ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: task.isDone)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body.bold())
                        .strikethrough(task.isDone, color: .gray)
                        .foregroundColor(task.isDone ? .gray : .primary)
                        .animation(.easeInOut(duration: 0.2), value: task.isDone)
                    
                    if let desc = task.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    if !task.comments.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption2)
                            Text("\(task.comments.count)")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(8)
                        .animation(.spring(response: 0.3), value: task.comments.count)
                    }
                }
                
                Spacer()
                
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let desc = task.description, !desc.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .padding(.top, 4)
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button {
                                showingEditDescription = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                    }
                    
                    Divider()
                    
                    CommentInputView(task: task)
                    
                    if !task.comments.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(task.comments) { comment in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue.opacity(0.7))
                                        .font(.system(size: 18))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(comment.content)
                                            .font(.caption)
                                        if let ownerName = comment.ownerName {
                                            Text(ownerName)
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .padding(.leading, 4)
                    } else {
                        Text("Нет комментариев — будьте первым!")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .sheet(isPresented: $showingEdit) {
            EditTaskView(task: task, viewModel: viewModel)
        }
        .sheet(isPresented: $showingEditDescription) {
            EditDescriptionView(task: task, viewModel: viewModel)
        }
    }
}
