import SwiftUI

@main
struct AutoAlbumPrototypeApp: App {
    @StateObject private var viewModel = TripListViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: viewModel)
            }
        }
    }
}
