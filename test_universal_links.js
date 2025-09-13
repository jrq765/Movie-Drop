#!/usr/bin/env node

/**
 * Universal Links Implementation Verification Script
 * Tests the complete flow from iMessage cards to app/web fallback
 */

const https = require('https');
const http = require('http');

// Test configuration
const BASE_URL = 'https://moviedrop.app';
const TEST_MOVIE_ID = '438631'; // Dune
const TEST_REGION = 'US';

console.log('🔍 Testing Universal Links Implementation...\n');

// Helper function to make HTTP requests
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https:') ? https : http;
    const req = client.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, data }));
    });
    req.on('error', reject);
    req.setTimeout(10000, () => reject(new Error('Request timeout')));
    req.end();
  });
}

async function testRedirect() {
  console.log('1️⃣ Testing /m/:id redirect to Framer...');
  try {
    const url = `${BASE_URL}/m/${TEST_MOVIE_ID}?region=${TEST_REGION}`;
    console.log(`   URL: ${url}`);
    
    const response = await makeRequest(url, { method: 'GET' });
    console.log(`   Status: ${response.status}`);
    console.log(`   Location: ${response.headers.location || 'No redirect'}`);
    
    if (response.status === 302 && response.headers.location?.includes('moviedrop.framer.website')) {
      console.log('   ✅ Redirect working correctly\n');
      return true;
    } else {
      console.log('   ❌ Redirect not working as expected\n');
      return false;
    }
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}\n`);
    return false;
  }
}

async function testAASA() {
  console.log('2️⃣ Testing Apple App Site Association...');
  try {
    const url = `${BASE_URL}/.well-known/apple-app-site-association`;
    console.log(`   URL: ${url}`);
    
    const response = await makeRequest(url, { method: 'GET' });
    console.log(`   Status: ${response.status}`);
    
    if (response.status === 200) {
      try {
        const aasa = JSON.parse(response.data);
        console.log('   AASA Content:', JSON.stringify(aasa, null, 2));
        
        if (aasa.applinks?.details?.[0]?.paths?.includes('/m/*')) {
          console.log('   ✅ AASA configured correctly\n');
          return true;
        } else {
          console.log('   ❌ AASA missing /m/* path\n');
          return false;
        }
      } catch (parseError) {
        console.log(`   ❌ Invalid JSON: ${parseError.message}\n`);
        return false;
      }
    } else {
      console.log('   ❌ AASA not accessible\n');
      return false;
    }
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}\n`);
    return false;
  }
}

async function testAPI() {
  console.log('3️⃣ Testing API endpoint...');
  try {
    const url = `${BASE_URL}/api/streaming/${TEST_MOVIE_ID}?region=${TEST_REGION}`;
    console.log(`   URL: ${url}`);
    
    const response = await makeRequest(url, { method: 'GET' });
    console.log(`   Status: ${response.status}`);
    
    if (response.status === 200) {
      try {
        const data = JSON.parse(response.data);
        console.log(`   Movie: ${data.title} (${data.year})`);
        console.log(`   Providers: ${data.providers?.length || 0} found`);
        
        if (data.providers && data.providers.length > 0) {
          console.log('   Sample provider:', data.providers[0]);
          
          // Verify that URLs are direct links, not search URLs
          const hasDirectLinks = data.providers.every(p => 
            p.url && !p.url.includes('search?') && !p.url.includes('themoviedb.org')
          );
          
          if (hasDirectLinks) {
            console.log('   ✅ All URLs are direct movie links');
          } else {
            console.log('   ❌ Some URLs are search links or TMDB links');
          }
        }
        
        console.log('   ✅ API working correctly\n');
        return true;
      } catch (parseError) {
        console.log(`   ❌ Invalid JSON: ${parseError.message}\n`);
        return false;
      }
    } else {
      console.log(`   ❌ API error: ${response.status}\n`);
      return false;
    }
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}\n`);
    return false;
  }
}

async function main() {
  console.log('🎬 MovieDrop Universal Links Test\n');
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Test Movie ID: ${TEST_MOVIE_ID}`);
  console.log(`Test Region: ${TEST_REGION}\n`);
  
  const results = await Promise.all([
    testRedirect(),
    testAASA(),
    testAPI()
  ]);
  
  const passed = results.filter(Boolean).length;
  const total = results.length;
  
  console.log('📊 Test Results:');
  console.log(`   Passed: ${passed}/${total}`);
  
  if (passed === total) {
    console.log('\n🎉 All tests passed! Universal Links implementation is ready.');
    console.log('\n📱 Next steps:');
    console.log('   1. Deploy to production');
    console.log('   2. Update AASA with real Team ID and Bundle ID');
    console.log('   3. Test on physical device with app installed');
    console.log('   4. Test on device without app (should open Framer)');
  } else {
    console.log('\n❌ Some tests failed. Check the errors above.');
    console.log('\n🔧 Restoration checklist:');
    console.log('   - AASA served at https://moviedrop.app/.well-known/apple-app-site-association');
    console.log('   - App entitlements include applinks:moviedrop.app');
    console.log('   - Message URL uses https://moviedrop.app/m/:id (NOT /api/m/:id)');
    console.log('   - vercel.json redirects /m/:id → Framer');
    console.log('   - TMDB_API_KEY set on Vercel');
    console.log('   - CORS_ALLOW_ORIGIN = https://moviedrop.framer.website');
  }
}

main().catch(console.error);
