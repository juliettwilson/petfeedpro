import Foundation
import SwiftUI
import Combine

class PetViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var user: User? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    
    @Published var searchText = ""
    @Published var selectedFilterType: PetType? = nil
    
    var filteredPets: [Pet] {
        pets.filter { pet in
            let matchesSearch = searchText.isEmpty || pet.name.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilterType == nil || pet.type == selectedFilterType?.rawValue
            return matchesSearch && matchesFilter
        }
    }
    
    private let apiService: PetAPIService = NativeNetworkManager.shared
    
    init() {
        checkAuth()
    }
    
    func checkAuth() {
        isLoading = true
        apiService.getMe { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let user):
                    self.user = user
                    self.isAuthenticated = true
                    self.loadPets()
                case .failure:
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    func login(username: String, password: String) {
        isLoading = true
        apiService.login(username: username, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.user = response.user
                    self.isAuthenticated = true
                    self.loadPets()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func register(username: String, fullName: String, email: String, password: String) {
        isLoading = true
        apiService.register(username: username, fullName: fullName, email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.user = response.user
                    self.isAuthenticated = true
                    self.loadPets()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func logout() {
        NativeNetworkManager.shared.logout()
        self.user = nil
        self.isAuthenticated = false
        self.pets = []
    }
    
    func loadPets() {
        guard isAuthenticated else { return }
        isLoading = true
        errorMessage = nil
        
        apiService.fetchPets { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let pets):
                    self.pets = pets
                case .failure(let error):
                    if case .unauthorized = error {
                        self.logout()
                    }
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addPet(name: String, type: PetType, birthDate: Date?) {
        apiService.addPet(name: name, type: type.rawValue, birthDate: birthDate) { result in
            DispatchQueue.main.async {
                if case .success(let newPet) = result {
                    self.pets.append(newPet)
                }
            }
        }
    }
    
    func editPet(pet: Pet, newName: String, newType: PetType, newBirthDate: Date?) {
        apiService.editPet(id: pet.id, name: newName, type: newType.rawValue, birthDate: newBirthDate) { result in
            DispatchQueue.main.async {
                if case .success(let updatedPet) = result {
                    if let index = self.pets.firstIndex(where: { $0.id == updatedPet.id }) {
                        self.pets[index] = updatedPet
                    }
                }
            }
        }
    }
    
    func uploadAvatar(uiImage: UIImage) {
        guard let data = uiImage.jpegData(compressionQuality: 0.7) else { return }
        isLoading = true
        apiService.uploadAvatar(image: data) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .success(let url) = result {
                    self.checkAuth() // Refresh user to get new avatar_url
                }
            }
        }
    }
    
    func deletePet(at offsets: IndexSet) {
        for index in offsets {
            let pet = pets[index]
            apiService.deletePet(id: pet.id) { result in
                DispatchQueue.main.async {
                    if case .success(let success) = result, success {
                        // Re-fetch or remove locally
                        self.loadPets()
                    }
                }
            }
        }
    }
    
    func feedPet(pet: Pet) {
        apiService.feedPet(id: pet.id, amount: "200g") { result in
            DispatchQueue.main.async {
                if case .success(let updatedPet) = result {
                    if let index = self.pets.firstIndex(where: { $0.id == updatedPet.id }) {
                        self.pets[index] = updatedPet
                    }
                }
            }
        }
    }
}
