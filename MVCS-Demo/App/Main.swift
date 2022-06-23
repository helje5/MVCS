import ViewController

class Main: ViewController {
  // The main idea here is that the controlling objects live outside of the
  // Views. Decouple presentation (View) from the current app state.

  let carouselFocusController = ScrollFocusController<String>()

  // Those are (and could be added as) child VCs (containment). But this sample
  // doesn't really do navigation, so we can just refer to them directly.
  let carousel  = FavoritesCarousel()
  lazy var card = RedPandaCard(focusController: carouselFocusController)
  
  var view: some View {
    VStack(spacing: 0.0) {
      carousel
        .controlledContentView // essentially the "presentInline"
        .environmentObject(carouselFocusController)
        .padding(.bottom, 8.0)

        Divider()

        Spacer()

      card
        .controlledContentView
    }
    .padding(.horizontal, 16.0)
    .background(Color.palette.background)
  }
}
