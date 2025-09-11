import type { VercelRequest, VercelResponse } from '@vercel/node';

const TMDB_KEY = process.env.TMDB_API_KEY!;
const REGION_DEFAULT = (process.env.REGION_DEFAULT || 'US').toUpperCase();
const CORS_ALLOW_ORIGIN = process.env.CORS_ALLOW_ORIGIN || 'https://moviedrop.framer.website';

function setCORS(res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ALLOW_ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  setCORS(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).send('Method Not Allowed');

  const id = (Array.isArray(req.query.id) ? req.query.id[0] : req.query.id) as string;
  if (!id) return res.status(400).json({ error: 'Missing movie id' });

  if (!TMDB_KEY) {
    return res.status(500).json({
      error: 'Missing TMDB_API_KEY',
      restore: [
        'Add TMDB_API_KEY to your Vercel project Environment Variables',
        'Redeploy, then GET /api/health should return { ok: true }'
      ]
    });
  }

  const region = ((req.query.region as string) || REGION_DEFAULT).toUpperCase();

  // Fetch watch/providers for the movie
  const url = new URL(`https://api.themoviedb.org/3/movie/${id}/watch/providers`);
  url.searchParams.set('api_key', TMDB_KEY);

  const resp = await fetch(url.toString(), { headers: { 'Accept': 'application/json' } });
  if (!resp.ok) {
    return res.status(resp.status).json({ error: 'TMDB providers fetch failed' });
  }
  const data = await resp.json();

  const regionData = data?.results?.[region];
  const tmdbRegionLink =
    regionData?.link || `https://www.themoviedb.org/movie/${id}/watch?locale=${region}`;

  if (!regionData) {
    return res.status(200).json({ region, link: tmdbRegionLink, providers: [] });
  }

  // Only providers that TMDB says are available, grouped by kind
  type Kind = 'flatrate' | 'rent' | 'buy';
  const kinds: Kind[] = ['flatrate', 'rent', 'buy'];

  const providers: Array<{ id: number; name: string; logo_path?: string; kind: Kind; url: string }> = [];

  for (const kind of kinds) {
    const arr = (regionData as any)[kind] || [];
    for (const p of arr) {
      providers.push({
        id: p.provider_id,
        name: p.provider_name,
        logo_path: p.logo_path,
        kind,
        // Direct deep links differ by provider and often require private catalogs.
        // For now, safely fall back to the TMDB/JustWatch region page.
        url: tmdbRegionLink
      });
    }
  }

  // Dedupe by provider id + kind
  const key = (x: any) => `${x.id}:${x.kind}`;
  const dedup = Object.values(
    providers.reduce((acc: any, cur) => ((acc[key(cur)] = acc[key(cur)] || cur), acc), {})
  );

  res.setHeader('Cache-Control', 's-maxage=300, stale-while-revalidate=600');
  return res.status(200).json({ region, link: tmdbRegionLink, providers: dedup });
}
