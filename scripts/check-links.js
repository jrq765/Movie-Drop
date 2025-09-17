#!/usr/bin/env node

/**
 * Pre-commit guard against hard-coded preview URLs
 * Fails if any staged diff contains vercel.app or /api/m/ patterns
 */

const { execSync } = require('child_process');
const fs = require('fs');

const FORBIDDEN_PATTERNS = [
  /vercel\.app/,
  /\/api\/m\//
];

const ERROR_MESSAGE = `❌ Do not hard-code preview or /api/m links. Use CANONICAL_WEB_BASE + /m/:id.

Found forbidden patterns in staged changes:
- vercel.app (use moviedrop.app)
- /api/m/ (use /m/ for web pages)

Fix by:
1. Using centralized URL functions from src/lib/links.ts
2. Setting NEXT_PUBLIC_CANONICAL_WEB_BASE=https://moviedrop.app
3. Using cardUrl(id, region) for all movie links`;

function checkStagedFiles() {
  try {
    // Get staged files
    const stagedFiles = execSync('git diff --cached --name-only', { encoding: 'utf8' })
      .trim()
      .split('\n')
      .filter(Boolean);

    if (stagedFiles.length === 0) {
      console.log('✅ No staged files to check');
      return;
    }

    let violations = [];

    for (const file of stagedFiles) {
      if (!fs.existsSync(file)) continue;

      try {
        const content = fs.readFileSync(file, 'utf8');
        
        for (const pattern of FORBIDDEN_PATTERNS) {
          if (pattern.test(content)) {
            violations.push({
              file,
              pattern: pattern.toString(),
              lines: content.split('\n')
                .map((line, i) => ({ line: i + 1, content: line }))
                .filter(({ content }) => pattern.test(content))
                .slice(0, 3) // Show first 3 matches
            });
          }
        }
      } catch (err) {
        // Skip binary files
        continue;
      }
    }

    if (violations.length > 0) {
      console.error(ERROR_MESSAGE);
      console.error('\nViolations found:');
      
      violations.forEach(({ file, lines }) => {
        console.error(`\n📁 ${file}:`);
        lines.forEach(({ line, content }) => {
          console.error(`  ${line}: ${content.trim()}`);
        });
      });
      
      process.exit(1);
    }

    console.log('✅ No forbidden URL patterns found in staged files');
  } catch (error) {
    console.error('Error checking staged files:', error.message);
    process.exit(1);
  }
}

checkStagedFiles();
