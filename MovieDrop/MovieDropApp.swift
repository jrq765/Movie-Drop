import SwiftUI

@main
struct MovieDropApp: App {
    @StateObject private var appState = AppState()
    @State private var showIntro = true
    
    var body: some Scene {
        WindowGroup {
            if showIntro {
                IntroView()
                    .onAppear {
                        // Hide intro after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showIntro = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(appState)
                    .onOpenURL { url in
                        handleURL(url)
                    }
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        print("Received URL: \(url)")
        
        // Handle moviedrop:// scheme
        if url.scheme == "moviedrop" {
            if url.host == "movie" {
                let movieId = url.pathComponents.last ?? ""
                if !movieId.isEmpty {
                    appState.selectedMovieId = movieId
                    print("Opening movie with ID: \(movieId)")
                }
            }
        }
        
        // Handle Universal Links (moviedrop.app)
        if url.host == "moviedrop.app" {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 3 && pathComponents[1] == "m" {
                let movieId = pathComponents[2]
                appState.selectedMovieId = movieId
                print("Opening movie via Universal Link with ID: \(movieId)")
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedMovieId: String? = nil
}
