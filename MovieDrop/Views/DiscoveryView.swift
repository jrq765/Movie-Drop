import SwiftUI

struct DiscoveryView: View {
    @StateObject private var movieService = MovieService()
    @State private var movies: [Movie] = []
    @State private var currentIndex = 0
    @State private var isLoading = false
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    @State private var showingWatchlist = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Header
                    HStack {
                        Text("Discover")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showingWatchlist = true
                        }) {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.97, green: 0.33, blue: 0.21))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Movie Cards Stack
                    ZStack {
                        if isLoading {
                            ProgressView("Loading movies...")
                                .foregroundColor(.white)
                        } else if movies.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "film.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                
                                Text("No more movies to discover!")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Button("Load More Movies") {
                                    loadMovies()
                                }
                                .padding()
                                .background(Color(red: 0.97, green: 0.33, blue: 0.21))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        } else {
                            // Show next 3 movies in stack
                            ForEach(0..<min(3, movies.count - currentIndex), id: \.self) { index in
                                let movieIndex = currentIndex + index
                                if movieIndex < movies.count {
                                    MovieCard(
                                        movie: movies[movieIndex],
                                        isTop: index == 0,
                                        dragOffset: index == 0 ? dragOffset : .zero,
                                        rotationAngle: index == 0 ? rotationAngle : 0,
                                        onSwipeLeft: {
                                            swipeLeft()
                                        },
                                        onSwipeRight: {
                                            swipeRight()
                                        }
                                    )
                                    .zIndex(Double(3 - index))
                                    .scaleEffect(index == 0 ? 1.0 : 0.9 - (Double(index) * 0.05))
                                    .offset(y: Double(index) * 10)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        // Pass Button
                        Button(action: {
                            swipeLeft()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        
                        // Add to Watchlist Button
                        Button(action: {
                            swipeRight()
                        }) {
                            Image(systemName: "heart.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color(red: 0.97, green: 0.33, blue: 0.21))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if movies.isEmpty {
                loadMovies()
            }
        }
        .sheet(isPresented: $showingWatchlist) {
            WatchlistView()
        }
    }
    
    private func loadMovies() {
        isLoading = true
        
        // Load popular movies for discovery
        Task {
            do {
                let popularMovies = try await movieService.fetchPopularMovies()
                await MainActor.run {
                    self.movies = popularMovies
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func swipeLeft() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentIndex += 1
            dragOffset = .zero
            rotationAngle = 0
        }
    }
    
    private func swipeRight() {
        // Add to watchlist
        if currentIndex < movies.count {
            let movie = movies[currentIndex]
            // TODO: Add to watchlist via API
            print("Added to watchlist: \(movie.title)")
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentIndex += 1
            dragOffset = .zero
            rotationAngle = 0
        }
    }
}

struct MovieCard: View {
    let movie: Movie
    let isTop: Bool
    let dragOffset: CGSize
    let rotationAngle: Double
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var dragAmount = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Movie Poster
            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.posterPath ?? "")")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
            .frame(height: 500)
            .clipped()
            
            // Movie Info
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(movie.overview ?? "No overview available")
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(4)
                
                HStack {
                    Text("⭐ \(String(format: "%.1f", movie.voteAverage ?? 0.0))")
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Text((movie.releaseDate ?? "").prefix(4))
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.8))
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .offset(dragAmount)
        .rotationEffect(.degrees(rotationAngle))
        .gesture(
            isTop ? DragGesture()
                .onChanged { value in
                    dragAmount = value.translation
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    
                    if value.translation.width > threshold {
                        // Swipe right - add to watchlist
                        onSwipeRight()
                    } else if value.translation.width < -threshold {
                        // Swipe left - pass
                        onSwipeLeft()
                    } else {
                        // Return to center
                        withAnimation(.spring()) {
                            dragAmount = .zero
                        }
                    }
                } : nil
        )
    }
}

struct WatchlistView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var watchlist: [Movie] = []
    
    var body: some View {
        NavigationView {
            List(watchlist) { movie in
                HStack {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w92\(movie.posterPath ?? "")")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(movie.title)
                            .font(.headline)
                        Text(movie.overview ?? "No overview available")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("My Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct DiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoveryView()
    }
}
