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
  kind: string
}

interface WatchProvidersResponse {
  flatrate?: WatchProvider[]
  rent?: WatchProvider[]
  buy?: WatchProvider[]
}

const MOVIEDROP_API_BASE = process.env.MOVIEDROP_API_BASE || 'https://perceptive-flow-production.up.railway.app/api'
export const TMDB_IMAGE_BASE = process.env.TMDB_IMAGE_BASE ?? "https://image.tmdb.org/t/p"

export function posterUrl(path?: string, size: "w500"|"w780"|"original"="w780"): string | null {
  return path ? `${TMDB_IMAGE_BASE}/${size}${path}` : null
}

export function providerLogo(path?: string): string | null {
  return path ? `${TMDB_IMAGE_BASE}/w45${path}` : null
}

export async function fetchMovie(id: string): Promise<MovieData> {
  const response = await fetch(
    `${MOVIEDROP_API_BASE}/movies/${id}`,
    {
      next: { revalidate: 3600 }, // Cache for 1 hour
    }
  )

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Movie not found')
    }
    console.error(`❌ MovieDrop API request failed: ${response.status}`)
    throw new Error(`Failed to fetch movie data: ${response.status}`)
  }

  return response.json()
}

export async function fetchProviders(id: string, region: string = 'US'): Promise<WatchProvider[] | null> {
  try {
    const response = await fetch(
      `${MOVIEDROP_API_BASE}/streaming/${id}?region=${region}`,
      {
        next: { revalidate: 3600 }, // Cache for 1 hour
      }
    )

    if (!response.ok) {
      console.error(`Failed to fetch watch providers: ${response.status}`)
      return null
    }

    const data = await response.json()

    // Transform the combined providers data
    const providers: WatchProvider[] = data.providers.map((provider: any) => ({
      provider_id: provider.provider_id,
      provider_name: provider.name, // Use the combined name
      logo_path: provider.logo_path,
      link: provider.url, // Use the direct URL from our API
      kind: provider.kind // Add kind for display
    }))

    return providers
  } catch (error) {
    console.error('Error fetching watch providers:', error)
    return null
  }
}

// Legacy exports for backward compatibility
export const getMovieData = fetchMovie
export const getWatchProviders = fetchProviders
