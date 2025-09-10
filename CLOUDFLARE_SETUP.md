# Cloudflare Setup for MovieDrop (Free Solution)

## Overview
This guide shows you how to use Cloudflare's free tier to route your moviedrop.app domain paths correctly without needing a subdomain.

## Why Cloudflare?
- ✅ **Free** - No additional costs
- ✅ **Easy Setup** - Simple page rules configuration
- ✅ **Fast** - Global CDN for better performance
- ✅ **Reliable** - Enterprise-grade infrastructure

## Step-by-Step Setup

### 1. Add Your Domain to Cloudflare

1. Go to [cloudflare.com](https://cloudflare.com) and create a free account
2. Click "Add a Site" and enter `moviedrop.app`
3. Choose the **Free** plan
4. Cloudflare will scan your current DNS records

### 2. Update DNS Records

In Cloudflare's DNS settings, you'll need:

```
Type: A Record
Name: @
Content: [Your Framer IP address]
Proxy status: Proxied (orange cloud)

Type: CNAME Record  
Name: www
Content: moviedrop.app
Proxy status: Proxied (orange cloud)
```

**To get your Framer IP:**
1. Contact Framer support or check your Framer dashboard
2. Or use: `dig moviedrop.app` to see current IP

### 3. Configure Page Rules

This is the key part - we'll route specific paths to your backend:

1. Go to **Rules** → **Page Rules**
2. Create these rules (in order of priority):

#### Rule 1: API Routes
```
URL: moviedrop.app/api/*
Settings:
- Forwarding URL: 301 Redirect to https://your-backend-url.vercel.app/api/$1
```

#### Rule 2: Movie Pages  
```
URL: moviedrop.app/m/*
Settings:
- Forwarding URL: 301 Redirect to https://your-backend-url.vercel.app/m/$1
```

#### Rule 3: Everything Else (Default)
```
URL: moviedrop.app/*
Settings:
- Forwarding URL: 301 Redirect to https://your-framer-site.framer.website
```

### 4. Update Nameserver

1. In Cloudflare, go to **Overview**
2. Copy the two nameservers Cloudflare provides
3. In Namescheap:
   - Go to Domain List → Manage → Nameservers
   - Change from "Namescheap BasicDNS" to "Custom DNS"
   - Enter the two Cloudflare nameservers

### 5. Wait for Propagation

- DNS changes can take 24-48 hours
- Cloudflare usually propagates faster (1-2 hours)
- You can check status at [whatsmydns.net](https://whatsmydns.net)

## Alternative: Cloudflare Workers (Advanced)

If you want more control, you can use Cloudflare Workers:

```javascript
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)
  
  // Route API calls to backend
  if (url.pathname.startsWith('/api/')) {
    return fetch(`https://your-backend.vercel.app${url.pathname}${url.search}`, request)
  }
  
  // Route movie pages to backend
  if (url.pathname.startsWith('/m/')) {
    return fetch(`https://your-backend.vercel.app${url.pathname}${url.search}`, request)
  }
  
  // Everything else goes to Framer
  return fetch(`https://your-framer-site.framer.website${url.pathname}${url.search}`, request)
}
```

## Testing Your Setup

Once configured, test these URLs:

```bash
# Should show your Framer marketing site
curl https://moviedrop.app/

# Should show API response
curl https://moviedrop.app/api/health

# Should show movie page
curl https://moviedrop.app/m/27205
```

## Troubleshooting

### Common Issues:

1. **"Too many redirects" error**
   - Check that your backend URLs are correct
   - Make sure you're not redirecting to the same domain

2. **API calls not working**
   - Verify your backend is deployed and accessible
   - Check that the `/api/*` rule is configured correctly

3. **Movie pages not loading**
   - Ensure the `/m/*` rule is set up
   - Verify your backend serves the movie page route

4. **Slow loading**
   - Cloudflare should make things faster, not slower
   - Check if you have any conflicting rules

### Debug Steps:

1. **Check DNS propagation:**
   ```bash
   dig moviedrop.app
   ```

2. **Test direct backend access:**
   ```bash
   curl https://your-backend.vercel.app/api/health
   ```

3. **Check Cloudflare analytics:**
   - Go to Analytics → Web Analytics
   - See if requests are being routed correctly

## Benefits You'll Get

- ✅ **Free hosting** for your routing logic
- ✅ **Global CDN** for faster loading
- ✅ **SSL certificate** automatically provided
- ✅ **DDoS protection** included
- ✅ **Analytics** on your traffic
- ✅ **Easy management** through web interface

## Next Steps

1. Set up Cloudflare account and add your domain
2. Configure the page rules as shown above
3. Update your nameservers in Namescheap
4. Test the URL flow with the provided test script
5. Deploy your iOS app and test iMessage sharing

This solution gives you professional-grade routing without any additional costs!
