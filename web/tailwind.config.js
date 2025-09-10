/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'md': {
          'ink': '#FFFFFF',
          'inkMuted': 'rgba(255,255,255,0.72)',
          'bg': '#0B0B0F',
          'surface': '#111315',
          'border': 'rgba(255,255,255,0.08)',
          'accent': '#EE5A3A',
          'accent600': '#E14C2E',
        },
      },
      borderRadius: {
        '2xl': '1rem',
      },
      boxShadow: {
        'md': '0 6px 30px rgba(0,0,0,0.35)',
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic':
          'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
    },
  },
  plugins: [],
}
