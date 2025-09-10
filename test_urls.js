#!/usr/bin/env node

/**
 * Test script to verify MovieDrop URL flow
 * Run with: node test_urls.js
 */

const https = require('https');
const http = require('http');

// Test configuration
const TEST_CONFIG = {
    apiBase: 'https://moviedrop.app',
    webBase: 'https://moviedrop.app',
    testMovieId: '27205', // Inception
    timeout: 10000
};

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function makeRequest(url) {
    return new Promise((resolve, reject) => {
        const client = url.startsWith('https:') ? https : http;
        const req = client.get(url, { timeout: TEST_CONFIG.timeout }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    statusCode: res.statusCode,
                    headers: res.headers,
                    data: data
                });
            });
        });
        
        req.on('error', reject);
        req.on('timeout', () => {
            req.destroy();
            reject(new Error('Request timeout'));
        });
    });
}

async function testEndpoint(name, url, expectedStatus = 200) {
    try {
        log(`\n🔍 Testing ${name}...`, 'cyan');
        log(`   URL: ${url}`, 'blue');
        
        const response = await makeRequest(url);
        
        if (response.statusCode === expectedStatus) {
            log(`   ✅ Status: ${response.statusCode}`, 'green');
            
            // Check for specific content
            if (name.includes('Movie Page') && response.data.includes('Inception')) {
                log(`   ✅ Content: Movie page contains expected content`, 'green');
            } else if (name.includes('API') && response.data.includes('{')) {
                log(`   ✅ Content: API returned JSON`, 'green');
            }
            
            return true;
        } else {
            log(`   ❌ Status: ${response.statusCode} (expected ${expectedStatus})`, 'red');
            return false;
        }
    } catch (error) {
        log(`   ❌ Error: ${error.message}`, 'red');
        return false;
    }
}

async function testURLFlow() {
    log('🎬 MovieDrop URL Flow Test', 'bright');
    log('=' .repeat(50), 'bright');
    
    const tests = [
        {
            name: 'API Health Check',
            url: `${TEST_CONFIG.apiBase}/api/health`,
            expectedStatus: 200
        },
        {
            name: 'API Movies Search',
            url: `${TEST_CONFIG.apiBase}/api/movies/search?query=inception`,
            expectedStatus: 200
        },
        {
            name: 'API Movie Details',
            url: `${TEST_CONFIG.apiBase}/api/movies/${TEST_CONFIG.testMovieId}`,
            expectedStatus: 200
        },
        {
            name: 'API Streaming Info',
            url: `${TEST_CONFIG.apiBase}/api/streaming/${TEST_CONFIG.testMovieId}`,
            expectedStatus: 200
        },
        {
            name: 'Movie Page (Main Domain)',
            url: `${TEST_CONFIG.webBase}/m/${TEST_CONFIG.testMovieId}`,
            expectedStatus: 200
        }
    ];
    
    let passed = 0;
    let total = tests.length;
    
    for (const test of tests) {
        const success = await testEndpoint(test.name, test.url, test.expectedStatus);
        if (success) passed++;
    }
    
    log('\n' + '=' .repeat(50), 'bright');
    log(`📊 Test Results: ${passed}/${total} tests passed`, passed === total ? 'green' : 'yellow');
    
    if (passed === total) {
        log('\n🎉 All tests passed! Your URL flow is working correctly.', 'green');
        log('\n📱 Next steps:', 'cyan');
        log('   1. Test iMessage card sharing in your iOS app', 'blue');
        log('   2. Verify URLs open correctly in browser', 'blue');
        log('   3. Check social media link previews', 'blue');
    } else {
        log('\n⚠️  Some tests failed. Check the errors above.', 'yellow');
        log('\n🔧 Troubleshooting tips:', 'cyan');
        log('   1. Verify DNS propagation: dig moviedrop.app', 'blue');
        log('   2. Check backend deployment status', 'blue');
        log('   3. Verify environment variables are set', 'blue');
        log('   4. Check CORS configuration', 'blue');
        log('   5. Verify path routing is configured correctly', 'blue');
    }
}

// Run the tests
if (require.main === module) {
    testURLFlow().catch(error => {
        log(`\n💥 Test script failed: ${error.message}`, 'red');
        process.exit(1);
    });
}

module.exports = { testURLFlow, makeRequest };
