declare global {
  interface Window {
    googletag: any
  }
}

interface AdConfig {
  network: string
  slotLeft: string
  slotRight: string
}

function getAdConfig(): AdConfig | null {
  const network = process.env.NEXT_PUBLIC_GAM_NETWORK
  const slotLeft = process.env.NEXT_PUBLIC_GAM_SLOT_LEFT
  const slotRight = process.env.NEXT_PUBLIC_GAM_SLOT_RIGHT

  if (!network || !slotLeft || !slotRight) {
    return null
  }

  return { network, slotLeft, slotRight }
}

export function initGAM(): void {
  const config = getAdConfig()
  if (!config) {
    console.log('Ad configuration not found, skipping ad initialization')
    return
  }

  // Check if GPT is already loaded
  if (typeof window !== 'undefined' && window.googletag) {
    console.log('GPT already loaded')
    return
  }

  // Load GPT script
  const script = document.createElement('script')
  script.async = true
  script.src = `https://www.googletagservices.com/tag/js/gpt.js`
  script.onload = () => {
    console.log('GPT script loaded')
    setupAdSlots(config)
  }
  document.head.appendChild(script)
}

function setupAdSlots(config: AdConfig): void {
  if (typeof window === 'undefined' || !window.googletag) {
    return
  }

  const { googletag } = window

  // Initialize GPT
  googletag.cmd.push(() => {
    // Define ad slots
    googletag
      .defineSlot(config.slotLeft, [160, 600], 'ad-slot-left')
      .addService(googletag.pubads())
    
    googletag
      .defineSlot(config.slotRight, [160, 600], 'ad-slot-right')
      .addService(googletag.pubads())

    // Enable services
    googletag.pubads().enableSingleRequest()
    googletag.pubads().collapseEmptyDivs()
    googletag.enableServices()

    // Display ads
    googletag.display('ad-slot-left')
    googletag.display('ad-slot-right')

    console.log('Ad slots configured and displayed')
  })
}
