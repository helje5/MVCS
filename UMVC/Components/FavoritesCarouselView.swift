import Boutique
import SwiftUI

// If you'd like to do more complex transforms on imagesController.images
// it's worth remembering that you can subscribe to the @Published property your controller exposes.
//
// Here `ImagesController`'s `images` is a @Published property which you can store and manipulate
// in your own `@State` property by subscribing to self.imagesController.$images like so.
//
//    @State private var images: [RemoteImage] = []
//
//    .onReceive(self.imagesController.$images, perform: {
//        self.images = $0.filter({ $0.width > 500 && $0.height > 500 })
//    })
/// A horizontally scrolling carousel that displays the red panda images a user has favorited.
struct FavoritesCarouselView: View {

    // An instance of `ImagesController`, which can take in the shared store or another store if we so choose,
    // an important part of our Controllers being decoupled from our Stores.
    @StateObject private var imagesController = ImagesController(store: Store.imagesStore)
    @State private var animation: Animation? = nil

    var body: some View {
        VStack {
            HStack {
                Text("Favorites")
                    .bold()
                    .font(.largeTitle)

                Spacer()

                Button(action: {
                    Task {
                        try await imagesController.clearAllImages()
                    }
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                })
            }

            if self.imagesController.images.isEmpty {
                VStack {
                    Text("Add some red pandas you love and they'll appear here!")
                        .multilineTextAlignment(.center)
                        .font(.title)

                    Spacer()
                }
            } else {
                HStack {
                    CarouselView(
                        items: self.imagesController.images.reversed(),
                        contentView: { image in
                            ZStack(alignment: .topTrailing) {
                                RemoteImageView(image: image)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8.0)
                                            .stroke(Color.palette.primary, lineWidth: 4.0)
                                    )
                                    .centerCroppedCardStyle()

                                Button(action: {
                                    Task {
                                        try await self.imagesController.removeImage(image: image)
                                    }
                                }, label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(color: .primary, radius: 4.0, x: 2.0, y: 2.0)
                                })
                                .padding(8.0)
                            }
                        }
                    )
                    .transition(.move(edge: .trailing))
                    .animation(animation, value: self.imagesController.images)
                }
                .task({
                    // Too lazy to figure out how to not trigger the janky
                    // initial animation because it's mostly irrelevant to this demo.
                    try! await Task.sleep(nanoseconds: 100_000_000)
                    self.animation = .easeInOut(duration: 0.35)
                })
            }
        }
        .frame(height: 200.0)
        .background(Color.palette.background)
    }

}
