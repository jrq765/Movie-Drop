/**
 * Centralized URL management for MovieDrop
 * Single source of truth for all link generation
 */

// Environment-based configuration
export const CANONICAL_WEB_BASE = process.env.NEXT_PUBLIC_CANONICAL_WEB_BASE || "https://moviedrop.app";
export const FRAMER_FALLBACK_BASE = process.env.NEXT_PUBLIC_FRAMER_FALLBACK_BASE || "https://moviedrop.framer.website";
export const API_BASE = process.env.NEXT_PUBLIC_API_BASE || `${CANONICAL_WEB_BASE}/api`;

/**
 * Generate canonical movie card URL
 * @param id - TMDB movie ID
 * @param region - Region code (default: US)
 * @returns Canonical URL for movie card
 */
export function cardUrl(id: string | number, region: string = "US"): string {
  return `${CANONICAL_WEB_BASE}/m/${id}?region=${region}`;
}

/**
 * Generate Framer fallback URL for web users
 * @param id - TMDB movie ID  
 * @param region - Region code (default: US)
 * @returns Framer URL for movie page
 */
export function framerUrl(id: string | number, region: string = "US"): string {
  return `${FRAMER_FALLBACK_BASE}/m/${id}?region=${region}`;
}

/**
 * Generate API streaming endpoint URL
 * @param id - TMDB movie ID
 * @param region - Region code (default: US)
 * @returns API URL for streaming data
 */
export function streamingApiUrl(id: string | number, region: string = "US"): string {
  return `${API_BASE}/streaming/${id}?region=${region}`;
}

/**
 * Generate API movie details endpoint URL
 * @param id - TMDB movie ID
 * @param region - Region code (default: US)
 * @returns API URL for movie details
 */
export function movieApiUrl(id: string | number, region: string = "US"): string {
  return `${API_BASE}/m/${id}?region=${region}`;
}

/**
 * Validate that URLs use canonical domain
 * @param url - URL to validate
 * @returns true if URL uses canonical domain
 */
export function isCanonicalUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.hostname === new URL(CANONICAL_WEB_BASE).hostname;
  } catch {
    return false;
  }
}

/**
 * Get environment configuration for debugging
 */
export function getConfig() {
  return {
    CANONICAL_WEB_BASE,
    FRAMER_FALLBACK_BASE,
    API_BASE,
    NODE_ENV: process.env.NODE_ENV
  };
}
