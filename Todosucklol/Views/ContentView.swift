import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                }
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.15), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Group {
                    if viewModel.isLoading && viewModel.tasks.isEmpty {
                        ProgressView("Загрузка задач...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.tasks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("Задач нет")
                                .font(.title2.bold())
                                .foregroundColor(.gray)
                            Text("Нажмите + чтобы добавить первую задачу")
                                .font(.body)
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(viewModel.tasks) { task in
                                TaskRow(task: task, viewModel: viewModel)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                    .listRowBackground(Color.clear)
                            }
                            .onDelete { indexSet in
                                viewModel.deleteTask(at: indexSet)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .contentMargins(.all, 0, for: .scrollContent)
                    }
                }
            }
            .navigationTitle("TodoSuck")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                for: .navigationBar
            )
            .overlay(
                Group {
                    if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Spacer()
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(8)
                                .padding()
                                .onTapGesture {
                                    viewModel.clearError()
                                }
                        }
                    }
                }
            )
            .overlay(
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .padding(.trailing, 20)
                .padding(.bottom, 16),
                alignment: .bottomTrailing
            )
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadTasks()
            }
            .refreshable {
                viewModel.loadTasks()
            }
        }
    }
}

#Preview {
    ContentView()
}
