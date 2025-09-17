import SwiftUI

struct WatchlistView: View {
    @StateObject private var movieService = MovieService()
    @StateObject private var authService = AuthService()
    @State private var watchlistMovies: [Movie] = []
    @State private var isLoading = true
    @State private var selectedMovie: Movie?
    @State private var showingMovieDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your watchlist...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if watchlistMovies.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Your Watchlist is Empty")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Start swiping to add movies to your watchlist!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(watchlistMovies) { movie in
                                WatchlistMovieCard(movie: movie) {
                                    selectedMovie = movie
                                    showingMovieDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("My Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadWatchlist()
            }
            .sheet(isPresented: $showingMovieDetail) {
                if let movie = selectedMovie {
                    MovieDetailView(movie: movie, streamingService: StreamingService())
                }
            }
        }
    }
    
    private func loadWatchlist() {
        Task {
            do {
                if let user = authService.currentUser {
                    let movies = try await movieService.getWatchlist(userId: user.id)
                    await MainActor.run {
                        watchlistMovies = movies
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        watchlistMovies = []
                        isLoading = false
                    }
                }
            } catch {
                print("❌ Failed to load watchlist: \(error)")
                await MainActor.run {
                    watchlistMovies = []
                    isLoading = false
                }
            }
        }
    }
}

struct WatchlistMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                .cornerRadius(8)
                .clipped()
                
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
                    
                    if let voteAverage = movie.voteAverage, voteAverage > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", voteAverage))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Remove from watchlist button
                Button(action: {
                    // Remove from watchlist functionality
                }) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
    }
}
