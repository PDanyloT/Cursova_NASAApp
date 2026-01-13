import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = APODViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea() // Космічний чорний фон
                
                if viewModel.isLoading {
                    ProgressView("Зв'язок з NASA...")
                        .colorScheme(.dark)
                } else {
                    List {
                        // Секція списку
                        ForEach(viewModel.apodList) { item in
                            NavigationLink(destination: DetailView(item: item, viewModel: viewModel)) {
                                HStack {
                                    // Маленька картинка
                                    AsyncImage(url: URL(string: item.url)) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                                    
                                    VStack(alignment: .leading) {
                                        Text(item.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(item.date)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchAPODs()
                    }
                }
            }
            .navigationTitle("NASA Atlas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Кнопка переходу до улюблених
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FavoritesView(viewModel: viewModel)) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        // Щоб навігація була темною
        .preferredColorScheme(.dark)
        .onAppear {
            if viewModel.apodList.isEmpty {
                Task { await viewModel.fetchAPODs() }
            }
        }
    }
}

// --- ЕКРАН ДЕТАЛЕЙ ---
struct DetailView: View {
    let item: AstronomyPicture
    @ObservedObject var viewModel: APODViewModel
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Велика картинка
                AsyncImage(url: URL(string: item.url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                        .frame(height: 300)
                }
                
                // Кнопки дій
                HStack {
                    // Кнопка збереження в галерею
                    Button(action: {
                        saveImageToGallery()
                    }) {
                        Label(isSaving ? "Збереження..." : "В галерею", systemImage: "square.and.arrow.down")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isSaving)
                    
                    Spacer()
                    
                    // Кнопка лайку
                    Button(action: {
                        viewModel.toggleFavorite(item: item)
                    }) {
                        Image(systemName: viewModel.isFavorite(item: item) ? "heart.fill" : "heart")
                            .font(.title)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                Text(item.title)
                    .font(.title)
                    .bold()
                
                Text(item.date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(item.explanation)
                    .font(.body)
                    .lineSpacing(5)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
    }
    
    // Функція завантаження і збереження
    func saveImageToGallery() {
        guard let url = URL(string: item.url) else { return }
        isSaving = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let uiImage = UIImage(data: data) {
                    let imageSaver = ImageSaver()
                    imageSaver.writeToPhotoAlbum(image: uiImage)
                }
                isSaving = false
            } catch {
                print("Error saving image")
                isSaving = false
            }
        }
    }
}

// --- ЕКРАН УЛЮБЛЕНИХ ---
struct FavoritesView: View {
    @ObservedObject var viewModel: APODViewModel
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.favorites.isEmpty {
                Text("У вас немає улюблених фото")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.favorites) { item in
                        NavigationLink(destination: DetailView(item: item, viewModel: viewModel)) {
                            HStack {
                                Text(item.title)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .listRowBackground(Color(white: 0.1))
                    }
                    .onDelete { indexSet in
                        viewModel.favorites.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Улюблене")
    }
}
