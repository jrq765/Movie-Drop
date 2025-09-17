import SwiftUI

struct TinderMovieView: View {
    @StateObject private var movieService = MovieService()
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var showingMovieDetail = false
    @State private var selectedMovie: Movie?
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    
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
                    // Movie Cards Stack
                    ZStack {
                        ForEach(Array(movies.enumerated().reversed()), id: \.element.id) { index, movie in
                            if index >= currentIndex {
                                MovieCardView(movie: movie) {
                                    selectedMovie = movie
                                    showingMovieDetail = true
                                }
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
                                            dragOffset = value.translation
                                            rotationAngle = Double(value.translation.width / 20)
                                        }
                                        .onEnded { value in
                                            handleSwipeEnd(value: value)
                                        } : nil
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Action Buttons
                if !isLoading && !movies.isEmpty && currentIndex < movies.count {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 40) {
                            // Pass Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    passMovie()
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            
                            // Like Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    likeMovie()
                                }
                            }) {
                                Image(systemName: "heart.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            
                            // Watchlist Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    addToWatchlist()
                                }
                            }) {
                                Image(systemName: "bookmark.fill")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadPopularMovies()
                    }
                }
            }
            .sheet(isPresented: $showingMovieDetail) {
                if let movie = selectedMovie {
                    MovieDetailView(movie: movie, streamingService: StreamingService())
                }
            }
        }
        .onAppear {
            loadPopularMovies()
        }
    }
    
    private func loadPopularMovies() {
        isLoading = true
        currentIndex = 0
        
        Task {
            do {
                let results = try await movieService.getPopularMovies()
                await MainActor.run {
                    movies = results
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to load popular movies: \(error)")
                    isLoading = false
                }
            }
        }
    }
    
    private func handleSwipeEnd(value: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        withAnimation(.spring()) {
            if abs(value.translation.width) > threshold {
                if value.translation.width > 0 {
                    // Swiped right - Like
                    likeMovie()
                } else {
                    // Swiped left - Pass
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
        print("❤️ Liked: \(movies[currentIndex].title)")
        // Here you would typically save to user's liked movies
        nextMovie()
    }
    
    private func passMovie() {
        print("❌ Passed: \(movies[currentIndex].title)")
        // Here you would typically save to user's passed movies
        nextMovie()
    }
    
    private func addToWatchlist() {
        print("📝 Added to watchlist: \(movies[currentIndex].title)")
        // Here you would typically save to user's watchlist
        nextMovie()
    }
    
    private func nextMovie() {
        withAnimation(.spring()) {
            currentIndex += 1
            dragOffset = .zero
            rotationAngle = 0
        }
    }
}

#Preview {
    TinderMovieView()
}
