import ViewController

@main
struct MVCSDemoApp: App {
  
  var body: some Scene {
    WindowGroup {
      // `Main` is the VC for the root page of the scene,
      // `MainViewController` hooks it up to the `View` hierarchy.
      MainViewController(Main())
    }
  }
}
