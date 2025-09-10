// MovieDrop Web App JavaScript

// Smooth scrolling for navigation links
document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for anchor links
    const links = document.querySelectorAll('a[href^="#"]');
    links.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add scroll effect to header
    const header = document.querySelector('.header');
    let lastScrollY = window.scrollY;

    window.addEventListener('scroll', () => {
        const currentScrollY = window.scrollY;
        
        if (currentScrollY > 100) {
            header.style.background = 'rgba(255, 255, 255, 0.95)';
            header.style.backdropFilter = 'blur(10px)';
        } else {
            header.style.background = '#fff';
            header.style.backdropFilter = 'none';
        }
        
        lastScrollY = currentScrollY;
    });

    // Animate elements on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe feature cards and steps
    const animatedElements = document.querySelectorAll('.feature-card, .step');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Movie Card Page Functionality
class MovieCardPage {
    constructor() {
        this.movieId = this.getMovieIdFromURL();
        if (this.movieId) {
            this.loadMovieData();
        }
    }

    getMovieIdFromURL() {
        const path = window.location.pathname;
        const match = path.match(/\/movie\/(\d+)/);
        return match ? match[1] : null;
    }

    async loadMovieData() {
        try {
            // In a real app, this would fetch from your backend API
            const movieData = await this.fetchMovieData(this.movieId);
            this.renderMovieCard(movieData);
        } catch (error) {
            console.error('Error loading movie data:', error);
            this.showError();
        }
    }

    async fetchMovieData(movieId) {
        // Mock data - replace with actual API call
        return {
            id: movieId,
            title: "Dune: Part Two",
            overview: "Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.",
            posterPath: "/8b8R8l88Qje9dnOMOEKTziywK8S.jpg",
            releaseDate: "2024-03-01",
            voteAverage: 8.2,
            streamingInfo: [
                {
                    platform: "Netflix",
                    type: "subscription",
                    url: "https://netflix.com",
                    price: null
                },
                {
                    platform: "Amazon Prime Video",
                    type: "subscription",
                    url: "https://amazon.com",
                    price: null
                },
                {
                    platform: "Apple TV",
                    type: "rent",
                    url: "https://tv.apple.com",
                    price: "$3.99"
                },
                {
                    platform: "YouTube Movies",
                    type: "rent",
                    url: "https://youtube.com",
                    price: "$3.99"
                }
            ]
        };
    }

    renderMovieCard(movie) {
        const container = document.querySelector('.movie-card-container');
        if (!container) return;

        container.innerHTML = `
            <div class="movie-header">
                <div class="movie-poster-large">
                    <img src="https://image.tmdb.org/t/p/w500${movie.posterPath}" 
                         alt="${movie.title}" 
                         onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div style="display: none; align-items: center; justify-content: center; font-size: 4rem;">🎬</div>
                </div>
                <div class="movie-details">
                    <h1>${movie.title}</h1>
                    <div class="movie-meta">
                        <span>⭐ ${movie.voteAverage}/10</span>
                        <span>📅 ${new Date(movie.releaseDate).getFullYear()}</span>
                    </div>
                    <p class="movie-overview">${movie.overview}</p>
                </div>
            </div>
            <div class="streaming-section">
                <h2>Where to Watch</h2>
                <div class="streaming-options">
                    ${movie.streamingInfo.map(option => `
                        <div class="streaming-option">
                            <h3>${option.platform}</h3>
                            <div class="price">${option.price || 'Included with subscription'}</div>
                            <a href="${option.url}" class="btn btn-primary" target="_blank">
                                ${this.getButtonText(option.type)}
                            </a>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;

        // Add affiliate tracking
        this.addAffiliateTracking();
    }

    getButtonText(type) {
        switch (type) {
            case 'subscription': return 'Watch Now';
            case 'rent': return 'Rent Now';
            case 'buy': return 'Buy Now';
            case 'free': return 'Watch Free';
            default: return 'Watch Now';
        }
    }

    addAffiliateTracking() {
        // Add affiliate tracking to streaming links
        const links = document.querySelectorAll('.streaming-option a');
        links.forEach(link => {
            link.addEventListener('click', (e) => {
                // Track affiliate click
                this.trackAffiliateClick(link.href);
            });
        });
    }

    trackAffiliateClick(url) {
        // Send tracking data to your analytics service
        console.log('Affiliate click tracked:', url);
        
        // Example: Send to your backend
        fetch('/api/track-click', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                url: url,
                movieId: this.movieId,
                timestamp: new Date().toISOString()
            })
        }).catch(error => {
            console.error('Error tracking click:', error);
        });
    }

    showError() {
        const container = document.querySelector('.movie-card-container');
        if (container) {
            container.innerHTML = `
                <div style="padding: 3rem; text-align: center;">
                    <h2>Movie Not Found</h2>
                    <p>The movie you're looking for could not be found.</p>
                    <a href="/" class="btn btn-primary">Back to Home</a>
                </div>
            `;
        }
    }
}

// Initialize movie card page if we're on a movie page
if (window.location.pathname.includes('/movie/')) {
    new MovieCardPage();
}

// Share functionality
function shareMovieCard() {
    if (navigator.share) {
        navigator.share({
            title: 'Check out this movie!',
            text: 'Found this great movie on MovieDrop',
            url: window.location.href
        });
    } else {
        // Fallback: copy to clipboard
        navigator.clipboard.writeText(window.location.href).then(() => {
            alert('Link copied to clipboard!');
        });
    }
}

// Add share button if on movie page
if (window.location.pathname.includes('/movie/')) {
    document.addEventListener('DOMContentLoaded', () => {
        const shareButton = document.createElement('button');
        shareButton.textContent = 'Share';
        shareButton.className = 'btn btn-secondary';
        shareButton.style.marginTop = '1rem';
        shareButton.onclick = shareMovieCard;
        
        const streamingSection = document.querySelector('.streaming-section');
        if (streamingSection) {
            streamingSection.appendChild(shareButton);
        }
    });
}
