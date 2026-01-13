import Foundation
import SwiftUI

@MainActor
class APODViewModel: ObservableObject {
    @Published var apodList: [AstronomyPicture] = []
    @Published var favorites: [AstronomyPicture] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let favoritesKey = "saved_apods"
    private let cacheKey = "last_session_apods" // Ключ для збереження останніх завантажених

    init() {
        loadFavorites()
        loadLastSession() // При запуску зразу показуємо те, що було минулого разу
        
        // Якщо список був пустий (перший запуск), пробуємо завантажити
        if apodList.isEmpty {
            Task { await fetchAPODs() }
        }
    }
    
    func fetchAPODs() async {
        // Не ставимо isLoading = true, якщо у нас вже є дані на екрані,
        // щоб не блимало зайвий раз. Тільки якщо список пустий.
        if apodList.isEmpty { isLoading = true }
        errorMessage = nil
        
        guard let url = URL(string: "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY&count=10") else { return }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Якщо помилка сервера (429 - ліміт)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }
            
            let decodedData = try JSONDecoder().decode([AstronomyPicture].self, from: data)
            let images = decodedData.filter { $0.media_type == "image" }
            
            if !images.isEmpty {
                // УСПІХ: Оновлюємо список і зберігаємо його в кеш
                self.apodList = images
                self.saveLastSession()
            }
            
            self.isLoading = false
            
        } catch {
            print("Помилка оновлення: \(error.localizedDescription)")
            
            // Якщо сталася помилка, ми НІЧОГО не видаляємо.
            // Старі фото залишаються на екрані.
            self.errorMessage = "Не вдалося оновити (Ліміт або Інтернет). Показано старі дані."
            self.isLoading = false
        }
    }
    
    // --- КЕШУВАННЯ ОСТАННЬОЇ СЕСІЇ ---
    
    private func saveLastSession() {
        if let encoded = try? JSONEncoder().encode(apodList) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    private func loadLastSession() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode([AstronomyPicture].self, from: data) {
            self.apodList = decoded
        }
    }
    
    // --- ЛОГІКА УЛЮБЛЕНОГО ---
    
    func toggleFavorite(item: AstronomyPicture) {
        if let index = favorites.firstIndex(where: { $0.date == item.date }) {
            favorites.remove(at: index)
        } else {
            favorites.append(item)
        }
        saveFavorites()
    }
    
    func isFavorite(item: AstronomyPicture) -> Bool {
        return favorites.contains(where: { $0.date == item.date })
    }
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([AstronomyPicture].self, from: data) {
            favorites = decoded
        }
    }
}
