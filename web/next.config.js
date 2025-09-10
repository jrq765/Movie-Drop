/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: ['image.tmdb.org'],
  },
  env: {
    TMDB_API_KEY: process.env.TMDB_API_KEY,
    NEXT_PUBLIC_BASE_URL: process.env.NEXT_PUBLIC_BASE_URL,
    NEXT_PUBLIC_REGION_DEFAULT: process.env.NEXT_PUBLIC_REGION_DEFAULT,
    NEXT_PUBLIC_APP_STORE_URL: process.env.NEXT_PUBLIC_APP_STORE_URL,
    NEXT_PUBLIC_GAM_NETWORK: process.env.NEXT_PUBLIC_GAM_NETWORK,
    NEXT_PUBLIC_GAM_SLOT_LEFT: process.env.NEXT_PUBLIC_GAM_SLOT_LEFT,
    NEXT_PUBLIC_GAM_SLOT_RIGHT: process.env.NEXT_PUBLIC_GAM_SLOT_RIGHT,
  },
}

module.exports = nextConfig
