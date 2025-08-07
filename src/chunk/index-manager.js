#!/usr/bin/env node

/**
 * Index management for chunks - handles storage and retrieval
 */

const fs = require('fs').promises;
const path = require('path');

class IndexManager {
  constructor(basePath) {
    this.basePath = basePath;
    this.chunksDir = path.join(basePath, 'chunks');
    this.indexFile = path.join(basePath, 'chunks', 'index.json');
    this.graphFile = path.join(basePath, 'chunks', 'graph.json');
    this.index = new Map();
    this.graph = new Map();
  }

  /**
   * Initialize directories and load existing index
   */
  async initialize() {
    // Create directories
    await fs.mkdir(this.chunksDir, { recursive: true });
    
    // Load existing index
    try {
      const indexData = await fs.readFile(this.indexFile, 'utf8');
      const parsed = JSON.parse(indexData);
      this.index = new Map(Object.entries(parsed));
    } catch (error) {
      // Index doesn't exist yet
      this.index = new Map();
    }

    // Load graph
    try {
      const graphData = await fs.readFile(this.graphFile, 'utf8');
      const parsed = JSON.parse(graphData);
      this.graph = new Map(Object.entries(parsed));
    } catch (error) {
      this.graph = new Map();
    }
  }

  /**
   * Save chunk to disk
   */
  async saveChunk(chunk) {
    const chunkPath = path.join(this.chunksDir, `${chunk.id}.json`);
    
    // Save chunk file
    await fs.writeFile(chunkPath, JSON.stringify(chunk, null, 2));
    
    // Update index
    this.index.set(chunk.id, {
      id: chunk.id,
      created: new Date().toISOString(),
      metadata: chunk.metadata,
      keywords: chunk.keywords || [],
      summary: chunk.summary || ''
    });
    
    // Update graph relationships
    if (chunk.metadata.previous) {
      this.addRelation(chunk.metadata.previous, chunk.id, 'next');
    }
    if (chunk.metadata.next) {
      this.addRelation(chunk.id, chunk.metadata.next, 'next');
    }
    
    // Save index
    await this.saveIndex();
  }

  /**
   * Load chunk from disk
   */
  async loadChunk(chunkId) {
    const chunkPath = path.join(this.chunksDir, `${chunkId}.json`);
    
    try {
      const data = await fs.readFile(chunkPath, 'utf8');
      return JSON.parse(data);
    } catch (error) {
      console.error(`Failed to load chunk ${chunkId}:`, error);
      return null;
    }
  }

  /**
   * Add relation between chunks
   */
  addRelation(fromId, toId, type) {
    if (!this.graph.has(fromId)) {
      this.graph.set(fromId, []);
    }
    
    const relations = this.graph.get(fromId);
    const existing = relations.find(r => r.to === toId && r.type === type);
    
    if (!existing) {
      relations.push({ to: toId, type });
    }
  }

  /**
   * Get related chunks
   */
  getRelated(chunkId, type = null, depth = 1) {
    const visited = new Set();
    const related = [];
    
    const traverse = (id, currentDepth) => {
      if (currentDepth > depth || visited.has(id)) return;
      visited.add(id);
      
      const relations = this.graph.get(id) || [];
      
      relations.forEach(relation => {
        if (!type || relation.type === type) {
          related.push({
            id: relation.to,
            type: relation.type,
            distance: currentDepth
          });
          
          traverse(relation.to, currentDepth + 1);
        }
      });
    };
    
    traverse(chunkId, 1);
    return related;
  }

  /**
   * Search chunks by keywords
   */
  async searchByKeywords(keywords) {
    const results = [];
    const searchTerms = keywords.toLowerCase().split(/\s+/);
    
    this.index.forEach((entry, id) => {
      let score = 0;
      
      // Check keywords
      entry.keywords.forEach(kw => {
        searchTerms.forEach(term => {
          if (kw.word.includes(term)) {
            score += kw.count;
          }
        });
      });
      
      // Check summary
      searchTerms.forEach(term => {
        if (entry.summary.toLowerCase().includes(term)) {
          score += 1;
        }
      });
      
      if (score > 0) {
        results.push({ id, score, ...entry });
      }
    });
    
    // Sort by score descending
    results.sort((a, b) => b.score - a.score);
    
    return results;
  }

  /**
   * Get chunks by checkpoint
   */
  async getChunksByCheckpoint(checkpointId) {
    const chunks = [];
    
    this.index.forEach((entry, id) => {
      if (entry.metadata && entry.metadata.checkpointId === checkpointId) {
        chunks.push({ id, ...entry });
      }
    });
    
    // Sort by position
    chunks.sort((a, b) => 
      (a.metadata.position || 0) - (b.metadata.position || 0)
    );
    
    return chunks;
  }

  /**
   * Save index to disk
   */
  async saveIndex() {
    const indexData = Object.fromEntries(this.index);
    await fs.writeFile(this.indexFile, JSON.stringify(indexData, null, 2));
    
    const graphData = Object.fromEntries(this.graph);
    await fs.writeFile(this.graphFile, JSON.stringify(graphData, null, 2));
  }

  /**
   * Get index statistics
   */
  getStats() {
    let totalTokens = 0;
    let checkpoints = new Set();
    
    this.index.forEach(entry => {
      if (entry.metadata) {
        totalTokens += entry.metadata.tokens || 0;
        if (entry.metadata.checkpointId) {
          checkpoints.add(entry.metadata.checkpointId);
        }
      }
    });
    
    return {
      totalChunks: this.index.size,
      totalTokens,
      checkpoints: checkpoints.size,
      relations: Array.from(this.graph.values())
        .reduce((sum, relations) => sum + relations.length, 0)
    };
  }

  /**
   * Delete chunk
   */
  async deleteChunk(chunkId) {
    // Remove chunk file
    const chunkPath = path.join(this.chunksDir, `${chunkId}.json`);
    try {
      await fs.unlink(chunkPath);
    } catch (error) {
      // File might not exist
    }
    
    // Remove from index
    this.index.delete(chunkId);
    
    // Remove from graph
    this.graph.delete(chunkId);
    
    // Remove incoming relations
    this.graph.forEach((relations, fromId) => {
      const filtered = relations.filter(r => r.to !== chunkId);
      if (filtered.length !== relations.length) {
        this.graph.set(fromId, filtered);
      }
    });
    
    await this.saveIndex();
  }

  /**
   * Clear all chunks
   */
  async clearAll() {
    // Remove all chunk files
    const files = await fs.readdir(this.chunksDir);
    
    for (const file of files) {
      if (file.endsWith('.json') && file !== 'index.json' && file !== 'graph.json') {
        await fs.unlink(path.join(this.chunksDir, file));
      }
    }
    
    // Clear index and graph
    this.index.clear();
    this.graph.clear();
    
    await this.saveIndex();
  }
}

module.exports = IndexManager;