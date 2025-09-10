import UIKit
import Messages
import ImageIO
import MobileCoreServices
import os.log

// MARK: - Logging Helper
enum MDLog {
    private static let log = OSLog(subsystem: "app.moviedrop.messages", category: "card")
    static func info(_ message: String)  { os_log("%{public}@", log: log, type: .info,  message) }
    static func error(_ message: String) { os_log("%{public}@", log: log, type: .error, message) }
}

// MARK: - Safe Image Loader
enum ImageLoader {
    static func fetchDownsampled(_ url: URL?, maxPixel: CGFloat = 1024) async -> UIImage? {
        guard let url = url else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return downsample(data: data, maxPixel: maxPixel)
        } catch { return nil }
    }

    private static func downsample(data: Data, maxPixel: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let src = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
        let dsOpts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, dsOpts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg, scale: UIScreen.main.scale, orientation: .up)
    }
}

// MARK: - Message Composer
struct MovieCardData {
    let id: String
    let title: String
    let overview: String?
    let releaseDate: String?
    let posterURL: URL?
}

enum MessageComposer {
    static func buildURL(base: String, movieId: String, region: String = "US") -> URL? {
        var comps = URLComponents(string: base)
        comps?.path = "/m/\(movieId)"
        comps?.queryItems = [URLQueryItem(name: "region", value: region)]
        return comps?.url
    }

    static func releaseYear(from date: String?) -> String {
        guard let d = date, d.count >= 4 else { return "" }
        return String(d.prefix(4))
    }

    @MainActor
    static func makeMessage(card: MovieCardData, poster: UIImage?, universalBaseURL: String, region: String = "US") -> MSMessage? {
        let session = MSSession()
        let layout = MSMessageTemplateLayout()
        layout.image = poster
        layout.imageTitle = card.title
        layout.imageSubtitle = releaseYear(from: card.releaseDate)
        layout.caption = (card.overview?.isEmpty == false ? card.overview : "Shared via MovieDrop")

        let message = MSMessage(session: session)
        message.layout = layout
        message.summaryText = "\(card.title)\(layout.imageSubtitle?.isEmpty == false ? " • \(layout.imageSubtitle!)" : "")"

        if let url = buildURL(base: universalBaseURL, movieId: card.id, region: region) {
            message.url = url
        }
        return message
    }
}

// MARK: - Properties
private var universalBaseURL: String {
    return Bundle.main.object(forInfoDictionaryKey: "MOVIEDROP_BASE_URL") as? String ?? "https://moviedrop.app"
}

class MessagesViewController: MSMessagesAppViewController {
    
    private var movieService = MovieService()
    private var searchResults: [Movie] = []
    private var selectedMovie: Movie?
    private var tableView: UITableView!
    private var searchBar: UISearchBar!
    private var emptyStateLabel: UILabel!
    private var isInserting = false // Debounce flag to prevent multiple inserts
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔧 MessagesViewController: viewDidLoad called")
        print("🔧 MessagesViewController: View frame: \(view.frame)")
        print("🔧 MessagesViewController: View bounds: \(view.bounds)")
        setupUI()
    }
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        print("🔧 MessagesViewController: willBecomeActive called")
    }
    
    override func didBecomeActive(with conversation: MSConversation) {
        super.didBecomeActive(with: conversation)
        print("🔧 MessagesViewController: didBecomeActive called")
    }
    
    private func setupUI() {
        print("🔧 MessagesViewController: setupUI called")
        print("🔧 MessagesViewController: Setting up UI with view frame: \(view.frame)")
        view.backgroundColor = .systemBackground
        
        // Create a container view for better layout
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.text = "🎬 MovieDrop"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        
        // Add subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Search and share movies with friends!"
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Create search bar
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for movies..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        containerView.addSubview(searchBar)
        
        // Create table view
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MovieTableViewCell.self, forCellReuseIdentifier: "MovieCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        
        // Ensure table view is properly configured for selection
        tableView.allowsSelection = true
        tableView.isUserInteractionEnabled = true
        
        // Add a tap gesture recognizer to test if the table view is receiving touches
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped(_:)))
        tableView.addGestureRecognizer(tapGesture)
        
        containerView.addSubview(tableView)
        print("🎬 Table view configured with delegate and data source")
        
        // Add empty state label
        let emptyStateLabel = UILabel()
        emptyStateLabel.text = "Start typing to search for movies..."
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = .tertiaryLabel
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.tag = 999 // Tag for easy access
        containerView.addSubview(emptyStateLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Empty state
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
        
        self.tableView = tableView
        self.searchBar = searchBar
        self.emptyStateLabel = emptyStateLabel
        
        print("🔧 MessagesViewController: UI setup complete")
    }
    
    private func searchMovies(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            updateUI()
            return
        }
        
        print("🔍 Searching for: \(query)")
        
        movieService.searchMovies(query: query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let movies):
                    print("✅ Found \(movies.count) movies")
                    self?.searchResults = movies
                    self?.updateUI()
                case .failure(let error):
                    print("❌ Search error: \(error)")
                    self?.searchResults = []
                    self?.updateUI()
                }
            }
        }
    }
    
    private func updateUI() {
        tableView.reloadData()
        emptyStateLabel.isHidden = !searchResults.isEmpty
    }
    
    private func createMovieCard(for movie: Movie) {
        print("🎬 Creating movie card for: \(movie.title)")
        print("🎬 Movie ID: \(movie.id)")
        print("🎬 Movie poster path: \(movie.posterPath ?? "nil")")
        print("🎬 About to call movieService.createMovieCard...")
        
        movieService.createMovieCard(movie: movie) { [weak self] result in
            print("🎬 MovieService.createMovieCard callback received")
            DispatchQueue.main.async {
                switch result {
                case .success(let movieCard):
                    print("✅ Movie card created successfully for: \(movieCard.movie.title)")
                    print("✅ Streaming info count: \(movieCard.streamingInfo.count)")
                    print("✅ Share URL: \(movieCard.shareURL)")
                    print("🎬 About to call sendMovieCard...")
                    self?.sendMovieCard(movieCard)
                case .failure(let error):
                    print("❌ Error creating movie card: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Movie Selection Handling
    @MainActor
    func handleMovieSelection(_ movie: Movie) {
        MDLog.info("handleMovieSelection called for: \(movie.title)")
        
        // Debounce: prevent multiple rapid taps
        guard !isInserting else {
            MDLog.info("Already inserting, ignoring tap")
            return
        }
        
        isInserting = true
        
        let card = MovieCardData(
            id: String(movie.id),
            title: movie.title,
            overview: movie.overview,
            releaseDate: movie.releaseDate,
            posterURL: movie.posterURL
        )
        
        Task { [weak self] in
            guard let self else { return }
            let poster = await ImageLoader.fetchDownsampled(card.posterURL, maxPixel: 1024)
            
            guard let messagesVC = sequence(first: self.parent, next: { $0?.parent })
                    .first(where: { $0 is MSMessagesAppViewController }) as? MSMessagesAppViewController
            else {
                self.isInserting = false
                MDLog.error("MSMessagesAppViewController not found")
                return
            }
            
            guard let message = MessageComposer.makeMessage(card: card, poster: poster, universalBaseURL: universalBaseURL, region: "US") else {
                self.isInserting = false
                MDLog.error("Failed to compose message")
                return
            }
            
            guard let convo = messagesVC.activeConversation else {
                self.isInserting = false
                MDLog.error("activeConversation is nil")
                return
            }
            
            convo.insert(message) { [weak self] error in
                guard let self else { return }
                self.isInserting = false
                if let error = error {
                    MDLog.error("insert(message) failed: \(error.localizedDescription)")
                    // Fallback: at least insert text so user can share something
                    convo.insertText("MovieDrop: \(card.title)", completionHandler: nil)
                } else {
                    messagesVC.requestPresentationStyle(.compact) // show Send button immediately
                }
            }
        }
    }
    
    private func sendMovieCard(_ movieCard: MovieCard) {
        print("🎬 sendMovieCard called for: \(movieCard.movie.title)")
        print("🎬 Active conversation: \(activeConversation != nil ? "Available" : "Nil")")
        print("🎬 Presentation style: \(presentationStyle.rawValue)")
        
        // Ensure we're in the right presentation style
        requestPresentationStyle(.compact)
        
        let message = MSMessage()
        
        // Create a rich message that will use cellular/WiFi instead of satellite
        // Create a URL for the movie card
        var components = URLComponents()
        components.scheme = "https"
        components.host = "moviedrop.app"
        components.path = "/movie/\(movieCard.movie.id)"
        message.url = components.url
        
        // Create a layout for the message
        let layout = MSMessageTemplateLayout()
        layout.image = createMovieCardImage(movieCard)
        layout.caption = "I recommend you watch this!"
        
        let movieTitle = movieCard.movie.title
        let streamingInfo = movieCard.streamingInfo.isEmpty ? "Streaming info coming soon!" : 
            movieCard.streamingInfo.prefix(3).map { $0.platform }.joined(separator: ", ")
        
        layout.subcaption = "🎬 \(movieTitle) - Available on: \(streamingInfo)"
        message.layout = layout
        message.summaryText = "🎬 \(movieTitle)"
        
        print("🎬 Sending rich movie card for: \(movieCard.movie.title)")
        print("🎬 Streaming platforms: \(movieCard.streamingInfo.map { $0.platform })")
        print("🎬 Message URL: \(message.url?.absoluteString ?? "nil")")
        print("🎬 Message layout: \(layout)")
        print("🎬 Message summary: \(message.summaryText ?? "nil")")
        
        // Send the message
        guard let conversation = activeConversation else {
            print("❌ No active conversation available")
            // Try to get the conversation again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let conversation = self.activeConversation {
                    print("🎬 Got conversation on retry, sending message...")
                    conversation.insert(message) { error in
                        if let error = error {
                            print("❌ Error sending message on retry: \(error)")
                        } else {
                            print("✅ Movie card sent successfully on retry!")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.dismiss()
                            }
                        }
                    }
                } else {
                    print("❌ Still no active conversation after retry")
                }
            }
            return
        }
        
        print("🎬 Inserting message into conversation...")
        conversation.insert(message) { error in
            DispatchQueue.main.async {
            if let error = error {
                    print("❌ Error sending message: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
            } else {
                    print("✅ Movie card sent successfully!")
                    // Don't dismiss immediately - let the user see the message was sent
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss()
                    }
                }
            }
        }
    }
    
    private func createMovieCardImage(_ movieCard: MovieCard) -> UIImage? {
        // Create a custom image for the movie card
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background with gradient
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Movie poster placeholder
            let posterRect = CGRect(x: 10, y: 10, width: 80, height: 120)
            UIColor.white.withAlphaComponent(0.3).setFill()
            context.cgContext.fill(posterRect)
            
            // Movie poster icon (film strip)
            let posterIconRect = CGRect(x: 30, y: 50, width: 40, height: 40)
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: posterIconRect)
            
            // Movie title
            let titleRect = CGRect(x: 100, y: 20, width: 190, height: 30)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            movieCard.movie.title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Recommendation text
            let recommendationRect = CGRect(x: 100, y: 50, width: 190, height: 20)
            let recommendationAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            "I recommend you watch this!".draw(in: recommendationRect, withAttributes: recommendationAttributes)
            
            // Streaming platforms
            let platformsText = movieCard.streamingInfo.isEmpty ? "Streaming info unavailable" : movieCard.streamingInfo.map { $0.platform }.joined(separator: ", ")
            let platformsRect = CGRect(x: 100, y: 80, width: 190, height: 40)
            let platformsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            platformsText.draw(in: platformsRect, withAttributes: platformsAttributes)
            
            // Add a subtle border
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            context.cgContext.setLineWidth(2)
            context.cgContext.stroke(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UISearchBarDelegate
extension MessagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchMovies(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let query = searchBar.text else { return }
        searchMovies(query: query)
    }
}

// MARK: - UITableViewDataSource
extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🎬 Configuring cell for row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieTableViewCell
        let movie = searchResults[indexPath.row]
        cell.configure(with: movie)
        
        // Ensure cell is selectable
        cell.selectionStyle = .default
        cell.isUserInteractionEnabled = true
        
        print("🎬 Cell configured for movie: \(movie.title)")
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("🎬 TABLE VIEW SELECTION DETECTED!")
        tableView.deselectRow(at: indexPath, animated: true)
        let movie = searchResults[indexPath.row]
        print("🎬 User tapped on movie: \(movie.title) (ID: \(movie.id))")
        
        // Handle movie selection with new message composition
        handleMovieSelection(movie)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    @objc private func tableViewTapped(_ gesture: UITapGestureRecognizer) {
        print("🎬 TABLE VIEW TAPPED! Gesture recognized!")
        let location = gesture.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: location) {
            print("🎬 Tap detected at row: \(indexPath.row)")
            let movie = searchResults[indexPath.row]
            print("🎬 Movie at tapped row: \(movie.title)")
            
            // Manually trigger the selection
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        } else {
            print("🎬 Tap detected but no row found at location: \(location)")
        }
    }
    
}

// MARK: - Custom Table View Cell
class MovieTableViewCell: UITableViewCell {
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let releaseDateLabel = UILabel()
    private let overviewLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Ensure cell is properly configured for interaction
        self.selectionStyle = .default
        self.isUserInteractionEnabled = true
        self.contentView.isUserInteractionEnabled = true
        
        posterImageView.contentMode = .scaleAspectFit
        posterImageView.layer.cornerRadius = 8
        posterImageView.clipsToBounds = true
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.isUserInteractionEnabled = false
        
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false
        
        releaseDateLabel.font = .systemFont(ofSize: 12)
        releaseDateLabel.textColor = .secondaryLabel
        releaseDateLabel.translatesAutoresizingMaskIntoConstraints = false
        releaseDateLabel.isUserInteractionEnabled = false
        
        overviewLabel.font = .systemFont(ofSize: 12)
        overviewLabel.textColor = .secondaryLabel
        overviewLabel.numberOfLines = 2
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        overviewLabel.isUserInteractionEnabled = false
        
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(releaseDateLabel)
        contentView.addSubview(overviewLabel)
        
        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            posterImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 60),
            posterImageView.heightAnchor.constraint(equalToConstant: 90),
            
            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            releaseDateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            releaseDateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            releaseDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            overviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            overviewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            overviewLabel.topAnchor.constraint(equalTo: releaseDateLabel.bottomAnchor, constant: 4),
            overviewLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with movie: Movie) {
        print("🎬 Configuring cell for movie: \(movie.title)")
        titleLabel.text = movie.title
        releaseDateLabel.text = movie.formattedReleaseDate
        
        if let overview = movie.overview {
            overviewLabel.text = overview
        } else {
            overviewLabel.text = "No description available"
        }
        
        // Ensure cell is still properly configured for interaction
        self.selectionStyle = .default
        self.isUserInteractionEnabled = true
        self.contentView.isUserInteractionEnabled = true
        
        // Load poster image
        if let posterURL = movie.posterURL {
            URLSession.shared.dataTask(with: posterURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.posterImageView.image = image
                    }
                }
            }.resume()
        } else {
            posterImageView.image = UIImage(systemName: "film")
        }
        
        print("🎬 Cell configured with selectionStyle: \(self.selectionStyle.rawValue), isUserInteractionEnabled: \(self.isUserInteractionEnabled)")
    }
}

