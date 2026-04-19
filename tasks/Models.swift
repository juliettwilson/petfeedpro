import Foundation

enum PetType: String, Codable, CaseIterable {
    case dog = "Dog"
    case cat = "Cat"
    case parrot = "Parrot"
    case rabbit = "Rabbit"
    case hamster = "Hamster"
    case fish = "Fish"
    
    var icon: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐈"
        case .parrot: return "🦜"
        case .rabbit: return "🐇"
        case .hamster: return "🐹"
        case .fish: return "🐠"
        }
    }
}

struct User: Codable {
    let username: String
    let full_name: String
    let email: String
    let avatar_url: String?
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct FeedingLog: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let amount: String
}

struct Pet: Codable, Identifiable {
    let id: String
    var name: String
    var type: String
    var is_fed: Bool
    var owner_username: String
    var birth_date: Date?
    var feeding_history: [FeedingLog]
    
    
    var petType: PetType {
        PetType(rawValue: type) ?? .dog
    }
    
    var ageString: String {
        guard let birthDate = birth_date else { return "Age Unknown" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate, to: Date())
        
        if let year = components.year, year > 0 {
            return "\(year)y \(components.month ?? 0)m"
        } else if let month = components.month, month > 0 {
            return "\(month)m \(components.day ?? 0)d"
        } else {
            return "\(components.day ?? 0)d"
        }
    }
    

    var feedingRatio: Double {
        
        let today = Calendar.current.startOfDay(for: Date())
        let todayFeeds = feeding_history.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }.count
        return min(Double(todayFeeds) / 3.0, 1.0)
    }
}
