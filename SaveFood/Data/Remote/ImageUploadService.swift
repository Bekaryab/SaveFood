import Foundation
import UIKit

enum ImageUploadError: LocalizedError {
    case missingAPIKey
    case imageCompressionFailed
    case invalidEndpoint
    case httpError(statusCode: Int, message: String?)
    case decodingFailed
    case serverRejected(String)
    case invalidReturnedURL

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Не настроен ключ IMGBB_API_KEY в Info.plist / Secrets.xcconfig."
        case .imageCompressionFailed:
            return "Не удалось обработать выбранную фотографию."
        case .invalidEndpoint:
            return "Некорректный адрес сервера загрузки изображений."
        case .httpError(let code, let message):
            if let message, !message.isEmpty {
                return "Ошибка загрузки фото (HTTP \(code)): \(message)"
            }
            return "Ошибка сервера загрузки изображений (HTTP \(code))."
        case .decodingFailed:
            return "Сервер вернул некорректный ответ при загрузке фото."
        case .serverRejected(let message):
            return "Загрузка фото отклонена: \(message)"
        case .invalidReturnedURL:
            return "Сервер вернул некорректную ссылку на загруженное фото."
        }
    }
}

protocol ImageUploading: Sendable {
    func uploadPhoto(_ image: UIImage) async throws -> String
}

private struct ImgBBResponseDTO: Decodable {
    struct DataPayload: Decodable {
        let url: String?
        let displayURL: String?

        enum CodingKeys: String, CodingKey {
            case url
            case displayURL = "display_url"
        }
    }

    struct ErrorPayload: Decodable {
        let message: String?
    }

    let data: DataPayload?
    let success: Bool?
    let status: Int?
    let error: ErrorPayload?
}

final class ImgBBImageUploadService: ImageUploading, @unchecked Sendable {

    private let session: URLSession
    private let apiKeyProvider: @Sendable () -> String?
    // Оңтайлы өлшем мен сапа: мобильді экранда анық көрінеді, бірақ 4-6 есе жылдам жүктеледі
    private let maxImageDimension: CGFloat = 960
    private let jpegQuality: CGFloat = 0.62

    init(
        session: URLSession = .shared,
        apiKeyProvider: @escaping @Sendable () -> String? = {
            Bundle.main.object(forInfoDictionaryKey: "IMGBB_API_KEY") as? String
        }
    ) {
        self.session = session
        self.apiKeyProvider = apiKeyProvider
    }

    func uploadPhoto(_ image: UIImage) async throws -> String {
        guard let rawKey = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawKey.isEmpty,
              !rawKey.contains("$(") else {
            throw ImageUploadError.missingAPIKey
        }

        let maxDim = self.maxImageDimension
        let quality = self.jpegQuality

        // Суретті кішірейту мен сығуды фондық ағында орындаймыз (UI қатпайды)
        let jpegData: Data? = await Task.detached(priority: .userInitiated) {
            let resized = Self.resizeIfNeeded(image, maxDimension: maxDim)
            return resized.jpegData(compressionQuality: quality)
        }.value

        guard let jpegData else {
            throw ImageUploadError.imageCompressionFailed
        }

        var components = URLComponents(string: "https://api.imgbb.com/1/upload")
        components?.queryItems = [URLQueryItem(name: "key", value: rawKey)]
        guard let url = components?.url else {
            throw ImageUploadError.invalidEndpoint
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.makeMultipartBody(jpegData: jpegData, boundary: boundary)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.decodingFailed
        }

        let decoded = try? JSONDecoder().decode(ImgBBResponseDTO.self, from: data)

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageUploadError.httpError(
                statusCode: httpResponse.statusCode,
                message: decoded?.error?.message
            )
        }

        guard let payload = decoded else {
            throw ImageUploadError.decodingFailed
        }

        if payload.success == false {
            throw ImageUploadError.serverRejected(payload.error?.message ?? "Неизвестная ошибка загрузки")
        }

        guard let resultURL = payload.data?.displayURL ?? payload.data?.url,
              Validators.isValidHTTPURL(resultURL) else {
            throw ImageUploadError.invalidReturnedURL
        }

        return resultURL
    }

    private static func makeMultipartBody(jpegData: Data, boundary: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"image\"; filename=\"savefood_\(UUID().uuidString).jpg\"\(lineBreak)".utf8))
        body.append(Data("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".utf8))
        body.append(jpegData)
        body.append(Data(lineBreak.utf8))
        body.append(Data("--\(boundary)--\(lineBreak)".utf8))
        return body
    }

    private static func resizeIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension, longestSide > 0 else {
            return image
        }
        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
