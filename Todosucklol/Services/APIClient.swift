import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .noData: return "Нет данных"
        case .decodingError: return "Ошибка обработки данных"
        case .serverError(let code): return "Ошибка сервера: \(code)"
        case .networkError(let error): return error.localizedDescription
        }
    }
}

class APIClient {
    static let shared = APIClient()
    
    private let baseURL = "http://localhost:8080/api/task"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        self.session = URLSession(configuration: .default)
        
        self.decoder = JSONDecoder()
        
        // ✅ Формат даты из API: "2026-03-07T19:06:47.836541"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            let simpleFormatter = DateFormatter()
            simpleFormatter.locale = Locale(identifier: "en_US_POSIX")
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = simpleFormatter.date(from: dateString) {
                return date
            }
            
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - GET запросы
    
    func fetchTasks() async throws -> [TaskItem] {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode([TaskItem].self, from: data)
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Raw response: \(jsonString)")
            }
            print("❌ Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    func fetchTask(by id: UUID) async throws -> TaskItem {
        guard let url = URL(string: "\(baseURL)/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode(TaskItem.self, from: data)
    }
    
    // MARK: - POST запросы
    
    func createTask(_ request: CreateTaskRequest) async throws -> TaskItem {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(TaskItem.self, from: data)
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Raw response: \(jsonString)")
            }
            print("❌ Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    // MARK: - PUT запросы
    
    func updateTask(id: UUID, _ request: CreateTaskRequest) async throws -> TaskItem {
        guard let url = URL(string: "\(baseURL)/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode(TaskItem.self, from: data)
    }
    
    // MARK: - DELETE запросы
    
    func deleteTask(id: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Комментарии
    
    /// Добавить комментарий к задаче
    /// POST /api/task/{taskId}/comment
    func addComment(to taskId: UUID, _ request: CreateCommentRequest) async throws -> Comment {
        guard let url = URL(string: "\(baseURL)/\(taskId.uuidString)/comment") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            // ✅ Возвращаем Comment (совместим с массивом comments)
            return try decoder.decode(Comment.self, from: data)
        } catch {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Raw response: \(jsonString)")
            }
            print("❌ Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    /// Удалить комментарий
    /// DELETE /api/task/{taskId}/comment/{commentId}
    func deleteComment(_ commentId: UUID, from taskId: UUID) async throws {
        guard let url = URL(string: "\(baseURL)/\(taskId.uuidString)/comment/\(commentId.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        
        let (_, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}
