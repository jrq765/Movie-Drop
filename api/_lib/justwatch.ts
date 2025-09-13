import type { VercelRequest } from '@vercel/node';

const JW = process.env.JUSTWATCH_BASE || 'https://apis.justwatch.com';

type Offer = {
  presentation_type?: string;
  monetization_type?: 'flatrate'|'buy'|'rent';
  package_short_name?: string;    // provider code
  standard_web_url?: string;      // direct web url to the title
  provider_id?: number;
};

type Item = {
  id: number;
  title: string;
  object_type: 'MOVIE'|'SHOW';
  original_release_year?: number;
  offers?: Offer[];
  scoring?: Array<{ provider_type: string, value: number }>;
  external_ids?: Array<{ provider: string, external_id: string }>;
};

export async function jwSearchByTitle(region: string, q: string, limit=8): Promise<Item[]> {
  const url = `${JW}/content/titles/${region.toLowerCase()}/popular?body=${encodeURIComponent(JSON.stringify({
    page_size: limit,
    page: 1,
    query: q,
    content_types: ['movie']
  }))}`;
  const r = await fetch(url, { headers: { 'accept': 'application/json' }});
  if (!r.ok) return [];
  const data = await r.json();
  return data?.items ?? [];
}

export function extractDirectOffers(items: Item[], region: string) {
  // Prefer items with highest scoring, has offers
  const best = items.find(i => Array.isArray(i.offers) && i.offers.length) || items[0];
  if (!best?.offers?.length) return [];
  // Keep only offers with a usable standard_web_url and known monetization types
  const okKinds = new Set(['flatrate','buy','rent']);
  const offers = best.offers.filter(o => o.standard_web_url && okKinds.has(String(o.monetization_type || '')));
  // Deduplicate by provider + monetization_type
  const map = new Map<string, Offer>();
  for (const o of offers) {
    const key = `${o.package_short_name || o.provider_id}:${o.monetization_type}`;
    if (!map.has(key)) map.set(key, o);
  }
  return Array.from(map.values());
}

