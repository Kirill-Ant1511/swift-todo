import Foundation
import SwiftUI
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    private let currentUserId = UUID()
    
    // MARK: - Загрузка задач
    
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedTasks = try await apiClient.fetchTasks()
                self.tasks = fetchedTasks.sorted { $0.createdAt > $1.createdAt }
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Error loading tasks: \(error)")
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Удаление задачи
    
    func deleteTask(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let task = tasks[index]
        
        Task {
            do {
                try await apiClient.deleteTask(id: task.id)
                withAnimation(.spring(response: 0.3)) {
                    self.tasks.remove(at: index)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.loadTasks()
            }
        }
    }
    
    // MARK: - Создание задачи
    
    func createTask(title: String, description: String?) {
        Task {
            do {
                let request = CreateTaskRequest(
                    title: title,
                    description: description?.isEmpty == true ? nil : description,
                    ownerId: currentUserId
                )
                let newTask = try await apiClient.createTask(request)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.tasks.insert(newTask, at: 0)
                }
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Error creating task: \(error)")
            }
        }
    }
    
    // MARK: - Обновление задачи
    
    func updateTask(_ task: TaskItem) {
        Task {
            do {
                let request = CreateTaskRequest(
                    title: task.title,
                    description: task.description,
                    ownerId: task.ownerId
                )
                let updatedTask = try await apiClient.updateTask(id: task.id, request)
                
                if let index = self.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    self.tasks[index] = updatedTask
                }
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Error updating task: \(error)")
            }
        }
    }
    
    // MARK: - Переключение статуса задачи
    
    func toggleTaskDone(_ task: TaskItem) {
        // Создаём обновлённую задачу
        let updatedTask = TaskItem(
            id: task.id,
            createdAt: task.createdAt,
            title: task.title,
            description: task.description,
            ownerId: task.ownerId,
            ownerName: task.ownerName,
            performBy: task.performBy,
            isDone: !task.isDone,  // Инвертируем статус
            comments: task.comments
        )
        
        // Обновляем локально
        if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.tasks[index] = updatedTask
            }
        }
        
        // Отправляем на сервер
        Task {
            do {
                let request = CreateTaskRequest(
                    title: updatedTask.title,
                    description: updatedTask.description,
                    ownerId: updatedTask.ownerId
                )
                let serverTask = try await apiClient.updateTask(id: updatedTask.id, request)
                
                // Обновляем данными с сервера
                if let index = self.tasks.firstIndex(where: { $0.id == serverTask.id }) {
                    self.tasks[index] = serverTask
                }
            } catch {
                print("❌ Error updating task status: \(error)")
                // Восстанавливаем состояние при ошибке
                self.loadTasks()
            }
        }
    }
    
    // MARK: - Очистка ошибки
    
    func clearError() {
        errorMessage = nil
    }
}
