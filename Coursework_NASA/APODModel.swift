import Foundation

// Модель даних, яка відповідає відповіді від NASA
struct AstronomyPicture: Codable, Identifiable {
    let id = UUID() // Локальний ID для списків
    let title: String
    let explanation: String
    let url: String
    let media_type: String // image або video
    let date: String
    
    // NASA повертає поля без ID, тому ми їх ігноруємо при кодуванні
    enum CodingKeys: String, CodingKey {
        case title, explanation, url, media_type, date
    }
}

