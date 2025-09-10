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

if (!TMDB_API_KEY) {
  throw new Error('TMDB_API_KEY environment variable is required')
}

export async function getMovieData(movieId: string): Promise<MovieData> {
  const response = await fetch(
    `${TMDB_BASE_URL}/movie/${movieId}?api_key=${TMDB_API_KEY}`,
    {
      next: { revalidate: 3600 }, // Cache for 1 hour
    }
  )

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Movie not found')
    }
    throw new Error(`Failed to fetch movie data: ${response.status}`)
  }

  return response.json()
}

export async function getWatchProviders(
  movieId: string, 
  region: string = 'US'
): Promise<WatchProvidersResponse | null> {
  try {
    const response = await fetch(
      `${TMDB_BASE_URL}/movie/${movieId}/watch/providers?api_key=${TMDB_API_KEY}`,
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
        link: `https://www.justwatch.com/us/movie/${movieId}` // JustWatch deep link
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
