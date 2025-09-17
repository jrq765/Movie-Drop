import { notFound } from 'next/navigation'
import Image from 'next/image'
import { Metadata } from 'next'
import { fetchMovie, fetchProviders, posterUrl, providerLogo } from '../../lib/tmdb'

interface MoviePageProps {
  params: {
    id: string
  }
  searchParams: {
    region?: string
  }
}

export async function generateMetadata({ params, searchParams }: MoviePageProps): Promise<Metadata> {
  try {
    const movie = await fetchMovie(params.id)
    const region = searchParams.region || process.env.NEXT_PUBLIC_REGION_DEFAULT || 'US'
    
    return {
      title: `${movie.title} – Where to Watch | MovieDrop`,
      description: movie.overview ? movie.overview.substring(0, 150) + '...' : `Watch ${movie.title} on your favorite streaming platform`,
      openGraph: {
        title: `${movie.title} – Where to Watch | MovieDrop`,
        description: movie.overview ? movie.overview.substring(0, 150) + '...' : `Watch ${movie.title} on your favorite streaming platform`,
        images: [
          {
            url: posterUrl(movie.poster_path ?? undefined, "w780") || '/logo-moviedrop.svg',
            width: 780,
            height: 1170,
            alt: movie.title,
          },
        ],
        url: `https://moviedrop.app/m/${params.id}`,
        type: 'website',
      },
      twitter: {
        card: 'summary_large_image',
        title: `${movie.title} – Where to Watch | MovieDrop`,
        description: movie.overview ? movie.overview.substring(0, 150) + '...' : `Watch ${movie.title} on your favorite streaming platform`,
        images: [
          posterUrl(movie.poster_path ?? undefined, "w780") || '/logo-moviedrop.svg'
        ],
      },
    }
  } catch (error) {
    return {
      title: 'Movie Not Found - MovieDrop',
      description: 'The requested movie could not be found.',
    }
  }
}

function copyCurrentUrl() {
  if (typeof window !== 'undefined') {
    navigator.clipboard.writeText(window.location.href)
  }
}

export default async function MoviePage({ params, searchParams }: MoviePageProps) {
  const region = searchParams.region || process.env.NEXT_PUBLIC_REGION_DEFAULT || 'US'
  
  try {
    const [movie, watchProviders] = await Promise.all([
      fetchMovie(params.id),
      fetchProviders(params.id, region)
    ])

    const releaseYear = new Date(movie.release_date).getFullYear()
    const runtime = movie.runtime ? `${Math.floor(movie.runtime / 60)}h ${movie.runtime % 60}m` : null
    const voteAverage = movie.vote_average > 0 ? movie.vote_average.toFixed(1) : null
    const providersLink = `https://www.justwatch.com/us/movie/${params.id}`

    return (
      <main className="min-h-screen bg-md-bg text-md-ink">
        {/* Header */}
        <header className="mx-auto max-w-[1120px] px-4 py-5 flex items-center gap-3">
          <img src="/logo-moviedrop.svg" alt="MovieDrop" className="h-6 w-auto" />
          <span className="sr-only">MovieDrop</span>
        </header>

        {/* Hero Card */}
        <section className="mx-auto max-w-[1120px] px-4 pb-24">
          <div className="rounded-2xl border border-md-border bg-md-surface shadow-md p-5 md:p-8 grid grid-cols-1 md:grid-cols-[320px,1fr] gap-6">
            {/* Poster */}
            {posterUrl(movie.poster_path ?? undefined) ? (
              <img 
                src={posterUrl(movie.poster_path ?? undefined, "w780")!} 
                alt={movie.title} 
                className="w-full h-auto rounded-xl object-cover" 
              />
            ) : (
              <div className="w-full aspect-[2/3] rounded-xl bg-[linear-gradient(135deg,#2A2D33,rgba(234,233,229,0.06))] grid place-items-center text-md-inkMuted">
                No poster
              </div>
            )}

            {/* Content */}
            <div className="flex min-w-0 flex-col gap-5">
              <div>
                <h1 className="text-3xl md:text-4xl font-semibold tracking-tight">{movie.title}</h1>
                <p className="mt-1 text-sm text-md-inkMuted">
                  {releaseYear} • {runtime} {voteAverage && <> • ⭐ {voteAverage}/10</>}
                </p>
              </div>

              {movie.overview && (
                <p className="text-base leading-7 text-md-inkMuted line-clamp-6">{movie.overview}</p>
              )}

              {/* Where to Watch */}
              <div className="mt-2">
                <h2 className="text-xl font-semibold mb-3">Where to Watch</h2>
                <div className="flex flex-wrap gap-2">
                  {watchProviders?.flatrate && watchProviders.flatrate.map((provider) => (
                    <a
                      key={provider.provider_id}
                      href={provider.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="group inline-flex items-center gap-2 rounded-full border border-md-border bg-white/5 hover:bg-white/10 px-3 py-1.5 text-sm"
                    >
                      {providerLogo(provider.logo_path ?? undefined) && (
                        <img 
                          src={providerLogo(provider.logo_path ?? undefined)!} 
                          alt="" 
                          className="h-4 w-4 rounded-[4px]" 
                        />
                      )}
                      <span>{provider.provider_name}</span>
                    </a>
                  ))}
                  
                  {watchProviders?.rent && watchProviders.rent.map((provider) => (
                    <a
                      key={provider.provider_id}
                      href={provider.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="group inline-flex items-center gap-2 rounded-full border border-md-border bg-white/5 hover:bg-white/10 px-3 py-1.5 text-sm"
                    >
                      {providerLogo(provider.logo_path ?? undefined) && (
                        <img 
                          src={providerLogo(provider.logo_path ?? undefined)!} 
                          alt="" 
                          className="h-4 w-4 rounded-[4px]" 
                        />
                      )}
                      <span>{provider.provider_name}</span>
                    </a>
                  ))}
                  
                  {watchProviders?.buy && watchProviders.buy.map((provider) => (
                    <a
                      key={provider.provider_id}
                      href={provider.link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="group inline-flex items-center gap-2 rounded-full border border-md-border bg-white/5 hover:bg-white/10 px-3 py-1.5 text-sm"
                    >
                      {providerLogo(provider.logo_path ?? undefined) && (
                        <img 
                          src={providerLogo(provider.logo_path ?? undefined)!} 
                          alt="" 
                          className="h-4 w-4 rounded-[4px]" 
                        />
                      )}
                      <span>{provider.provider_name}</span>
                    </a>
                  ))}
                  
                  {(!watchProviders || 
                    (!watchProviders.flatrate?.length && 
                     !watchProviders.rent?.length && 
                     !watchProviders.buy?.length)) && (
                    <p className="text-md-inkMuted text-sm">
                      Streaming availability information is not available for this movie.
                    </p>
                  )}
                </div>
              </div>

              {/* Actions */}
              <div className="mt-auto flex flex-wrap gap-3">
                <a 
                  href={providersLink} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 rounded-full bg-md-accent px-4 py-2 text-sm font-medium text-white hover:bg-md-accent600"
                >
                  Open Watch Options
                </a>
                <button 
                  className="rounded-full border border-md-border px-4 py-2 text-sm hover:bg-white/5"
                  onClick={copyCurrentUrl}
                >
                  Copy Link
                </button>
              </div>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="mx-auto max-w-[1120px] px-4 pb-16">
          <div className="rounded-xl border border-md-border bg-md-surface p-4 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <img src="/logo-moviedrop.svg" alt="" className="h-5 w-auto" />
              <span className="text-sm text-md-inkMuted">MovieDrop</span>
            </div>
            {process.env.NEXT_PUBLIC_APP_STORE_URL && (
              <a 
                href={process.env.NEXT_PUBLIC_APP_STORE_URL} 
                target="_blank" 
                rel="noopener" 
                className="inline-flex items-center rounded-md border border-md-border px-3 py-1.5 text-sm hover:bg-white/5"
              >
                Download on the App Store
              </a>
            )}
          </div>
          <p className="mt-3 text-xs text-md-inkMuted">
            This product uses the TMDB API but is not endorsed or certified by TMDB.
          </p>
        </footer>
      </main>
    )
  } catch (error) {
    console.error('Error fetching movie data:', error)
    notFound()
  }
}
