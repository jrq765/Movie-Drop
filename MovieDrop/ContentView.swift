import SwiftUI

struct ContentView: View {
    @StateObject private var movieService = MovieService()
    @StateObject private var streamingService = StreamingService()
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var isLoading = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("MovieDrop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search movies...", text: $searchText)
                            .font(.system(size: 16))
                            .onSubmit {
                                performSearch()
                            }
                            .onChange(of: searchText) { _, newValue in
                                if newValue.count > 2 {
                                    performSearch()
                                } else if newValue.isEmpty {
                                    searchResults = []
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
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
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        print("🔍 Starting search for: '\(searchText)'")
        isLoading = true
        
        Task {
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
                        .background(Color.green)
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
        let movieCard = createMovieCard()
        
        // Create a URL for the movie (for future use)
        _ = URL(string: "https://moviedrop.app/movie/\(movie.id)")!
        
        // Create the message content
        let messageContent = """
        🎬 \(movie.title)
        
        \(movieCard)
        
        Check it out on MovieDrop!
        """
        
        // Open Messages app with the content
        if let url = URL(string: "sms:&body=\(messageContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
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
            .background(Color.blue)
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