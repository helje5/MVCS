import Boutique
import ViewController

/// A viewcontroller that fetches a red panda image from the server and allows a
/// user to favorite the red panda.
class RedPandaCard: ViewController {
  
  @Stored(in: .imagesStore) private var images

  @Published private var currentImage    : RemoteImage?
  @Published private var requestInFlight = false
  
  private let focusController : ScrollFocusController<String>

  init(focusController: ScrollFocusController<String>) {
    // can we please get synthesized class init's?
    self.focusController = focusController
    
    Task { // no onAppear/task necessary, can be done in init
      do {
        try await setCurrentImage()
      }
      catch {
        print("Error fetching image", error)
      }
    }
  }
  
  /// A few simple errors we can throw in case we receive bad data.
  enum DownloadError: Error {
      case badData
      case unexpectedStatusCode
  }

  @MainActor
  private func setCurrentImage() async throws {
    requestInFlight = true
    defer {
      requestInFlight = false
    }

    currentImage = nil // Assigning nil shows the progress spinner
    currentImage = try await fetchImage()
  }

  @MainActor
  private var currentImageIsSaved: Bool {
    if let image = currentImage {
      return images.contains(where: { image.id == $0.id })
    }
    else {
      return false
    }
  }

  /// Fetches `RemoteImage` from the API, providing the user with a red panda
  /// if the request succeeds.
  /// - Returns: The `RemoteImage` requested.
  private func fetchImage() async throws -> RemoteImage {
    // Hit the API that provides you a random image's metadata
    let imageURL = URL(string: "https://image.redpanda.club/random/json")!
    let randomImageRequest = URLRequest(url: imageURL)
    let (randomImageJSONData, _) =
      try await URLSession.shared.data(for: randomImageRequest)

    /// A type representing the API response providing image metadata from
    /// the API we're interacting with.
    struct RemoteImageResponse: Codable {
      let width  : Float
      let height : Float
      let key    : String
      let url    : URL
    }
    let imageResponse = try JSONDecoder().decode(RemoteImageResponse.self,
                                                 from: randomImageJSONData)

    // Download the image at the URL we received from the API
    let imageRequest = URLRequest(url: imageResponse.url)
    let (imageData, _) = try await URLSession.shared.data(for: imageRequest)

    // Lazy error handling, sorry, please do it better in your app
    guard let pngData = UIImage(data: imageData)?.pngData() else {
      throw DownloadError.badData
    }

    return RemoteImage(
      createdAt: .now, url: imageResponse.url,
      width: imageResponse.width, height: imageResponse.height,
      dataRepresentation: pngData
    )
  }

  
  // MARK: - Actions
  
  private func star() {
    Task {
      if await self.currentImageIsSaved {
        if let id = currentImage?.id {
          focusController.scrollTo(id)
        }
      }
      else if let image = currentImage {
        try await $images.add(image)
        try await setCurrentImage()
      }
    }
  }
  
  private func fetch() {
    Task {
      try await self.setCurrentImage()
    }
  }
  
  @MainActor
  private func scrollToCurrentImage() {
    guard currentImageIsSaved, let id = currentImage?.id else { return }
    focusController.scrollTo(id)
  }
  
  
  // MARK: - View

  @MainActor
  var view: some View {
    VStack(spacing: 16.0) {
      Spacer()
      if let currentImage = currentImage {
        RemoteImageView(image: currentImage)
          .aspectRatio(CGFloat(currentImage.height / currentImage.width),
                       contentMode: .fit)
          .primaryBorder()
          .overlay {
            currentImageIsSaved ? Color.black.opacity(0.5) : Color.clear
          }
          .cornerRadius(8.0)
          .onTapGesture { self.scrollToCurrentImage() }
      }
      else {
        ProgressView()
          .frame(width: 300.0, height: 300.0)
      }
      Spacer()

      VStack(spacing: 0.0) {
        Button(action: fetch) {
          Label("Fetch", systemImage: "arrow.clockwise.circle")
            .font(.title)
            .frame(maxWidth: .infinity)
            .frame(height: 52.0)
            .background(
              Color.palette.primary.overlay(
                requestInFlight ? Color.black.opacity(0.2) : Color.clear
              )
            )
            .foregroundColor(.white)
        }
        .disabled(requestInFlight)
        
        Button(action: star) {
          let title     = currentImageIsSaved ? "View Favorite"    : "Favorite"
          let imageName = currentImageIsSaved ? "star.circle.fill" : "star.circle"
          Label(title, systemImage: imageName)
            .font(.title)
            .frame(maxWidth: .infinity)
            .frame(height: 52.0)
            .background {
              if currentImageIsSaved {
                Color.palette.secondary
              }
              else {
                Color.palette.tertiary.overlay(
                  requestInFlight ? Color.black.opacity(0.2) : Color.clear
                )
              }
            }
            .foregroundColor(.white)
        }
        .disabled(requestInFlight)
      }
      .cornerRadius(8.0)
    }
    .padding(.vertical, 16.0)
  }
}
