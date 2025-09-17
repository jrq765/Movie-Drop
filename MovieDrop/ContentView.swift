import SwiftUI

struct ContentView: View {
    @StateObject private var movieService = MovieService()
    @StateObject private var streamingService = StreamingService()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var searchResults: [Movie] = []
    @State private var isLoading = false
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    @State private var searchTask: Task<Void, Never>? // For debouncing search requests
    @State private var showingWatchlist = false
    
    var body: some View {
        TabView {
            // Search Tab
            NavigationView {
                VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("MovieDrop")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
                        
                        Spacer()
                        
                        // Profile/Logout Button
                        Menu {
                            if let user = authService.currentUser {
                                Text("Welcome, \(user.displayName)")
                                    .font(.headline)
                            }
                            
                            Button("My Watchlist") {
                                showingWatchlist = true
                            }
                            
                            Button("Logout") {
                                authService.logout()
                            }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                        }
                    }
                    
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
                                SearchMovieCardView(movie: movie) {
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
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .sheet(isPresented: $showingMovieDetail) {
                    if let movie = selectedMovie {
                        MovieDetailView(movie: movie, streamingService: streamingService)
                    }
                }
                .sheet(isPresented: $showingWatchlist) {
                    WatchlistView()
                }
                .onChange(of: appState.selectedMovieId) { _, newMovieId in
                    if let movieId = newMovieId, let id = Int(movieId) {
                        handleDeepLinkToMovie(id: id)
                    }
                }
            
            // Discovery Tab
            DiscoveryView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Discover")
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

struct SearchMovieCardView: View {
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
    @ObservedObject var streamingService: StreamingService
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
                    
                    // Streaming Options (use direct links from backend when available)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Where to Watch")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
                                
                                Spacer()
                            }

                            let streamingInfo = streamingService.getStreamingInfo(for: movie)
                            
                            if streamingInfo.isEmpty {
                                // Show loading state with company colors
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Color(red: 0.97, green: 0.33, blue: 0.21))
                                    Text("Finding available streaming options...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.3), lineWidth: 1)
                                )
                            } else {
                                // Show only real streaming options for this specific movie
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(streamingInfo, id: \.url) { info in
                                        MovieDropStreamingCard(info: info)
                                    }
                                }
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
        // Universal link with cache-busting to refresh iMessage preview
        let movieURL = "https://moviedrop.app/m/\(movie.id)?region=US&v=2"
        
        // Create visual movie card
        Task {
            let movieCardImage = await createMovieCardImage()
            
            await MainActor.run {
                var items: [Any] = []
                
                // Add the visual card if we have it
                if let cardImage = movieCardImage {
                    items.append(cardImage)
                }
                
                // Add the URL
                if let url = URL(string: movieURL) {
                    items.append(url)
                }
                
                // Add text fallback
                let message = createMovieCardText()
                items.append(message)
                
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityVC, animated: true)
                }
            }
        }
    }
    
    private func createMovieCardText() -> String {
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
    
    private func createMovieCardImage() async -> UIImage? {
        // Create a visual movie card similar to the iMessage extension
        let cardSize = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: cardSize)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Background gradient
                    let colors = [UIColor.systemBackground.cgColor, UIColor.systemGray6.cgColor]
                    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
                    cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: cardSize.height), options: [])
                    
                    // Load and draw poster
                    if let posterURL = self.movie.posterURL {
                        do {
                            let posterData = try Data(contentsOf: posterURL)
                            if let posterImage = UIImage(data: posterData) {
                                let posterRect = CGRect(x: 50, y: 50, width: 300, height: 450)
                                posterImage.draw(in: posterRect)
                                
                                // Add rounded corners to poster
                                cgContext.setFillColor(UIColor.systemBackground.cgColor)
                                cgContext.fillEllipse(in: CGRect(x: 45, y: 45, width: 310, height: 460))
                                posterImage.draw(in: posterRect)
                            }
                        } catch {
                            // Fallback: draw placeholder
                            let placeholderRect = CGRect(x: 50, y: 50, width: 300, height: 450)
                            cgContext.setFillColor(UIColor.systemGray4.cgColor)
                            cgContext.fill(placeholderRect)
                        }
                    }
                    
                    // Add title
                    let titleFont = UIFont.boldSystemFont(ofSize: 24)
                    let titleAttributes: [NSAttributedString.Key: Any] = [
                        .font: titleFont,
                        .foregroundColor: UIColor.label
                    ]
                    let titleText = NSAttributedString(string: self.movie.title, attributes: titleAttributes)
                    let titleSize = titleText.size()
                    let titleRect = CGRect(x: (cardSize.width - titleSize.width) / 2, y: 520, width: titleSize.width, height: titleSize.height)
                    titleText.draw(in: titleRect)
                    
                    // Add year
                    if let releaseDate = self.movie.releaseDate, releaseDate.count >= 4 {
                        let year = String(releaseDate.prefix(4))
                        let yearFont = UIFont.systemFont(ofSize: 18)
                        let yearAttributes: [NSAttributedString.Key: Any] = [
                            .font: yearFont,
                            .foregroundColor: UIColor.secondaryLabel
                        ]
                        let yearText = NSAttributedString(string: year, attributes: yearAttributes)
                        let yearSize = yearText.size()
                        let yearRect = CGRect(x: (cardSize.width - yearSize.width) / 2, y: 550, width: yearSize.width, height: yearSize.height)
                        yearText.draw(in: yearRect)
                    }
                    
                    // Add MovieDrop branding
                    let brandFont = UIFont.systemFont(ofSize: 14)
                    let brandAttributes: [NSAttributedString.Key: Any] = [
                        .font: brandFont,
                        .foregroundColor: UIColor.tertiaryLabel
                    ]
                    let brandText = NSAttributedString(string: "Shared via MovieDrop", attributes: brandAttributes)
                    let brandSize = brandText.size()
                    let brandRect = CGRect(x: (cardSize.width - brandSize.width) / 2, y: 570, width: brandSize.width, height: brandSize.height)
                    brandText.draw(in: brandRect)
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}

struct MovieDropStreamingCard: View {
    let info: StreamingInfo
    
    var body: some View {
        Button(action: openDirectLink) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21)) // MovieDrop orange
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(platformName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(priceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var platformName: String {
        let platform = info.platform.lowercased()
        if platform.contains("netflix") { return "Netflix" }
        if platform.contains("prime") || platform.contains("amazon") { return "Prime Video" }
        if platform.contains("hulu") { return "Hulu" }
        if platform.contains("disney") { return "Disney+" }
        if platform.contains("max") || platform.contains("hbo") { return "Max" }
        if platform.contains("apple") { return "Apple TV" }
        if platform.contains("youtube") { return "YouTube" }
        if platform.contains("paramount") { return "Paramount+" }
        if platform.contains("peacock") { return "Peacock" }
        return info.platform
    }
    
    private var priceText: String {
        switch info.type {
        case .subscription:
            return "Subscription"
        case .rent:
            return "Rent"
        case .buy:
            return "Buy"
        case .free:
            return "Free"
        }
    }
    
    private func openDirectLink() {
        // Ensure we're opening the direct link from the API (no redirects)
        guard let url = URL(string: info.url) else { 
            print("❌ Invalid streaming URL: \(info.url)")
            return 
        }
        
        print("🎬 Opening direct streaming link: \(info.platform) - \(info.url)")
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ Successfully opened \(info.platform)")
                } else {
                    print("❌ Failed to open \(info.platform)")
                }
            }
        } else {
            print("❌ Cannot open URL: \(url)")
        }
    }
}


// Keep the old button for backward compatibility
struct StreamingInfoButton: View {
    let info: StreamingInfo
    
    var body: some View {
        Button(action: openLink) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                Text("Watch on \(info.platform)")
                Spacer()
                Text(info.price ?? "")
                    .font(.caption)
                    .opacity(0.8)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color(red: 0.97, green: 0.33, blue: 0.21))
            .cornerRadius(12)
        }
    }
    
    private func openLink() {
        guard let url = URL(string: info.url) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}