import SwiftUI
import UIKit

final class RemoteImageMemoryCache {
    static let shared = RemoteImageMemoryCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 150
    }

    func image(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    func store(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }
}

struct RemoteCachedImageView: View {

    let urlString: String
    var placeholderIcon: String = "photo"
    var tintColor: Color = Color(red: 0.08, green: 0.30, blue: 0.15)

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image = loadedImage ?? RemoteImageMemoryCache.shared.image(for: urlString) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(tintColor.opacity(0.10))
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .tint(tintColor)
                        } else {
                            Image(systemName: placeholderIcon)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundStyle(tintColor.opacity(0.45))
                        }
                    }
            }
        }
        .task(id: urlString) {
            await loadIfNeeded()
        }
    }

    @MainActor
    private func loadIfNeeded() async {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let cached = RemoteImageMemoryCache.shared.image(for: trimmed) {
            loadedImage = cached
            return
        }

        guard let url = URL(string: trimmed) else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else {
                return
            }
            RemoteImageMemoryCache.shared.store(image, for: trimmed)
            loadedImage = image
        } catch {
            // Запрос мог быть отменён при переиспользовании ячейки
        }
    }
}
