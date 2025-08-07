#!/usr/bin/env node

/**
 * Wrapper for chunk command to handle initialization
 */

const ChunkCommand = require('./chunk');
const path = require('path');

// Get memento directory from environment or default
const mementoDir = process.env.MEMENTO_DIR || path.join(process.env.HOME, '.claude/memento');

async function main() {
  try {
    const command = new ChunkCommand(mementoDir);
    await command.initialize();
    
    // Get arguments (skip node and script name)
    const args = process.argv.slice(2);
    
    await command.execute(args);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();