import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received from server"
        case .decodingError: return "Failed to decode response"
        case .unauthorized: return "Unauthorized access (401)"
        case .serverError(let msg): return "Server error: \(msg)"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

protocol PetAPIService {
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void)
    func register(username: String, fullName: String, email: String, password: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void)
    func getMe(completion: @escaping (Result<User, NetworkError>) -> Void)
    func uploadAvatar(image: Data, completion: @escaping (Result<String, NetworkError>) -> Void)
    func fetchPets(completion: @escaping (Result<[Pet], NetworkError>) -> Void)
    func addPet(name: String, type: String, birthDate: Date?, completion: @escaping (Result<Pet, NetworkError>) -> Void)
    func editPet(id: String, name: String, type: String, birthDate: Date?, completion: @escaping (Result<Pet, NetworkError>) -> Void)
    func updatePet(id: String, isFed: Bool, completion: @escaping (Result<Pet, NetworkError>) -> Void)
    func deletePet(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void)
    func feedPet(id: String, amount: String, completion: @escaping (Result<Pet, NetworkError>) -> Void)
}

class NativeNetworkManager: PetAPIService {
    static let shared = NativeNetworkManager()
    private let baseURL = "http://localhost:8000"
    
    private var token: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) { return date }
            let standardFormatter = ISO8601DateFormatter()
            standardFormatter.formatOptions = [.withInternetDateTime]
            if let date = standardFormatter.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        })
        return decoder
    }()
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = self.token {
            request.setValue(token, forHTTPHeaderField: "api-key")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else { return }
        var request = createRequest(url: url, method: "POST")
        let body = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                do {
                    let response = try self.decoder.decode(AuthResponse.self, from: data)
                    self.token = response.token
                    DispatchQueue.main.async { completion(.success(response)) }
                } catch {
                    print("Login error: \(error)")
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    func register(username: String, fullName: String, email: String, password: String, completion: @escaping (Result<AuthResponse, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/register") else { return }
        var request = createRequest(url: url, method: "POST")
        let body = ["username": username, "full_name": fullName, "email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                do {
                    let response = try self.decoder.decode(AuthResponse.self, from: data)
                    self.token = response.token
                    DispatchQueue.main.async { completion(.success(response)) }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    func getMe(completion: @escaping (Result<User, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/me") else { return }
        let request = createRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if (response as? HTTPURLResponse)?.statusCode == 401 {
                completion(.failure(.unauthorized))
                return
            }
            if let data = data {
                do {
                    let user = try self.decoder.decode(User.self, from: data)
                    DispatchQueue.main.async { completion(.success(user)) }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }

    func logout() {
        self.token = nil
    }
    
    func uploadAvatar(image: Data, completion: @escaping (Result<String, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/upload_avatar") else { return }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = createRequest(url: url, method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(image)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let url = json["avatar_url"] as? String {
                DispatchQueue.main.async { completion(.success(url)) }
            } else {
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func editPet(id: String, name: String, type: String, birthDate: Date?, completion: @escaping (Result<Pet, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets/\(id)") else { return }
        var request = createRequest(url: url, method: "PUT")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var body: [String: Any] = ["name": name, "type": type]
        if let birthDate = birthDate {
            body["birth_date"] = formatter.string(from: birthDate)
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                do {
                    let pet = try self.decoder.decode(Pet.self, from: data)
                    DispatchQueue.main.async { completion(.success(pet)) }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    func fetchPets(completion: @escaping (Result<[Pet], NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let request = createRequest(url: url, method: "GET")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.unknown(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let pets = try self.decoder.decode([Pet].self, from: data)
                DispatchQueue.main.async { completion(.success(pets)) }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(.decodingError))
            }
        }.resume()
    }
    
    func addPet(name: String, type: String, birthDate: Date?, completion: @escaping (Result<Pet, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets") else { return }
        var request = createRequest(url: url, method: "POST")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var body: [String: Any] = ["name": name, "type": type]
        if let birthDate = birthDate {
            body["birth_date"] = formatter.string(from: birthDate)
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let pet = try self.decoder.decode(Pet.self, from: data)
                    DispatchQueue.main.async { completion(.success(pet)) }
                } catch {
                    print("Decoding error in addPet: \(error)")
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    func updatePet(id: String, isFed: Bool, completion: @escaping (Result<Pet, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets/\(id)") else { return }
        var request = createRequest(url: url, method: "PUT")
        let body: [String: Any] = ["is_fed": isFed]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                do {
                    let pet = try self.decoder.decode(Pet.self, from: data)
                    DispatchQueue.main.async { completion(.success(pet)) }
                } catch {
                    print("Decoding error in updatePet: \(error)")
                }
            }
        }.resume()
    }
    
    func deletePet(id: String, completion: @escaping (Result<Bool, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets/\(id)") else { return }
        let request = createRequest(url: url, method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            let success = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(.success(success)) }
        }.resume()
    }
    
    func feedPet(id: String, amount: String, completion: @escaping (Result<Pet, NetworkError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/pets/\(id)/feed?amount=\(amount)") else { return }
        let request = createRequest(url: url, method: "POST")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data = data {
                do {
                    let pet = try self.decoder.decode(Pet.self, from: data)
                    DispatchQueue.main.async { completion(.success(pet)) }
                } catch {
                    print("Decoding error in feedPet: \(error)")
                }
            }
        }.resume()
    }
}

/*
// --- Note: Alamofire Implementation ---
// You need to add Alamofire package via SPM first.
// Go to File -> Add Packages... and search for https://github.com/Alamofire/Alamofire

import Alamofire

class AlamofireManager: PetAPIService {
    static let shared = AlamofireManager()
    private let baseURL = "http://localhost:8000"
    private let headers: HTTPHeaders = ["api-key": "my_secret_token"]

    func fetchPets(completion: @escaping (Result<[Pet], NetworkError>) -> Void) {
        AF.request("\(baseURL)/pets", headers: headers)
            .validate()
            .responseDecodable(of: [Pet].self) { response in
                switch response.result {
                case .success(let pets):
                    completion(.success(pets))
                case .failure(let error):
                    if response.response?.statusCode == 401 {
                        completion(.failure(.unauthorized))
                    } else {
                        completion(.failure(.unknown(error)))
                    }
                }
            }
    }
    
    // Similarly implement addPet, updatePet, deletePet using AF.request
}
*/
