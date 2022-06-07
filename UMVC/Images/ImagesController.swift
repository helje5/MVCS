import Boutique
import Foundation
import SwiftUI

/// A controller that allos you to fetch, save, and delete images from a `Store`.
final class ImagesController: ObservableObject {

    private let store: Store<RemoteImage>

    /// The `images` available to read for external callers.
    @MainActor @Published private(set) var images: [RemoteImage] = []

    ///   - items: The items you are adding to the `Store`.
    ///   - invalidationStrategy: An optional `CacheInvalidationStrategy` you can provide when adding data

    /// Initializes an `ImagesController` with a `Store` to hold `RemoteImage`s.
    /// - Parameter store: The store which holds the `images` which are saved in memory and to disk.
    init(store: Store<RemoteImage>) {
        self.store = store

        self.store.$items
            .assign(to: &self.$images)
    }

    /// Fetches `RemoteImage` from the API, providing the user with a red panda if the request suceeds.
    /// - Returns: The `RemoteImage` requested.
    func fetchImage() async throws -> RemoteImage {
        // Hit the API that provides you a random image's metadata
        let imageURL = URL(string: "https://image.redpanda.club/random/json")!
        let randomImageRequest = URLRequest(url: imageURL)
        let (randomImageJSONData, _) = try await URLSession.shared.data(for: randomImageRequest)

        let imageResponse = try JSONDecoder().decode(RemoteImageResponse.self, from: randomImageJSONData)

        // Download the image at the URL we received from the API
        let imageRequest = URLRequest(url: imageResponse.url)
        let (imageData, _) = try await URLSession.shared.data(for: imageRequest)

        // Lazy error handling, sorry, please do it better in your app
        guard let pngData = UIImage(data: imageData)?.pngData() else { throw DownloadError.badData }

        return RemoteImage(url: imageResponse.url, width: imageResponse.width, height: imageResponse.height, dataRepresentation: pngData)
    }

    /// Saves an image to the `Store` in memory and on disk.
    /// - Parameter image: A `RemoteImage` to be saved.
    func saveImage(image: RemoteImage) async throws {
        try await self.store.add(image)
    }

    /// Removes one image from the `Store` in memory and on disk.
    /// - Parameter image: A `RemoteImage` to be removed.
    func removeImage(image: RemoteImage) async throws {
        try await self.store.remove(image)
    }

    /// Removes all of the images from the `Store` in memory and on disk.
    func clearAllImages() async throws {
        try await self.store.removeAll()
    }

}

extension ImagesController {

    /// A few simple errors we can throw in case we receive bad data.
    enum DownloadError: Error {
        case badData
        case unexpectedStatusCode
    }

}

private extension ImagesController {

    /// A type representing the API response providing image metadata from the API we're interacting with.
    struct RemoteImageResponse: Codable {
        let height: Float
        let width: Float
        let key: String
        let url: URL
    }

}
