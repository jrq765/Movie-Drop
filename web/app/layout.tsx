import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'MovieDrop - Share Movies Instantly',
  description: 'Share movies instantly with friends. Find where to watch, rent, or buy your favorite films.',
  openGraph: {
    title: 'MovieDrop - Share Movies Instantly',
    description: 'Share movies instantly with friends. Find where to watch, rent, or buy your favorite films.',
    url: 'https://moviedrop.app',
    siteName: 'MovieDrop',
    images: [
      {
        url: 'https://moviedrop.app/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'MovieDrop',
      },
    ],
    locale: 'en_US',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'MovieDrop - Share Movies Instantly',
    description: 'Share movies instantly with friends. Find where to watch, rent, or buy your favorite films.',
    images: ['https://moviedrop.app/og-image.jpg'],
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
