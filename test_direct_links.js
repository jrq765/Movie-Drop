#!/usr/bin/env node

/**
 * Test script to verify direct movie links (not search URLs)
 */

const https = require('https');

function makeRequest(url) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    });
    req.on('error', reject);
    req.setTimeout(10000, () => reject(new Error('Request timeout')));
    req.end();
  });
}

async function testDirectLinks() {
  console.log('🔍 Testing Direct Movie Links...\n');
  
  const testCases = [
    { id: '438631', name: 'Dune (2021)' },
    { id: '550', name: 'Fight Club' },
    { id: '13', name: 'Forrest Gump' }
  ];
  
  for (const testCase of testCases) {
    console.log(`📽️  Testing: ${testCase.name} (ID: ${testCase.id})`);
    
    try {
      const url = `https://moviedrop.app/api/streaming/${testCase.id}?region=US`;
      const response = await makeRequest(url);
      
      if (response.status === 200) {
        const data = JSON.parse(response.data);
        console.log(`   Title: ${data.title}`);
        console.log(`   Providers: ${data.providers?.length || 0}`);
        
        if (data.providers && data.providers.length > 0) {
          // Check each provider URL
          let hasSearchUrls = false;
          let hasTmdbUrls = false;
          let directLinkCount = 0;
          
          data.providers.forEach(provider => {
            if (provider.url) {
              if (provider.url.includes('search?') || provider.url.includes('search&')) {
                hasSearchUrls = true;
                console.log(`   ❌ Search URL: ${provider.name} - ${provider.url}`);
              } else if (provider.url.includes('themoviedb.org')) {
                hasTmdbUrls = true;
                console.log(`   ❌ TMDB URL: ${provider.name} - ${provider.url}`);
              } else {
                directLinkCount++;
                console.log(`   ✅ Direct: ${provider.name} - ${provider.url}`);
              }
            }
          });
          
          console.log(`   📊 Results: ${directLinkCount} direct links, ${data.providers.length - directLinkCount} invalid`);
          
          if (hasSearchUrls || hasTmdbUrls) {
            console.log('   ❌ FAILED: Contains search URLs or TMDB links\n');
          } else {
            console.log('   ✅ PASSED: All links are direct movie links\n');
          }
        } else {
          console.log('   ⚠️  No providers found\n');
        }
      } else {
        console.log(`   ❌ API Error: ${response.status}\n`);
      }
    } catch (error) {
      console.log(`   ❌ Error: ${error.message}\n`);
    }
  }
}

testDirectLinks().catch(console.error);
