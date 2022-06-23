import Boutique
import ViewController

/// A horizontally scrolling carousel that displays the red panda images a user
/// has favorited.
class FavoritesCarousel: ViewController {
  // Unlike in @mergesort's setup, this VC only does the controlling relevant
  // for this specific View. I.e. the `ImagesController` is gone.
  // Like in his setup, the controllers share the same store.
  
  /// The `Store` that we'll be using to save images.
  @Stored(in: .imagesStore) var images

  @Published private var animation: Animation? = nil
  
  init() {
    // Too lazy to figure out how to not trigger the janky
    // initial animation because it's mostly irrelevant to this demo.
    Task { // hh: Still not good w/ async, is this right? :-)
      try! await Task.sleep(nanoseconds: 100_000_000)
      Task { @MainActor in
        self.animation = .easeInOut(duration: 0.35)
      }
    }
  }
  
  
  // MARK: - Actions

  /// Removes one image from the `Store` in memory and on disk.
  /// - Parameter image: A `RemoteImage` to be removed.
  private func removeImage(image: RemoteImage) {
    Task { try await self.$images.remove(image) }
  }
  
  /// Removes all of the images from the `Store` in memory and on disk.
  private func clearAllImages() {
    Task { try await self.$images.removeAll() }
  }
  
  
  // MARK: - View
  
  @MainActor
  var view: some View {
    VStack {
      HStack {
        Text("Favorites")
          .bold()
          .font(.largeTitle)
          .padding(.top)
        
        Spacer()
        
        Button(action: clearAllImages) {
          Image(systemName: "xmark.circle.fill")
            .opacity(images.isEmpty ? 0.0 : 1.0)
            .font(.title)
            .foregroundColor(.red)
        }
      }
      
      if images.isEmpty {
        VStack {
          Spacer()
          
          Text("Add some red pandas you love and they'll appear here!")
            .multilineTextAlignment(.center)
            .font(.title)
          
          Spacer()
        }
      }
      else {
        HStack {
          CarouselView(items: images.sorted(by: { $0.createdAt > $1.createdAt })) {
            image in
            
            ZStack(alignment: .topTrailing) {
              RemoteImageView(image: image)
                .primaryBorder()
                .centerCroppedCardStyle()
              
              Button(action: { self.removeImage(image: image) }) {
                Image(systemName: "xmark.circle.fill")
                  .font(.title2)
                  .foregroundColor(.white)
                  .shadow(color: .primary, radius: 4.0, x: 2.0, y: 2.0)
              }
              .padding(8.0)
            }
          }
          .transition(.move(edge: .trailing))
          .animation(animation, value: images)
        }
      }
    }
    .frame(height: 200.0)
    .background(Color.palette.background)
  }
}
