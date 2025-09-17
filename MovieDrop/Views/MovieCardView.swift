import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let onTap: () -> Void
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    @State private var showingTrailer = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 0) {
                    // Movie Poster/Backdrop
                    AsyncImage(url: movie.backdropURL ?? movie.posterURL) { image in
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
                    .frame(height: 400)
                    .clipped()
                    .overlay(
                        // Gradient overlay for better text readability
                        LinearGradient(
                            gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Movie Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movie.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                HStack {
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
                                    
                                    Spacer()
                                }
                            }
                            
                            Spacer()
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                // Trailer Button
                                Button(action: { showingTrailer = true }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 40, height: 40)
                                        )
                                }
                                
                                // Share Button
                                Button(action: shareMovie) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 40, height: 40)
                                        )
                                }
                            }
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
                        
                        // Streaming Platforms
                        HStack {
                            Text("Available on:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Mock streaming platform icons
                            HStack(spacing: 8) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "play.fill")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .offset(dragOffset)
        .rotationEffect(.degrees(rotationAngle))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    rotationAngle = Double(value.translation.width / 20)
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        rotationAngle = 0
                    }
                }
        )
        .sheet(isPresented: $showingTrailer) {
            TrailerView(movie: movie)
        }
    }
    
    private func shareMovie() {
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

#Preview {
    MovieCardView(
        movie: Movie(
            id: 1,
            title: "Inception",
            overview: "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O.",
            releaseDate: "2010-07-16",
            posterPath: "/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
            backdropPath: "/s3TBrRGB1iav7gFOCNx3H31MoES.jpg",
            voteAverage: 8.4,
            genreIds: [28, 878, 12]
        )
    ) {
        print("Movie tapped")
    }
    .padding()
}
