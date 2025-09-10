interface MovieData {
  id: number
  title: string
  overview: string
  release_date: string
  runtime: number
  vote_average: number
  poster_path: string | null
  backdrop_path: string | null
}

interface WatchProvider {
  provider_id: number
  provider_name: string
  logo_path: string | null
  link: string
}

interface WatchProvidersResponse {
  flatrate?: WatchProvider[]
  rent?: WatchProvider[]
  buy?: WatchProvider[]
}

const TMDB_API_KEY = process.env.TMDB_API_KEY
const TMDB_BASE_URL = 'https://api.themoviedb.org/3'
export const TMDB_IMAGE_BASE = process.env.TMDB_IMAGE_BASE ?? "https://image.tmdb.org/t/p"

if (!TMDB_API_KEY) {
  console.error(`
❌ TMDB_API_KEY environment variable is missing!

RESTORATION CHECKLIST:
1. Set TMDB_API_KEY in your environment variables
2. Get your API key from: https://www.themoviedb.org/settings/api
3. Add to .env.local: TMDB_API_KEY=your_api_key_here
4. Optional: Set NEXT_PUBLIC_REGION_DEFAULT=US
5. Optional: Set TMDB_IMAGE_BASE=https://image.tmdb.org/t/p

Test with curl:
curl "https://api.themoviedb.org/3/movie/550?api_key=YOUR_KEY"
curl "https://api.themoviedb.org/3/movie/550/watch/providers?api_key=YOUR_KEY"
`)
  throw new Error('TMDB_API_KEY environment variable is required')
}

export function posterUrl(path?: string, size: "w500"|"w780"|"original"="w780"): string | null {
  return path ? `${TMDB_IMAGE_BASE}/${size}${path}` : null
}

export function providerLogo(path?: string): string | null {
  return path ? `${TMDB_IMAGE_BASE}/w45${path}` : null
}

export async function fetchMovie(id: string): Promise<MovieData> {
  const response = await fetch(
    `${TMDB_BASE_URL}/movie/${id}?api_key=${TMDB_API_KEY}`,
    {
      next: { revalidate: 3600 }, // Cache for 1 hour
    }
  )

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Movie not found')
    }
    console.error(`
❌ TMDB API request failed!

RESTORATION CHECKLIST:
1. Verify TMDB_API_KEY is correct
2. Check API key permissions at: https://www.themoviedb.org/settings/api
3. Test with curl: curl "https://api.themoviedb.org/3/movie/${id}?api_key=YOUR_KEY"
4. Check rate limits (40 requests per 10 seconds)
`)
    throw new Error(`Failed to fetch movie data: ${response.status}`)
  }

  return response.json()
}

export async function fetchProviders(id: string, region: string = 'US'): Promise<WatchProvidersResponse | null> {
  try {
    const response = await fetch(
      `${TMDB_BASE_URL}/movie/${id}/watch/providers?api_key=${TMDB_API_KEY}`,
      {
        next: { revalidate: 3600 }, // Cache for 1 hour
      }
    )

    if (!response.ok) {
      console.error(`Failed to fetch watch providers: ${response.status}`)
      return null
    }

    const data = await response.json()
    const regionData = data.results[region]

    if (!regionData) {
      return null
    }

    // Transform the data to include links (using JustWatch deep links)
    const transformProviders = (providers: any[]): WatchProvider[] => {
      return providers.map(provider => ({
        provider_id: provider.provider_id,
        provider_name: provider.provider_name,
        logo_path: provider.logo_path,
        link: `https://www.justwatch.com/us/movie/${id}` // JustWatch deep link
      }))
    }

    const result: WatchProvidersResponse = {}

    if (regionData.flatrate) {
      result.flatrate = transformProviders(regionData.flatrate)
    }
    if (regionData.rent) {
      result.rent = transformProviders(regionData.rent)
    }
    if (regionData.buy) {
      result.buy = transformProviders(regionData.buy)
    }

    return result
  } catch (error) {
    console.error('Error fetching watch providers:', error)
    return null
  }
}

// Legacy exports for backward compatibility
export const getMovieData = fetchMovie
export const getWatchProviders = fetchProviders
