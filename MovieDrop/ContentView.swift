import SwiftUI

struct ContentView: View {
    @StateObject private var movieService = MovieService()
    @StateObject private var streamingService = StreamingService()
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var isLoading = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    @State private var searchTask: Task<Void, Never>? // For debouncing search requests
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("MovieDrop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search movies...", text: $searchText)
                            .font(.system(size: 16))
                            .onSubmit {
                                performSearchDebounced()
                            }
                            .onChange(of: searchText) { _, newValue in
                                if newValue.count > 2 {
                                    performSearchDebounced()
                                } else if newValue.isEmpty {
                                    searchTask?.cancel()
                                    searchResults = []
                                    isLoading = false
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchTask?.cancel()
                                searchText = ""
                                searchResults = []
                                isLoading = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.3), lineWidth: 1)
                    )
                    
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .font(.headline)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No movies found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Try a different search term")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "film")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Search for movies")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Enter a movie title to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchResults) { movie in
                                MovieCardView(movie: movie) {
                                    selectedMovie = movie
                                    showingMovieDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailView(movie: movie, streamingService: streamingService)
            }
        }
        .onChange(of: appState.selectedMovieId) { _, newMovieId in
            if let movieId = newMovieId, let id = Int(movieId) {
                handleDeepLinkToMovie(id: id)
            }
        }
    }
    
    private func refresh() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        do {
            let results = try await movieService.searchMovies(query: searchText)
            await MainActor.run {
                searchResults = results
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
    
    private func performSearchDebounced() {
        // Cancel previous search task
        searchTask?.cancel()
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Debounce search requests
        searchTask = Task {
            // Wait 500ms before making the request
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            await performSearch()
        }
    }
    
    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        print("🔍 Starting search for: '\(searchText)'")
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let results = try await movieService.searchMovies(query: searchText)
            await MainActor.run {
                print("✅ Search completed. Found \(results.count) movies")
                searchResults = results
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Search failed: \(error)")
                searchResults = []
                isLoading = false
            }
        }
    }
    
    private func handleDeepLinkToMovie(id: Int) {
        print("🔗 Handling deep link to movie ID: \(id)")
        isLoading = true
        
        Task {
            do {
                let movie = try await movieService.getMovieDetails(id: id)
                await MainActor.run {
                    print("✅ Deep link: Successfully loaded movie: \(movie.title)")
                    selectedMovie = movie
                    showingMovieDetail = true
                    isLoading = false
                    // Clear the selected movie ID to prevent re-triggering
                    appState.selectedMovieId = nil
                }
            } catch {
                await MainActor.run {
                    print("❌ Deep link: Failed to load movie details: \(error)")
                    isLoading = false
                    // Clear the selected movie ID even on failure
                    appState.selectedMovieId = nil
                }
            }
        }
    }
}

struct MovieCardView: View {
    let movie: Movie
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Movie Poster
                AsyncImage(url: movie.posterURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear {
                    print("🖼️ Loading poster for \(movie.title): \(movie.posterPath ?? "nil")")
                }
                
                // Movie Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let releaseDate = movie.releaseDate {
                        Text(releaseDate.prefix(4))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MovieDetailView: View {
    let movie: Movie
    let streamingService: StreamingService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Movie Poster
                    AsyncImage(url: movie.backdropURL ?? movie.posterURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 50))
                            )
                    }
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Movie Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(movie.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let releaseDate = movie.releaseDate {
                            Text(releaseDate)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let overview = movie.overview, !overview.isEmpty {
                            Text(overview)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                    }
                    
                    // Streaming Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where to Watch")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        ForEach(streamingService.getAvailablePlatforms(for: movie), id: \.self) { platform in
                            StreamingButton(platform: platform, movie: movie, streamingService: streamingService)
                        }
                    }
                    
                    // Share Button
                    Button(action: shareMovie) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Movie")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Movie Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareMovie() {
        // Create the movie URL for the web version
        let movieURL = "https://moviedrop.app/m/\(movie.id)"
        
        // Create a rich movie card message
        let movieCard = createMovieCard()
        
        // Create the message content with the web URL
        let messageContent = """
        🎬 \(movie.title)
        
        \(movieCard)
        
        Watch it here: \(movieURL)
        
        📱 Get the MovieDrop app for the best experience!
        """
        
        // Use the native share sheet for better sharing options
        let activityViewController = UIActivityViewController(
            activityItems: [messageContent, URL(string: movieURL)!],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    private func createMovieCard() -> String {
        var card = "🎬 \(movie.title)\n"
        if let releaseDate = movie.releaseDate {
            card += "📅 \(releaseDate)\n"
        }
        if let overview = movie.overview, !overview.isEmpty {
            card += "📝 \(overview)\n"
        }
        card += "\n🔍 Found with MovieDrop"
        return card
    }
}

struct StreamingButton: View {
    let platform: StreamingPlatform
    let movie: Movie
    let streamingService: StreamingService
    
    var body: some View {
        Button(action: {
            openStreamingPlatform(platform)
        }) {
            HStack {
                Image(systemName: platform.iconName)
                Text("Watch on \(platform.displayName)")
                Spacer()
                Text(streamingService.getPrice(for: platform) ?? "")
                    .font(.caption)
                    .opacity(0.8)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
            .cornerRadius(12)
        }
    }
    
    private func openStreamingPlatform(_ platform: StreamingPlatform) {
        guard let url = streamingService.getStreamingURL(for: platform, movieTitle: movie.title) else {
            print("Could not create URL for \(platform.displayName)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("Cannot open URL: \(url)")
        }
    }
}

#Preview {
    ContentView()
}