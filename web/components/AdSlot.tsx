'use client'

import { useEffect } from 'react'
import { initGAM } from '@/lib/ads'

interface AdSlotProps {
  position: 'left' | 'right'
}

export default function AdSlot({ position }: AdSlotProps) {
  useEffect(() => {
    // Only initialize ads if we're on the client side and have ad configuration
    if (typeof window !== 'undefined') {
      initGAM()
    }
  }, [])

  // Check if ad configuration exists
  const hasAdConfig = !!(
    process.env.NEXT_PUBLIC_GAM_NETWORK &&
    process.env.NEXT_PUBLIC_GAM_SLOT_LEFT &&
    process.env.NEXT_PUBLIC_GAM_SLOT_RIGHT
  )

  // Don't render anything if ad configuration is missing
  if (!hasAdConfig) {
    return null
  }

  return (
    <div 
      id={`ad-slot-${position}`}
      className="w-full h-96 bg-gray-100 flex items-center justify-center"
    >
      <span className="text-gray-400 text-sm">Advertisement</span>
    </div>
  )
}
