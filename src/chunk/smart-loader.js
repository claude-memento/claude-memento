#!/usr/bin/env node

/**
 * Claude Memento - Smart Loader
 * Intelligent context loading with query-based search and graph expansion
 */

const fs = require('fs').promises;
const path = require('path');
const Vectorizer = require('./vectorizer');
const GraphDB = require('./graph');

class SmartLoader {
  constructor(mementoDir, indexManager) {
    this.mementoDir = mementoDir || path.join(process.env.HOME, '.claude', 'memento');
    this.chunksDir = path.join(this.mementoDir, 'chunks');
    this.checkpointsDir = path.join(this.mementoDir, 'checkpoints');
    this.indexManager = indexManager;
    this.vectorizer = new Vectorizer(this.mementoDir);
    this.graph = new GraphDB(this.mementoDir);
    this.tokenBudget = 10000; // Default token budget
  }

  /**
   * Initialize loader components
   */
  async initialize() {
    await this.vectorizer.initialize();
    await this.graph.initialize();
  }

  /**
   * Load context based on query
   */
  async loadContext(query, options = {}) {
    const {
      maxTokens = this.tokenBudget,
      maxChunks = 20,
      includeRelated = true,
      relatedDepth = 1
    } = options;

    // Find relevant chunks
    const candidates = await this.findRelevantChunks(query);
    
    // Score and rank chunks
    const scored = await this.scoreChunks(candidates, query);
    
    // Select chunks within token budget
    const selected = await this.selectChunks(scored, maxTokens, maxChunks);
    
    // Expand with related chunks if requested
    if (includeRelated) {
      await this.expandWithRelated(selected, relatedDepth, maxTokens);
    }
    
    // Load and assemble chunks
    const context = await this.assembleContext(selected);
    
    return context;
  }

  /**
   * Query-based intelligent loading with graph expansion
   */
  async query(searchQuery, options = {}) {
    const {
      maxChunks = 5,
      expandDepth = 2,
      includeRelated = true,
      minScore = 0.3
    } = options;

    console.error(`[SmartLoader] Searching for: "${searchQuery}"`);

    // Step 1: Vector search for initial chunks
    const vectorResults = await this.vectorizer.search(searchQuery, maxChunks * 2);
    console.error(`[SmartLoader] Found ${vectorResults.length} initial matches`);

    // Step 2: Graph expansion if enabled
    let expandedResults = [];
    if (includeRelated && vectorResults.length > 0) {
      const topResults = vectorResults.slice(0, Math.ceil(maxChunks / 2));
      
      for (const result of topResults) {
        const related = this.graph.findRelated(result.id, expandDepth);
        expandedResults.push(...related);
      }
      
      console.error(`[SmartLoader] Expanded to ${expandedResults.length} related chunks`);
    }

    // Step 3: Score and rank all chunks
    const allChunks = await this.scoreChunks(
      [...vectorResults, ...expandedResults],
      searchQuery,
      minScore
    );

    // Step 4: Deduplicate and sort
    const uniqueChunks = this.deduplicateChunks(allChunks);
    const sortedChunks = uniqueChunks.sort((a, b) => b.score - a.score);

    // Step 5: Load actual content for top chunks
    const finalChunks = sortedChunks.slice(0, maxChunks);
    const loadedChunks = await this.loadChunkContent(finalChunks);

    console.error(`[SmartLoader] Returning ${loadedChunks.length} chunks`);
    return loadedChunks;
  }

  /**
   * Find potentially relevant chunks
   */
  async findRelevantChunks(query) {
    const candidates = new Set();
    
    // 1. Keyword search
    const keywords = query.split(/\s+/).filter(w => w.length > 2);
    const keywordResults = await this.indexManager.searchByKeywords(keywords.join(' '));
    
    keywordResults.slice(0, 30).forEach(result => {
      candidates.add(result.id);
    });
    
    // 2. Vector similarity search (if vectorizer has documents)
    if (this.vectorizer.documents.size > 0) {
      const similar = this.vectorizer.findSimilar(query, 20);
      similar.forEach(doc => {
        candidates.add(doc.id);
      });
    }
    
    return Array.from(candidates);
  }

  /**
   * Score chunks based on relevance
   */
  async scoreChunks(chunkIds, query) {
    const scored = [];
    
    for (const chunkId of chunkIds) {
      const chunk = await this.indexManager.loadChunk(chunkId);
      if (!chunk) continue;
      
      let score = 0;
      
      // Keyword matching score
      const queryWords = query.toLowerCase().split(/\s+/);
      const chunkWords = chunk.content.toLowerCase().split(/\s+/);
      
      queryWords.forEach(qWord => {
        chunkWords.forEach(cWord => {
          if (cWord.includes(qWord)) {
            score += 1;
          }
        });
      });
      
      // Boost recent chunks
      const age = Date.now() - new Date(chunk.metadata.created || 0).getTime();
      const ageBoost = Math.max(0, 1 - age / (7 * 24 * 60 * 60 * 1000)); // Decay over 7 days
      score *= (1 + ageBoost * 0.5);
      
      // TF-IDF similarity if available
      if (this.vectorizer.documents.has(chunkId)) {
        const queryVector = this.vectorizer.vectorizeText(query);
        const chunkVector = this.vectorizer.vectorize(chunkId);
        const similarity = this.vectorizer.cosineSimilarity(queryVector, chunkVector);
        score += similarity * 10;
      }
      
      scored.push({
        id: chunkId,
        score,
        tokens: chunk.metadata.tokens || 1000,
        chunk
      });
    }
    
    // Sort by score descending
    scored.sort((a, b) => b.score - a.score);
    
    return scored;
  }

  /**
   * Select chunks within token budget
   */
  async selectChunks(scored, maxTokens, maxChunks) {
    const selected = [];
    let totalTokens = 0;
    
    for (const item of scored) {
      if (selected.length >= maxChunks) break;
      if (totalTokens + item.tokens > maxTokens) continue;
      
      selected.push(item);
      totalTokens += item.tokens;
    }
    
    return selected;
  }

  /**
   * Expand selection with related chunks
   */
  async expandWithRelated(selected, depth, maxTokens) {
    const currentIds = new Set(selected.map(s => s.id));
    const relatedCandidates = [];
    let totalTokens = selected.reduce((sum, s) => sum + s.tokens, 0);
    
    // Find related chunks
    for (const item of selected) {
      const related = this.indexManager.getRelated(item.id, null, depth);
      
      for (const rel of related) {
        if (!currentIds.has(rel.id)) {
          const chunk = await this.indexManager.loadChunk(rel.id);
          if (chunk) {
            relatedCandidates.push({
              id: rel.id,
              score: item.score * (1 / (rel.distance + 1)), // Decay by distance
              tokens: chunk.metadata.tokens || 1000,
              chunk,
              relation: rel.type
            });
          }
        }
      }
    }
    
    // Sort related by score
    relatedCandidates.sort((a, b) => b.score - a.score);
    
    // Add related chunks within budget
    for (const candidate of relatedCandidates) {
      if (totalTokens + candidate.tokens <= maxTokens) {
        selected.push(candidate);
        totalTokens += candidate.tokens;
        currentIds.add(candidate.id);
      }
    }
  }

  /**
   * Assemble chunks into coherent context
   */
  async assembleContext(selected) {
    // Group by position if they're from same sequence
    const sequences = new Map();
    const standalone = [];
    
    selected.forEach(item => {
      const meta = item.chunk.metadata;
      if (meta.checkpointId && meta.position !== undefined) {
        const key = `${meta.checkpointId}-${meta.total}`;
        if (!sequences.has(key)) {
          sequences.set(key, []);
        }
        sequences.get(key).push(item);
      } else {
        standalone.push(item);
      }
    });
    
    // Sort sequences by position
    sequences.forEach(seq => {
      seq.sort((a, b) => 
        a.chunk.metadata.position - b.chunk.metadata.position
      );
    });
    
    // Build context
    const contextParts = [];
    
    // Add sequences
    sequences.forEach((seq, key) => {
      contextParts.push({
        type: 'sequence',
        chunks: seq.map(s => s.chunk)
      });
    });
    
    // Add standalone chunks
    standalone.forEach(item => {
      contextParts.push({
        type: 'standalone',
        chunks: [item.chunk]
      });
    });
    
    // Generate summary
    const summary = {
      totalChunks: selected.length,
      totalTokens: selected.reduce((sum, s) => sum + s.tokens, 0),
      sequences: sequences.size,
      topScores: selected.slice(0, 5).map(s => ({
        id: s.id,
        score: s.score.toFixed(2)
      }))
    };
    
    return {
      parts: contextParts,
      summary,
      selected
    };
  }

  /**
   * Update vectorizer with new chunks
   */
  async updateVectorizer(chunks) {
    chunks.forEach(chunk => {
      this.vectorizer.addDocument(chunk.id, chunk.content);
    });
  }

  /**
   * Get context as text
   */
  formatContext(context) {
    const parts = [];
    
    context.parts.forEach(part => {
      if (part.type === 'sequence') {
        parts.push('=== Related Context ===');
        part.chunks.forEach(chunk => {
          parts.push(chunk.content);
          parts.push('---');
        });
      } else {
        parts.push('=== Context Chunk ===');
        part.chunks.forEach(chunk => {
          parts.push(chunk.content);
          parts.push('---');
        });
      }
    });
    
    return parts.join('\n\n');
  }

  /**
   * Deduplicate chunks
   */
  deduplicateChunks(chunks) {
    const seen = new Set();
    const unique = [];

    for (const chunk of chunks) {
      const id = chunk.id || chunk.node?.id;
      if (id && !seen.has(id)) {
        seen.add(id);
        unique.push(chunk);
      }
    }

    return unique;
  }

  /**
   * Load actual content for chunks
   */
  async loadChunkContent(chunks) {
    const loaded = [];

    for (const chunk of chunks) {
      const chunkId = chunk.id || chunk.node?.id;
      if (!chunkId) continue;

      try {
        const chunkFile = path.join(this.chunksDir, `${chunkId}.md`);
        const content = await fs.readFile(chunkFile, 'utf8');
        
        loaded.push({
          id: chunkId,
          content: content,
          score: chunk.score,
          factors: chunk.factors,
          metadata: chunk.node || {}
        });
      } catch (error) {
        console.error(`[SmartLoader] Failed to load chunk ${chunkId}: ${error.message}`);
      }
    }

    return loaded;
  }
}

module.exports = SmartLoader;