import { redirect } from 'next/navigation'

export default function HomePage() {
  // Redirect to the existing HTML page
  redirect('/index.html')
}
