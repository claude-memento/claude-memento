#!/usr/bin/env node

/**
 * Text chunking module for Claude Memento
 * Splits large texts into manageable chunks with metadata
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

class Chunker {
  constructor(options = {}) {
    this.options = {
      maxTokens: options.maxTokens || 2500,
      minTokens: options.minTokens || 500,
      overlap: options.overlap || 100,
      boundaryRegex: /\n\n+|^#{1,3}\s.+$|^---+$/gm,
      ...options
    };
    
    // Simple token estimation (4 chars ≈ 1 token)
    this.charsPerToken = 4;
  }

  /**
   * Estimate token count from text
   */
  estimateTokens(text) {
    return Math.ceil(text.length / this.charsPerToken);
  }

  /**
   * Find natural boundaries in text
   */
  findBoundaries(text) {
    const boundaries = [0];
    let match;
    
    while ((match = this.options.boundaryRegex.exec(text)) !== null) {
      boundaries.push(match.index);
    }
    
    boundaries.push(text.length);
    return [...new Set(boundaries)].sort((a, b) => a - b);
  }

  /**
   * Split text into chunks
   */
  async chunk(text, metadata = {}) {
    const tokens = this.estimateTokens(text);
    
    // If text is small enough, return as single chunk
    if (tokens <= this.options.maxTokens) {
      return [{
        id: this.generateId(text),
        content: text,
        metadata: {
          ...metadata,
          tokens,
          position: 0,
          total: 1
        }
      }];
    }

    // Find natural boundaries
    const boundaries = this.findBoundaries(text);
    const chunks = [];
    let currentChunk = '';
    let currentStart = 0;
    let position = 0;

    for (let i = 1; i < boundaries.length; i++) {
      const segment = text.slice(boundaries[i-1], boundaries[i]);
      const segmentTokens = this.estimateTokens(segment);
      const currentTokens = this.estimateTokens(currentChunk);

      // Check if adding segment would exceed limit
      if (currentTokens + segmentTokens > this.options.maxTokens && currentChunk) {
        // Save current chunk
        chunks.push({
          content: currentChunk.trim(),
          start: currentStart,
          end: boundaries[i-1]
        });
        
        // Start new chunk with overlap
        const overlapStart = Math.max(0, boundaries[i-1] - this.options.overlap * this.charsPerToken);
        currentChunk = text.slice(overlapStart, boundaries[i]);
        currentStart = overlapStart;
      } else {
        // Add segment to current chunk
        currentChunk += segment;
      }
    }

    // Add remaining content
    if (currentChunk.trim()) {
      chunks.push({
        content: currentChunk.trim(),
        start: currentStart,
        end: text.length
      });
    }

    // Generate final chunks with metadata
    return chunks.map((chunk, index) => ({
      id: this.generateId(chunk.content),
      content: chunk.content,
      metadata: {
        ...metadata,
        tokens: this.estimateTokens(chunk.content),
        position: index,
        total: chunks.length,
        previous: index > 0 ? this.generateId(chunks[index-1].content) : null,
        next: index < chunks.length - 1 ? this.generateId(chunks[index+1].content) : null
      }
    }));
  }

  /**
   * Generate unique ID for chunk
   */
  generateId(content) {
    return crypto
      .createHash('sha256')
      .update(content)
      .digest('hex')
      .substring(0, 16);
  }

  /**
   * Extract keywords from text (simple version)
   */
  extractKeywords(text) {
    // Remove common words and punctuation
    const stopWords = new Set([
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'is', 'was', 'are', 'were', 'been', 'be',
      'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
      'it', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'we', 'they'
    ]);

    const words = text.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2 && !stopWords.has(word));

    // Count frequency
    const frequency = {};
    words.forEach(word => {
      frequency[word] = (frequency[word] || 0) + 1;
    });

    // Sort by frequency and return top keywords
    return Object.entries(frequency)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([word, count]) => ({ word, count }));
  }

  /**
   * Generate summary for chunk (simple extractive)
   */
  generateSummary(text, maxLength = 200) {
    const sentences = text.match(/[^.!?]+[.!?]+/g) || [];
    if (sentences.length === 0) return text.substring(0, maxLength) + '...';
    
    // Take first few sentences that fit in maxLength
    let summary = '';
    for (const sentence of sentences) {
      if (summary.length + sentence.length > maxLength) break;
      summary += sentence;
    }
    
    return summary.trim() || sentences[0].substring(0, maxLength) + '...';
  }
}

module.exports = Chunker;