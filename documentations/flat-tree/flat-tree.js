#!/usr/bin/env node

/**
 * Script Name: flat-tree.js
 * Description: Generates a flat directory tree with relative paths
 * Parameters: [optional] Exclude directories pattern.
 * Usage: node flat-tree.js --exclude 'node_modules|dist|documentation'
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { program } = require('commander');

// Configure command-line options
program
  .name('flat-tree')
  .description('Generates a flat directory tree with relative paths')
  .version('1.0.0')
  .option('-e, --exclude <pattern>', 'Additional directories to exclude (pipe-separated)')
  .option('-d, --debug', 'Enable debug mode')
  .option('-o, --output <file>', 'Save output to a file')
  .option('-c, --copy', 'Copy output to clipboard')
  .parse(process.argv);

const options = program.opts();

// Helper functions
const notice = (message) => console.log(`\x1b[33m${message}\x1b[0m`);
const success = (message) => console.log(`\x1b[32m${message}\x1b[0m`);
const error = (message) => console.log(`\x1b[31m${message}\x1b[0m`);
const debug = (message) => {
  if (options.debug || process.env.DEBUG === 'true') {
    console.log(`---> DEBUG: ${message}`);
  }
};

/**
 * Copies text to clipboard
 * @param {string} text - The text to copy
 */
function copy(text) {
  try {
    // Basic clipboard implementation without external dependencies
    if (process.platform === 'win32') {
      const tempFile = path.join(process.env.TEMP || '.', 'clipboard.txt');
      fs.writeFileSync(tempFile, text);
      execSync(`type "${tempFile}" | clip`, { stdio: 'ignore' });
      fs.unlinkSync(tempFile);
    } else if (process.platform === 'darwin') {
      // macOS
      execSync('pbcopy', { input: text });
    } else {
      // Linux - try various clipboard tools
      try {
        execSync('xclip -selection clipboard', { input: text });
      } catch (e) {
        try {
          execSync('xsel -ib', { input: text });
        } catch (e) {
          error('Unable to copy to clipboard: no supported clipboard utility found');
          return;
        }
      }
    }
    success('📋 Copied to clipboard');
  } catch (e) {
    error(`Failed to copy to clipboard: ${e.message}`);
  }
}

/**
 * Gets exclude patterns from .gitignore and merges with provided patterns
 * @param {string} additionalExcludes - Additional patterns to exclude
 * @returns {string} - Pipe-separated list of patterns to exclude
 */
function getExcludePatterns(additionalExcludes = '') {
  let excludeDirs = '*/documentations/**|*/node_modules/**|.git|*/.angular/*|*/Production/**|*/Outils/**|*/Maj/**|*/CICD/**|*/.git/**|*/.idea/**|*/.vs/**|*/.vscode/**|*/Addons/**';
  
  try {
    if (fs.existsSync('.gitignore')) {
      // Read gitignore with correct handling of Windows line endings
      let gitignoreContent = fs.readFileSync('.gitignore', 'utf8');
      
      // Normalize line endings (convert CRLF to LF)
      gitignoreContent = gitignoreContent.replace(/\r\n/g, '\n');
      
      // Process .gitignore content with improved pattern handling
      const gitignorePatterns = gitignoreContent
        .split('\n')
        .filter(line => line.trim() && !line.startsWith('#')) // Remove comments and empty lines
        .map(line => {
          // Clean up pattern
          return line
            .trim()
            .replace(/^\//, '')     // Remove leading /
            .replace(/\/$/, '')     // Remove trailing /
        })
        .filter(line => line.trim());  // Remove any lines that became empty
      
      // Use proper array join for multiple patterns
      if (gitignorePatterns.length > 0) {
        excludeDirs += `|${gitignorePatterns.join('|')}`;
      }
    } else {
      debug('.gitignore file not found. Using default exclusions only.');
    }
    
    // Add additional exclusions if provided
    if (additionalExcludes) {
      excludeDirs += `|${additionalExcludes}`;
    }
    
    debug(`Exclude patterns: ${excludeDirs}`);
    return excludeDirs;
  } catch (e) {
    error(`Error processing exclusion patterns: ${e.message}`);
    return excludeDirs;
  }
}

/**
 * Pure JavaScript implementation of a flat tree with relative paths
 * @param {string} dir - The directory to start from
 * @param {string} excludePattern - Pipe-separated patterns to exclude
 * @returns {string} - Formatted tree output
 */
function flatTree(dir = '.', excludePattern = '') {
  // Convert pipe-separated pattern to array for easier checking
  const excludePatterns = excludePattern ? excludePattern.split('|') : [];
  
  // Initialize output with just the root
  let output = '.\n';
  
  function shouldExclude(name) {
    if (!excludePatterns.length) return false;
    
    return excludePatterns.some(pattern => {
      // For simple patterns, use direct comparison
      if (pattern === name) return true;
      
      // For patterns with wildcard, do special check
      if (pattern.includes('*')) {
        // Convert glob pattern to parts for comparison
        const parts = pattern.split('*');
        
        // Check if name starts with first part (if not empty)
        if (parts[0] && !name.startsWith(parts[0])) return false;
        
        // Check if name ends with last part (if not empty)
        if (parts[parts.length-1] && !name.endsWith(parts[parts.length-1])) return false;
        
        // For patterns like a*b*c, check all parts present in order
        let remainingName = name;
        for (let i = 0; i < parts.length; i++) {
          if (!parts[i]) continue; // Skip empty parts
          
          const index = remainingName.indexOf(parts[i]);
          if (index === -1) return false;
          
          // Move forward in string for next part
          remainingName = remainingName.substring(index + parts[i].length);
        }
        
        return true;
      }
      
      // Try safe regex comparison
      try {
        // Escape all regex special chars except asterisk
        let regexPattern = pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
                                  .replace(/\\\*/g, '.*'); // Replace \* with .*
        
        const regex = new RegExp(`^${regexPattern}$`, 'i');
        return regex.test(name);
      } catch (e) {
        debug(`Error with pattern "${pattern}": ${e.message}`);
        // In case of regex error, do simple comparison
        return name === pattern;
      }
    });
  }
  
  // Use a flat approach (no recursion to avoid call stack issues with very large directories)
  const queue = [{path: dir, relPath: '.'}];
  const processed = new Set(); // To avoid cycles
  const allPaths = []; // Collect all paths to sort them later
  
  while (queue.length > 0) {
    const current = queue.shift();
    const currentAbsPath = path.resolve(current.path);
    
    // Skip if already processed (avoid cycles)
    if (processed.has(currentAbsPath)) continue;
    processed.add(currentAbsPath);
    
    try {
      // Read directory entries including hidden files
      const entries = fs.readdirSync(current.path, { withFileTypes: true });
      
      for (const entry of entries) {
        const entryName = entry.name;
        const entryPath = path.join(current.path, entryName);
        const entryRelPath = path.join(current.relPath, entryName);
        
        // Use forward slashes for consistent output even on Windows
        // Make sure path starts with ./ (but not for the root which is just .)
        let normalizedRelPath = entryRelPath.replace(/\\/g, '/');
        if (!normalizedRelPath.startsWith('./') && normalizedRelPath !== '.') {
          normalizedRelPath = './' + normalizedRelPath;
        }
        
        // Skip excluded entries - note we're checking the normalized relative path
        if (shouldExclude(normalizedRelPath)) continue;
        
        // Add to paths array instead of directly to output
        allPaths.push({
          path: normalizedRelPath,
          isDirectory: entry.isDirectory()
        });
        
        // Add directories to queue for processing
        if (entry.isDirectory()) {
          queue.push({path: entryPath, relPath: normalizedRelPath});
        }
      }
    } catch (e) {
      debug(`Error reading directory ${current.path}: ${e.message}`);
    }
  }
  
  // Sort paths to preserve directory hierarchy
  allPaths.sort((a, b) => {
    // Split paths into segments for comparison
    const aSegments = a.path.split('/');
    const bSegments = b.path.split('/');
    
    // Compare segments one by one
    const minLength = Math.min(aSegments.length, bSegments.length);
    
    for (let i = 0; i < minLength; i++) {
      if (aSegments[i] !== bSegments[i]) {
        return aSegments[i].localeCompare(bSegments[i]);
      }
    }
    
    // If all segments so far are equal, shorter paths come first
    return aSegments.length - bSegments.length;
  });
  
  // Add sorted paths to output
  for (const item of allPaths) {
    output += `${item.path}\n`;
  }
  
  return output;
}

/**
 * Generates and displays the directory tree
 */
function generateTree() {
  const excludePattern = getExcludePatterns(options.exclude);
  
  debug(`Exclude patterns: ${excludePattern}`);
  
  let treeOutput = '';
  
  // Use our flat tree implementation
  treeOutput = flatTree('.', excludePattern);
  
  // Output results
  console.log(treeOutput);
  
  // Save to file if requested
  if (options.output) {
    try {
      fs.writeFileSync(options.output, treeOutput);
      success(`Tree output saved to: ${options.output}`);
    } catch (e) {
      error(`Failed to save output to file: ${e.message}`);
    }
  }
  
  return treeOutput;
}

// Main execution
try {
  const output = generateTree();
  
  // Add ability to copy output to clipboard if requested
  if (process.argv.includes('--copy') || process.argv.includes('-c')) {
    try {
      copy(output);
    } catch (e) {
      error(`Failed to copy to clipboard: ${e.message}`);
    }
  }
} catch (e) {
  error(`Fatal error: ${e.message}`);
  process.exit(1);
}