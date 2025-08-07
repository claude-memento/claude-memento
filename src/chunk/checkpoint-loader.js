#!/usr/bin/env node

/**
 * Smart loader for chunked checkpoints
 */

const fs = require('fs').promises;
const path = require('path');
const SmartLoader = require('./smart-loader');
const IndexManager = require('./index-manager');
const Vectorizer = require('./vectorizer');

class CheckpointLoader {
  constructor(mementoDir) {
    this.mementoDir = mementoDir;
    this.indexManager = new IndexManager(mementoDir);
    this.vectorizer = new Vectorizer();
    this.smartLoader = new SmartLoader(this.indexManager, this.vectorizer);
  }

  async initialize() {
    await this.indexManager.initialize();
  }

  /**
   * Load checkpoint (chunked or regular)
   */
  async loadCheckpoint(checkpointFile, options = {}) {
    // Check if checkpoint is chunked
    const manifestPath = checkpointFile.replace('.md', '-manifest.json');
    
    try {
      await fs.access(manifestPath);
      // Chunked checkpoint
      return await this.loadChunkedCheckpoint(checkpointFile, manifestPath, options);
    } catch {
      // Regular checkpoint
      return await this.loadRegularCheckpoint(checkpointFile);
    }
  }

  /**
   * Load chunked checkpoint using manifest
   */
  async loadChunkedCheckpoint(checkpointFile, manifestPath, options = {}) {
    console.log('Loading chunked checkpoint...');
    
    // Read manifest
    const manifestData = await fs.readFile(manifestPath, 'utf8');
    const manifest = JSON.parse(manifestData);
    
    console.log(`Found ${manifest.chunks.length} chunks`);

    // Determine loading strategy
    if (options.query) {
      // Smart load based on query
      return await this.smartLoadWithQuery(manifest, options.query);
    } else if (options.recent) {
      // Load recent chunks
      return await this.loadRecentChunks(manifest, options.recent);
    } else {
      // Load all chunks in order
      return await this.loadAllChunks(manifest);
    }
  }

  /**
   * Load regular checkpoint
   */
  async loadRegularCheckpoint(checkpointFile) {
    console.log('Loading regular checkpoint...');
    const content = await fs.readFile(checkpointFile, 'utf8');
    return {
      type: 'regular',
      content,
      chunks: 1,
      tokens: Math.ceil(content.length / 4)
    };
  }

  /**
   * Smart load chunks based on query
   */
  async smartLoadWithQuery(manifest, query) {
    console.log(`Smart loading with query: "${query}"`);
    
    // Initialize vectorizer with checkpoint chunks
    for (const chunkInfo of manifest.chunks) {
      const chunk = await this.indexManager.loadChunk(chunkInfo.id);
      if (chunk) {
        this.vectorizer.addDocument(chunk.id, chunk.content);
      }
    }
    
    // Use smart loader to find relevant chunks
    const context = await this.smartLoader.loadContext(query, {
      maxTokens: 8000,
      maxChunks: 10,
      includeRelated: true
    });
    
    // Format loaded content
    const content = this.smartLoader.formatContext(context);
    
    return {
      type: 'smart',
      content,
      chunks: context.summary.totalChunks,
      tokens: context.summary.totalTokens,
      query,
      topMatches: context.summary.topScores
    };
  }

  /**
   * Load recent chunks
   */
  async loadRecentChunks(manifest, count = 5) {
    console.log(`Loading ${count} most recent chunks...`);
    
    // Get last N chunks
    const recentChunks = manifest.chunks.slice(-count);
    const contents = [];
    let totalTokens = 0;
    
    for (const chunkInfo of recentChunks) {
      const chunk = await this.indexManager.loadChunk(chunkInfo.id);
      if (chunk) {
        contents.push(chunk.content);
        totalTokens += chunk.metadata.tokens;
      }
    }
    
    return {
      type: 'recent',
      content: contents.join('\n\n---\n\n'),
      chunks: contents.length,
      tokens: totalTokens
    };
  }

  /**
   * Load all chunks in order
   */
  async loadAllChunks(manifest) {
    console.log('Loading all chunks...');
    
    const contents = [];
    let totalTokens = 0;
    
    // Sort by position
    const sortedChunks = manifest.chunks.sort((a, b) => a.position - b.position);
    
    for (const chunkInfo of sortedChunks) {
      const chunk = await this.indexManager.loadChunk(chunkInfo.id);
      if (chunk) {
        contents.push(chunk.content);
        totalTokens += chunk.metadata.tokens;
      }
    }
    
    return {
      type: 'full',
      content: contents.join('\n\n'),
      chunks: contents.length,
      tokens: totalTokens
    };
  }

  /**
   * Search within checkpoint chunks
   */
  async searchInCheckpoint(checkpointFile, query) {
    const manifestPath = checkpointFile.replace('.md', '-manifest.json');
    
    try {
      const manifestData = await fs.readFile(manifestPath, 'utf8');
      const manifest = JSON.parse(manifestData);
      
      // Search through chunks
      const results = [];
      
      for (const chunkInfo of manifest.chunks) {
        const chunk = await this.indexManager.loadChunk(chunkInfo.id);
        if (chunk && chunk.content.toLowerCase().includes(query.toLowerCase())) {
          results.push({
            chunkId: chunkInfo.id,
            position: chunkInfo.position,
            preview: chunk.content.substring(0, 200) + '...',
            score: chunk.content.toLowerCase().split(query.toLowerCase()).length - 1
          });
        }
      }
      
      // Sort by score
      results.sort((a, b) => b.score - a.score);
      
      return results;
    } catch {
      // Not a chunked checkpoint
      return [];
    }
  }
}

// CLI interface for testing
if (require.main === module) {
  const args = process.argv.slice(2);
  const [checkpointFile, query] = args;
  
  if (!checkpointFile) {
    console.error('Usage: checkpoint-loader.js <checkpoint-file> [query]');
    process.exit(1);
  }
  
  const mementoDir = process.env.MEMENTO_DIR || path.join(process.env.HOME, '.claude/memento');
  
  async function main() {
    try {
      const loader = new CheckpointLoader(mementoDir);
      await loader.initialize();
      
      const options = query ? { query } : {};
      const result = await loader.loadCheckpoint(checkpointFile, options);
      
      console.log('\nLoad Result:');
      console.log(`Type: ${result.type}`);
      console.log(`Chunks: ${result.chunks}`);
      console.log(`Tokens: ${result.tokens}`);
      
      if (result.topMatches) {
        console.log('\nTop Matches:');
        result.topMatches.forEach(match => {
          console.log(`- ${match.id}: Score ${match.score}`);
        });
      }
      
      console.log('\n--- Content Preview ---');
      console.log(result.content.substring(0, 500) + '...');
    } catch (error) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  }
  
  main();
}

module.exports = CheckpointLoader;