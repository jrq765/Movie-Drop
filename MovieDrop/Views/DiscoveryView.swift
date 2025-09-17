import SwiftUI

struct DiscoveryView: View {
    @StateObject private var movieService = MovieService()
    @StateObject private var authService = AuthService()
    @EnvironmentObject var appState: AppState
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    @State private var seenMovieIds: Set<Int> = []
    @State private var lastFirstMovieId: Int? = nil
    private let seenStoreKey = "seen_movie_ids"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.1),
                        Color.black.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading movies...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                        } else if movies.isEmpty {
                            VStack(spacing: 20) {
                        Image(systemName: "film")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                        Text("No movies available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Try refreshing or check your connection")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else if currentIndex >= movies.count {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("That's all for now!")
                                    .font(.title2)
                            .fontWeight(.semibold)
                        Text("You've seen all available movies")
                            .font(.body)
                            .foregroundColor(.secondary)
                                
                        Button("Refresh") {
                            loadPopularMovies()
                                }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                                .background(Color(red: 0.97, green: 0.33, blue: 0.21))
                        .cornerRadius(25)
                            }
                        } else {
                    // Movie Cards Stack with proper spacing
                    VStack(spacing: 0) {
                        // Top spacing to avoid header overlap
                        Spacer()
                            .frame(height: 50)
                        
                        ZStack {
                            ForEach(Array(movies.enumerated().reversed()), id: \.element.id) { index, movie in
                                if index >= currentIndex {
                                    TinderMovieCard(movie: movie) {
                                        selectedMovie = movie
                                        showingMovieDetail = true
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .scaleEffect(index == currentIndex ? 1.0 : 0.95 - CGFloat(index - currentIndex) * 0.05)
                                    .offset(
                                        x: index == currentIndex ? dragOffset.width : 0,
                                        y: index == currentIndex ? dragOffset.height : CGFloat(index - currentIndex) * 10
                                    )
                                    .rotationEffect(.degrees(index == currentIndex ? rotationAngle : 0))
                                    .opacity(index == currentIndex ? 1.0 : 0.8 - CGFloat(index - currentIndex) * 0.2)
                                    .zIndex(Double(movies.count - index))
                                    .gesture(
                                        index == currentIndex ?
                                        DragGesture()
                                            .onChanged { value in
                                                // Only allow drag if not touching action buttons area
                                                let buttonAreaHeight: CGFloat = 120 // Height of action buttons area
                                                let screenHeight = UIScreen.main.bounds.height
                                                let touchY = value.startLocation.y
                                                
                                                // Check if touch is in the button area (bottom 120 points)
                                                if touchY < screenHeight - buttonAreaHeight {
                                                    dragOffset = value.translation
                                                    rotationAngle = Double(value.translation.width / 20)
                                                }
                                            }
                                            .onEnded { value in
                                                // Only handle swipe if not in button area
                                                let buttonAreaHeight: CGFloat = 120
                                                let screenHeight = UIScreen.main.bounds.height
                                                let touchY = value.startLocation.y
                                                
                                                if touchY < screenHeight - buttonAreaHeight {
                                                    handleSwipeEnd(value: value)
                                                } else {
                                                    // Reset drag if in button area
                                                    withAnimation(.spring()) {
                                                        dragOffset = .zero
                                                        rotationAngle = 0
                                                    }
                                                }
                                            } : nil
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 380)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
                    
                    // Action Buttons
                if !isLoading && !movies.isEmpty && currentIndex < movies.count {
                    VStack(spacing: 0) {
                        // Movie cards take up most of the space
                        Spacer()
                        
                        // Action buttons at the bottom
                        HStack(spacing: 50) {
                        // Pass Button
                        Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        if currentIndex < movies.count {
                                            passMovie(movies[currentIndex])
                                        }
                                    }
                        }) {
                            Image(systemName: "xmark")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.8),
                                                Color(red: 0.85, green: 0.25, blue: 0.15).opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                .clipShape(Circle())
                                    .shadow(color: Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        
                                // Like Button
                        Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        if currentIndex < movies.count {
                                            likeMovie(movies[currentIndex])
                                        }
                                    }
                        }) {
                            Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.97, green: 0.33, blue: 0.21),
                                                Color(red: 0.85, green: 0.25, blue: 0.15)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.5), radius: 12, x: 0, y: 6)
                            }
                            
                                // Watchlist Button
                            Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        if currentIndex < movies.count {
                                            addToWatchlist(movies[currentIndex])
                                        }
                                    }
                            }) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.9),
                                                Color(red: 0.85, green: 0.25, blue: 0.15).opacity(0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.4), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(.bottom, 30)
                            .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadPopularMovies()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.97, green: 0.33, blue: 0.21),
                                        Color(red: 0.85, green: 0.25, blue: 0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color(red: 0.97, green: 0.33, blue: 0.21).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .sheet(isPresented: $showingMovieDetail) {
                if let movie = selectedMovie {
                    MovieDetailView(movie: movie, streamingService: StreamingService())
                }
            }
            .overlay(
                // Success message overlay
                Group {
                    if showingSuccessMessage {
                        VStack {
                            Spacer()
                            Text(successMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                        }
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showingSuccessMessage = false
                                }
                            }
                        }
                    }
                }
            )
        }
        .onAppear {
            loadSeenIds()
            loadPopularMovies()
        }
        .onChange(of: appState.resetDiscoverTick) { _, _ in
            // Full reset triggered from settings/profile
            seenMovieIds.removeAll()
            movies.removeAll()
            currentIndex = 0
            loadPopularMovies()
        }
    }
    
    private func loadPopularMovies() {
        isLoading = true
        currentIndex = 0
        
        Task {
            do {
                var results: [Movie]
                
                // Try to get personalized recommendations if user has liked movies
                if let user = authService.currentUser {
                    do {
                        results = try await movieService.getRecommendations(userId: user.id)
                        print("🎯 Loaded personalized recommendations")
                    } catch {
                        // Fall back to popular movies if recommendations fail
                        results = try await movieService.getPopularMovies(excludeIds: Array(seenMovieIds))
                        print("📊 Fallback to popular movies")
                    }
                } else {
                    // No user logged in, use popular movies
                    results = try await movieService.getPopularMovies(excludeIds: Array(seenMovieIds))
                    print("📊 Loaded popular movies (no user)")
                }
                
                await MainActor.run {
                    var randomized = results.shuffled()
                    if let last = lastFirstMovieId, let first = randomized.first, first.id == last, randomized.count > 1 {
                        randomized.swapAt(0, 1)
                    }
                    movies = randomized
                    lastFirstMovieId = movies.first?.id
                    // Add newly fetched IDs to seen set
                    for m in movies { seenMovieIds.insert(m.id) }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to load movies: \(error)")
                    isLoading = false
                }
            }
        }
    }
    
    private func refreshMovies() async {
        print("🔄 Refreshing movies...")
        // Don't reset currentIndex - keep showing new movies from where we are
        
        do {
            var results: [Movie]
            
            // Try to get personalized recommendations if user has liked movies
            if let user = authService.currentUser {
                do {
                    results = try await movieService.getRecommendations(userId: user.id)
                    print("🎯 Refreshed with personalized recommendations")
                } catch {
                    // Fall back to popular movies if recommendations fail
                    results = try await movieService.getPopularMovies()
                    print("📊 Refreshed with popular movies (fallback)")
                }
            } else {
                // No user logged in, use popular movies
                results = try await movieService.getPopularMovies()
                print("📊 Refreshed with popular movies (no user)")
            }
            
            await MainActor.run {
                var randomized = results.shuffled()
                if let last = lastFirstMovieId, let first = randomized.first, first.id == last, randomized.count > 1 {
                    randomized.swapAt(0, 1)
                }
                movies = randomized
                lastFirstMovieId = movies.first?.id
                for m in movies { seenMovieIds.insert(m.id) }
                print("✅ Refreshed with \(movies.count) new movies (randomized)")
            }
        } catch {
            print("❌ Failed to refresh movies: \(error)")
        }
    }
    
    private func handleSwipeEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        withAnimation(.spring()) {
            if abs(value.translation.width) > threshold {
                if value.translation.width > 0 {
                    // Swiped right - Like (Heart) - ML Learning only
                    // Haptic feedback for swipe
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    likeMovie()
                } else {
                    // Swiped left - Pass (X)
                    // Haptic feedback for swipe
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    passMovie()
                }
            } else {
                // Return to center
            dragOffset = .zero
            rotationAngle = 0
            }
        }
    }
    
    private func likeMovie() {
        let movie = movies[currentIndex]
        print("❤️ Liked: \(movie.title) - Learning user preferences for ML recommendations")
        
        // TODO: Add to user's liked movies for ML learning
        // This will help the recommendation system learn user preferences
        // but does NOT add to watchlist (that's what the save button does)
        
        Task {
            do {
                if let user = authService.currentUser {
                    // Here we would save to a "liked_movies" table for ML learning
                    // For now, just show success message
                    await MainActor.run {
                        successMessage = "❤️ Thanks! Learning your preferences..."
                        showingSuccessMessage = true
                    }
                }
            } catch {
                print("❌ Failed to save like: \(error)")
                await MainActor.run {
                    successMessage = "❌ Failed to save like"
                    showingSuccessMessage = true
                }
            }
        }
        
        markSeen(movie.id)
        nextMovie()
    }
    
    private func passMovie() {
        print("❌ Passed: \(movies[currentIndex].title)")
        // Just move to next movie when passing
        markSeen(movies[currentIndex].id)
        nextMovie()
    }
    
    private func addToWatchlist() {
            let movie = movies[currentIndex]
        print("📝 Saved to watchlist: \(movie.title) - Also learning preferences for ML")
        
        Task {
            do {
                if let user = authService.currentUser {
                    // 1. Add to watchlist
                    try await movieService.addToWatchlist(userId: user.id, movie: movie)
                    
                    // 2. Also save as liked for ML learning (since user wants to watch it)
                    // TODO: Add to user's liked movies for ML learning
                    
                    await MainActor.run {
                        successMessage = "📝 Saved \(movie.title) to watchlist & learning preferences!"
                        showingSuccessMessage = true
                    }
                }
            } catch {
                print("❌ Failed to add to watchlist: \(error)")
                await MainActor.run {
                    successMessage = "❌ Failed to save to watchlist"
                    showingSuccessMessage = true
                }
            }
        }
        
        markSeen(movie.id)
        nextMovie()
    }
    
    private func nextMovie() {
        withAnimation(.spring()) {
            if currentIndex < movies.count { seenMovieIds.insert(movies[currentIndex].id) }
            currentIndex += 1
            dragOffset = .zero
            rotationAngle = 0
        }
        // If we are within last 2 cards, prefetch more to avoid repetition
        if currentIndex >= movies.count - 2 {
            Task {
                do {
                    let more = try await movieService.getPopularMovies(excludeIds: Array(seenMovieIds))
                    await MainActor.run {
                        movies.append(contentsOf: more)
                        more.forEach { seenMovieIds.insert($0.id) }
                    }
                } catch {
                    print("⚠️ Prefetch failed: \(error)")
                }
            }
        }
    }

    // MARK: - Seen IDs persistence
    private func loadSeenIds() {
        if let saved = UserDefaults.standard.array(forKey: seenStoreKey) as? [Int] {
            seenMovieIds = Set(saved)
            print("📦 Loaded seen ids: \(seenMovieIds.count)")
        }
    }
    private func saveSeenIds() {
        UserDefaults.standard.set(Array(seenMovieIds), forKey: seenStoreKey)
    }
    private func markSeen(_ id: Int) {
        seenMovieIds.insert(id)
        saveSeenIds()
    }
    
    // MARK: - User Actions
    private func likeMovie(_ movie: Movie) {
        print("❤️ User liked: \(movie.title)")
        
        // Add to seen movies
        seenMovieIds.insert(movie.id)
        saveSeenIds()
        
        // Send signal to Railway for learning
        Task {
            await sendUserSignal(movieId: movie.id, action: "like")
        }
        
        // Move to next movie
        nextMovie()
    }
    
    private func passMovie(_ movie: Movie) {
        print("👎 User passed: \(movie.title)")
        
        // Add to seen movies
        seenMovieIds.insert(movie.id)
        saveSeenIds()
        
        // Send signal to Railway for learning
        Task {
            await sendUserSignal(movieId: movie.id, action: "dismiss")
        }
        
        // Move to next movie
        nextMovie()
    }
    
    private func addToWatchlist(_ movie: Movie) {
        print("📝 User added to watchlist: \(movie.title)")
        
        // Add to seen movies
        seenMovieIds.insert(movie.id)
        saveSeenIds()
        
        // Send signal to Railway for learning
        Task {
            await sendUserSignal(movieId: movie.id, action: "watchlist")
        }
        
        // Add to watchlist via MovieService
        Task {
            if let user = authService.currentUser {
                do {
                    try await movieService.addToWatchlist(userId: user.id, movie: movie)
                    print("✅ Added to watchlist successfully")
                } catch {
                    print("❌ Failed to add to watchlist: \(error)")
                }
            }
        }
        
        // Move to next movie
        nextMovie()
    }
    
    private func sendUserSignal(movieId: Int, action: String) async {
        guard let user = authService.currentUser else { return }
        
        do {
            let signalData: [String: Any] = [
                "userId": user.id,
                "movieId": movieId,
                "action": action,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            guard let url = URL(string: "https://movie-drop-production.up.railway.app/signals") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: signalData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Signal sent: \(action) for movie \(movieId) - Status: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ Failed to send signal: \(error)")
        }
    }
}

struct TinderMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    @State private var showingTrailer = false
    @State private var currentImageIndex = 0
    @State private var showingReviews = false
    
    // Real data from backend API
    private var movieImages: [URL?] {
        [
            movie.backdropURL ?? movie.posterURL,
            movie.posterURL,
            movie.backdropURL
        ].compactMap { $0 }
    }
    
    private var rottenTomatoesScore: Int? {
        // This will be populated from the backend API
        return movie.rottenTomatoesScore
    }
    
    private var communityReviews: [String] {
        // Real reviews from backend API
        return movie.communityReviews ?? []
    }
    
    var body: some View {
        // Unified card structure - everything moves together
        Group {
        VStack(spacing: 0) {
            // Image Carousel - Top part of card
            ZStack {
                if !movieImages.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(0..<movieImages.count, id: \.self) { index in
                            CachedAsyncImage(url: movieImages[index]) { image in
                image
                    .resizable()
                                    .scaledToFill()
            } placeholder: {
                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("Loading...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            .frame(height: 250)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 250)
                }
                
                // Gradient overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 25
                )
            )
            
            // Card Content - Bottom part with glassmorphism background
            VStack(alignment: .leading, spacing: 12) {
            // Movie Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            HStack(spacing: 16) {
                                if let releaseDate = movie.releaseDate {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                        Text(releaseDate.prefix(4))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                if let voteAverage = movie.voteAverage, voteAverage > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(String(format: "%.1f", voteAverage))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                // Rotten Tomatoes Score
                                if let rtScore = rottenTomatoesScore, rtScore > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "tomato")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                        Text("\(rtScore)%")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Overview
                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(4)
                            .lineSpacing(2)
                    }
                    
                    // Genre Tags (if available)
                    if let genreIds = movie.genreIds, !genreIds.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(genreIds.prefix(3), id: \.self) { genreId in
                                    Text(genreName(for: genreId))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground).opacity(0.95),
                        Color(.systemBackground).opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 25,
                    bottomTrailingRadius: 25,
                    topTrailingRadius: 25
                )
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 25,
                    bottomTrailingRadius: 25,
                    topTrailingRadius: 25
                )
            )
        }
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        .sheet(isPresented: $showingTrailer) {
            TrailerView(movie: movie)
        }
        .sheet(isPresented: $showingReviews) {
            CommunityReviewsView(movie: movie, reviews: communityReviews)
        }
        }
    }
    
    private func genreName(for id: Int) -> String {
        switch id {
        case 28: return "Action"
        case 12: return "Adventure"
        case 16: return "Animation"
        case 35: return "Comedy"
        case 80: return "Crime"
        case 99: return "Documentary"
        case 18: return "Drama"
        case 10751: return "Family"
        case 14: return "Fantasy"
        case 36: return "History"
        case 27: return "Horror"
        case 10402: return "Music"
        case 9648: return "Mystery"
        case 10749: return "Romance"
        case 878: return "Sci-Fi"
        case 10770: return "TV Movie"
        case 53: return "Thriller"
        case 10752: return "War"
        case 37: return "Western"
        default: return "Movie"
    }
}

private func shareMovie(movie: Movie) {
    let movieURL = "https://moviedrop.app/m/\(movie.id)"
    let messageContent = """
    🎬 \(movie.title)
    
    \(movie.overview ?? "Check out this movie!")
    
    Watch it here: \(movieURL)
    
    📱 Get the MovieDrop app for the best experience!
    """
    
    let activityViewController = UIActivityViewController(
        activityItems: [messageContent, URL(string: movieURL)!],
        applicationActivities: nil
    )
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.rootViewController?.present(activityViewController, animated: true)
    }
}

struct TrailerView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Trailer for \(movie.title)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Trailer functionality coming soon!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    
                    Spacer()
            }
            .navigationTitle("Trailer")
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
}

struct CommunityReviewsView: View {
    let movie: Movie
    let reviews: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Movie Header
                HStack {
                        CachedAsyncImage(url: movie.posterURL) { image in
                        image
                            .resizable()
                                .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                        .frame(width: 80, height: 120)
                    .cornerRadius(8)
                    
                        VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let releaseDate = movie.releaseDate {
                                Text(releaseDate.prefix(4))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let voteAverage = movie.voteAverage, voteAverage > 0 {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f/10", voteAverage))
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                    
                    // Reviews Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Community Reviews")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(Array(reviews.enumerated()), id: \.offset) { index, review in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text("U\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("User \(index + 1)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            ForEach(0..<5) { star in
                                                Image(systemName: star < 4 ? "star.fill" : "star")
                                                    .foregroundColor(.yellow)
                            .font(.caption)
                                            }
                                        }
                    }
                    
                    Spacer()
                }
                                
                                Text(review)
                                    .font(.body)
                                    .padding(.leading, 40)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Reviews")
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
}

struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryView()
    }
}
