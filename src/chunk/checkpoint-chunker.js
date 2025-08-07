#!/usr/bin/env node

/**
 * Checkpoint-specific chunking for automatic content splitting
 */

const fs = require('fs').promises;
const path = require('path');
const Chunker = require('./chunker');
const IndexManager = require('./index-manager');
const Vectorizer = require('./vectorizer');

class CheckpointChunker {
  constructor(mementoDir) {
    this.mementoDir = mementoDir;
    this.chunker = new Chunker({
      maxTokens: 2000,  // Smaller chunks for checkpoints
      minTokens: 500,
      overlap: 50
    });
    this.indexManager = new IndexManager(mementoDir);
    this.vectorizer = new Vectorizer();
  }

  async initialize() {
    await this.indexManager.initialize();
  }

  /**
   * Process checkpoint content and create chunks if needed
   */
  async processCheckpoint(checkpointFile, content) {
    const stats = await fs.stat(checkpointFile);
    const sizeKB = stats.size / 1024;
    
    console.log(`Checkpoint size: ${sizeKB.toFixed(2)} KB`);
    
    // Check if chunking is needed (>10KB)
    if (sizeKB < 10) {
      console.log('Checkpoint small enough, no chunking needed');
      return null;
    }

    console.log('Large checkpoint detected, creating chunks...');
    
    // Generate checkpoint ID
    const checkpointId = path.basename(checkpointFile, '.md');
    
    // Create chunks
    const chunks = await this.chunker.chunk(content, {
      checkpointId,
      source: 'checkpoint',
      created: new Date().toISOString()
    });

    // Save chunks and build manifest
    const manifest = {
      checkpointId,
      created: new Date().toISOString(),
      originalSize: stats.size,
      chunks: [],
      summary: {
        totalChunks: chunks.length,
        totalTokens: 0
      }
    };

    for (const chunk of chunks) {
      // Extract keywords and summary
      chunk.keywords = this.chunker.extractKeywords(chunk.content);
      chunk.summary = this.chunker.generateSummary(chunk.content);
      
      // Save chunk
      await this.indexManager.saveChunk(chunk);
      
      // Update vectorizer
      this.vectorizer.addDocument(chunk.id, chunk.content);
      
      // Add to manifest
      manifest.chunks.push({
        id: chunk.id,
        position: chunk.metadata.position,
        tokens: chunk.metadata.tokens,
        summary: chunk.summary.substring(0, 100)
      });
      
      manifest.summary.totalTokens += chunk.metadata.tokens;
    }

    // Save manifest
    const manifestPath = checkpointFile.replace('.md', '-manifest.json');
    await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
    
    console.log(`Created ${chunks.length} chunks (${manifest.summary.totalTokens} tokens)`);
    console.log(`Manifest saved to: ${manifestPath}`);
    
    // Create simplified checkpoint file
    const simplifiedContent = this.createSimplifiedCheckpoint(manifest);
    await fs.writeFile(checkpointFile, simplifiedContent);
    
    return manifest;
  }

  /**
   * Create simplified checkpoint content with chunk references
   */
  createSimplifiedCheckpoint(manifest) {
    const chunks = manifest.chunks
      .map(c => `- ${c.id.substring(0, 8)}: ${c.summary}...`)
      .join('\n');
    
    return `# 📸 Chunked Checkpoint: ${manifest.checkpointId}

**Created**: ${new Date(manifest.created).toLocaleString()}
**Status**: Chunked (${manifest.summary.totalChunks} chunks, ${manifest.summary.totalTokens} tokens)

---

## 📦 Content Chunks

This checkpoint was automatically split into chunks for efficient storage and retrieval.

### Chunk List:
${chunks}

### Loading Instructions:
Use \`/cm:load ${manifest.checkpointId}\` to automatically load and assemble all chunks.

### Manifest Location:
\`${manifest.checkpointId}-manifest.json\`

---

*Original size: ${(manifest.originalSize / 1024).toFixed(2)} KB*
`;
  }

  /**
   * Check if a checkpoint has been chunked
   */
  async isChunked(checkpointFile) {
    const manifestPath = checkpointFile.replace('.md', '-manifest.json');
    try {
      await fs.access(manifestPath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get manifest for a checkpoint
   */
  async getManifest(checkpointFile) {
    const manifestPath = checkpointFile.replace('.md', '-manifest.json');
    try {
      const data = await fs.readFile(manifestPath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      return null;
    }
  }
}

// CLI interface for testing
if (require.main === module) {
  const args = process.argv.slice(2);
  const [checkpointFile] = args;
  
  if (!checkpointFile) {
    console.error('Usage: checkpoint-chunker.js <checkpoint-file>');
    process.exit(1);
  }
  
  const mementoDir = process.env.MEMENTO_DIR || path.join(process.env.HOME, '.claude/memento');
  
  async function main() {
    try {
      const chunker = new CheckpointChunker(mementoDir);
      await chunker.initialize();
      
      const content = await fs.readFile(checkpointFile, 'utf8');
      const manifest = await chunker.processCheckpoint(checkpointFile, content);
      
      if (manifest) {
        console.log('Chunking completed successfully');
      } else {
        console.log('No chunking needed');
      }
    } catch (error) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  }
  
  main();
}

module.exports = CheckpointChunker;