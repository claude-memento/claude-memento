#!/usr/bin/env node

/**
 * Chunk command implementation for Claude Code integration
 */

const fs = require('fs').promises;
const path = require('path');
const Chunker = require('../chunk/chunker');
const Vectorizer = require('../chunk/vectorizer');
const IndexManager = require('../chunk/index-manager');
const SmartLoader = require('../chunk/smart-loader');

class ChunkCommand {
  constructor(mementoDir) {
    this.mementoDir = mementoDir;
    this.chunker = new Chunker();
    this.vectorizer = new Vectorizer();
    this.indexManager = new IndexManager(mementoDir);
    this.smartLoader = new SmartLoader(this.indexManager, this.vectorizer);
  }

  async initialize() {
    await this.indexManager.initialize();
  }

  /**
   * Process chunk command
   */
  async execute(args) {
    const [subcommand, ...params] = args;

    switch (subcommand) {
      case 'create':
        return await this.createChunks(params);
      
      case 'search':
        return await this.searchChunks(params);
      
      case 'load':
        return await this.loadContext(params);
      
      case 'stats':
        return await this.showStats();
      
      case 'list':
        return await this.listChunks(params);
      
      case 'delete':
        return await this.deleteChunk(params);
      
      default:
        return this.showHelp();
    }
  }

  /**
   * Create chunks from input
   */
  async createChunks(params) {
    const content = params.join(' ');
    
    if (!content) {
      console.log('Error: No content provided');
      return;
    }

    console.log('Creating chunks...');
    
    // Generate chunks
    const chunks = await this.chunker.chunk(content, {
      source: 'manual',
      created: new Date().toISOString()
    });

    // Process each chunk
    for (const chunk of chunks) {
      // Extract keywords and summary
      chunk.keywords = this.chunker.extractKeywords(chunk.content);
      chunk.summary = this.chunker.generateSummary(chunk.content);
      
      // Save chunk
      await this.indexManager.saveChunk(chunk);
      
      // Update vectorizer
      this.vectorizer.addDocument(chunk.id, chunk.content);
      
      console.log(`Created chunk ${chunk.id} (${chunk.metadata.tokens} tokens)`);
    }

    console.log(`\nCreated ${chunks.length} chunks`);
    console.log('Chunks are linked: ' + chunks.map(c => c.id.substring(0, 8)).join(' → '));
  }

  /**
   * Search chunks
   */
  async searchChunks(params) {
    const query = params.join(' ');
    
    if (!query) {
      console.log('Error: No search query provided');
      return;
    }

    console.log(`Searching for: "${query}"\n`);
    
    // Keyword search
    const keywordResults = await this.indexManager.searchByKeywords(query);
    
    if (keywordResults.length === 0) {
      console.log('No chunks found');
      return;
    }

    // Display results
    console.log(`Found ${keywordResults.length} chunks:\n`);
    
    for (const result of keywordResults.slice(0, 10)) {
      console.log(`[${result.id.substring(0, 8)}] Score: ${result.score}`);
      console.log(`Summary: ${result.summary.substring(0, 100)}...`);
      console.log(`Keywords: ${result.keywords.slice(0, 5).map(k => k.word).join(', ')}`);
      console.log('---');
    }
  }

  /**
   * Load context based on query
   */
  async loadContext(params) {
    const query = params.join(' ');
    
    if (!query) {
      console.log('Error: No query provided');
      return;
    }

    console.log(`Loading context for: "${query}"\n`);
    
    const context = await this.smartLoader.loadContext(query, {
      maxTokens: 8000,
      maxChunks: 10,
      includeRelated: true
    });

    // Display summary
    console.log('Context Summary:');
    console.log(`- Total chunks: ${context.summary.totalChunks}`);
    console.log(`- Total tokens: ${context.summary.totalTokens}`);
    console.log(`- Sequences: ${context.summary.sequences}`);
    console.log('\nTop matches:');
    
    context.summary.topScores.forEach(item => {
      console.log(`  [${item.id.substring(0, 8)}] Score: ${item.score}`);
    });

    console.log('\n=== Assembled Context ===\n');
    console.log(this.smartLoader.formatContext(context));
  }

  /**
   * Show statistics
   */
  async showStats() {
    const stats = this.indexManager.getStats();
    const vectorStats = this.vectorizer.getStats();
    
    console.log('Chunk Statistics:');
    console.log(`- Total chunks: ${stats.totalChunks}`);
    console.log(`- Total tokens: ${stats.totalTokens}`);
    console.log(`- Checkpoints: ${stats.checkpoints}`);
    console.log(`- Relations: ${stats.relations}`);
    console.log('\nVector Statistics:');
    console.log(`- Documents: ${vectorStats.documents}`);
    console.log(`- Vocabulary: ${vectorStats.vocabulary}`);
    console.log(`- Avg tokens: ${Math.round(vectorStats.averageTokens)}`);
  }

  /**
   * List chunks
   */
  async listChunks(params) {
    const [filter] = params;
    const chunks = [];
    
    this.indexManager.index.forEach((entry, id) => {
      if (!filter || entry.summary.includes(filter)) {
        chunks.push({ id, ...entry });
      }
    });

    // Sort by creation date
    chunks.sort((a, b) => 
      new Date(b.created).getTime() - new Date(a.created).getTime()
    );

    console.log(`Showing ${chunks.length} chunks:\n`);
    
    chunks.slice(0, 20).forEach(chunk => {
      console.log(`[${chunk.id.substring(0, 8)}] ${new Date(chunk.created).toLocaleString()}`);
      console.log(`  ${chunk.summary.substring(0, 80)}...`);
      console.log(`  Tokens: ${chunk.metadata.tokens || 'unknown'}`);
    });
  }

  /**
   * Delete chunk
   */
  async deleteChunk(params) {
    const [chunkId] = params;
    
    if (!chunkId) {
      console.log('Error: No chunk ID provided');
      return;
    }

    await this.indexManager.deleteChunk(chunkId);
    console.log(`Deleted chunk ${chunkId}`);
  }

  /**
   * Show help
   */
  showHelp() {
    console.log(`
Claude Memento Chunk Commands:

  /cm:chunk create <content>    Create chunks from content
  /cm:chunk search <query>      Search chunks by keywords
  /cm:chunk load <query>        Load smart context based on query
  /cm:chunk stats              Show chunk statistics
  /cm:chunk list [filter]      List all chunks
  /cm:chunk delete <id>        Delete a specific chunk

Examples:
  /cm:chunk create "Long text to be chunked..."
  /cm:chunk search "claude memento"
  /cm:chunk load "previous conversation about API"
    `);
  }
}

// Export for use in bridge
module.exports = ChunkCommand;