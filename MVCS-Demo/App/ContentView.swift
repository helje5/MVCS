import SwiftUI

struct ContentView: View {

    @StateObject private var carouselFocusController = ScrollFocusController<String>()

    var body: some View {
        VStack(spacing: 0.0) {
            FavoritesCarouselView()
                .padding(.bottom, 8.0)
                .environmentObject(carouselFocusController)

            Divider()

            Spacer()

            RedPandaCardView()
                .environmentObject(carouselFocusController)
        }
        .padding(.horizontal, 16.0)
        .background(Color.palette.background)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
