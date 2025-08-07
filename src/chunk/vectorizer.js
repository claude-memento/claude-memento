#!/usr/bin/env node

/**
 * TF-IDF based text vectorization for Claude Memento
 * Pure JavaScript implementation without external dependencies
 */

class Vectorizer {
  constructor() {
    this.documents = new Map();
    this.idf = new Map();
    this.vocabulary = new Set();
  }

  /**
   * Tokenize text into words
   */
  tokenize(text) {
    return text.toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(word => word.length > 2);
  }

  /**
   * Calculate term frequency
   */
  calculateTF(tokens) {
    const tf = new Map();
    const totalTokens = tokens.length;
    
    tokens.forEach(token => {
      tf.set(token, (tf.get(token) || 0) + 1);
    });
    
    // Normalize by total tokens
    tf.forEach((count, token) => {
      tf.set(token, count / totalTokens);
    });
    
    return tf;
  }

  /**
   * Calculate inverse document frequency
   */
  calculateIDF() {
    const documentCount = this.documents.size;
    
    this.vocabulary.forEach(term => {
      let docWithTerm = 0;
      
      this.documents.forEach(doc => {
        if (doc.tokens.includes(term)) {
          docWithTerm++;
        }
      });
      
      // IDF = log(N / df)
      const idf = Math.log(documentCount / (docWithTerm || 1));
      this.idf.set(term, idf);
    });
  }

  /**
   * Add document to corpus
   */
  addDocument(id, text) {
    const tokens = this.tokenize(text);
    tokens.forEach(token => this.vocabulary.add(token));
    
    this.documents.set(id, {
      text,
      tokens,
      tf: this.calculateTF(tokens)
    });
    
    // Recalculate IDF when new document is added
    this.calculateIDF();
  }

  /**
   * Calculate TF-IDF vector for a document
   */
  vectorize(id) {
    const doc = this.documents.get(id);
    if (!doc) return null;
    
    const vector = new Map();
    
    doc.tf.forEach((tf, term) => {
      const idf = this.idf.get(term) || 0;
      vector.set(term, tf * idf);
    });
    
    return vector;
  }

  /**
   * Calculate TF-IDF vector for new text (not in corpus)
   */
  vectorizeText(text) {
    const tokens = this.tokenize(text);
    const tf = this.calculateTF(tokens);
    const vector = new Map();
    
    tf.forEach((tfValue, term) => {
      const idf = this.idf.get(term) || Math.log(this.documents.size + 1);
      vector.set(term, tfValue * idf);
    });
    
    return vector;
  }

  /**
   * Calculate cosine similarity between two vectors
   */
  cosineSimilarity(vector1, vector2) {
    let dotProduct = 0;
    let norm1 = 0;
    let norm2 = 0;
    
    // Get all unique terms
    const allTerms = new Set([...vector1.keys(), ...vector2.keys()]);
    
    allTerms.forEach(term => {
      const v1 = vector1.get(term) || 0;
      const v2 = vector2.get(term) || 0;
      
      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    });
    
    norm1 = Math.sqrt(norm1);
    norm2 = Math.sqrt(norm2);
    
    if (norm1 === 0 || norm2 === 0) return 0;
    
    return dotProduct / (norm1 * norm2);
  }

  /**
   * Find similar documents
   */
  findSimilar(queryText, topK = 5) {
    const queryVector = this.vectorizeText(queryText);
    const similarities = [];
    
    this.documents.forEach((doc, id) => {
      const docVector = this.vectorize(id);
      const similarity = this.cosineSimilarity(queryVector, docVector);
      
      similarities.push({
        id,
        similarity,
        text: doc.text.substring(0, 100) + '...'
      });
    });
    
    // Sort by similarity descending
    similarities.sort((a, b) => b.similarity - a.similarity);
    
    return similarities.slice(0, topK);
  }

  /**
   * Extract N-grams from tokens
   */
  extractNgrams(tokens, n = 2) {
    const ngrams = [];
    
    for (let i = 0; i <= tokens.length - n; i++) {
      ngrams.push(tokens.slice(i, i + n).join(' '));
    }
    
    return ngrams;
  }

  /**
   * Get document statistics
   */
  getStats() {
    return {
      documents: this.documents.size,
      vocabulary: this.vocabulary.size,
      averageTokens: Array.from(this.documents.values())
        .reduce((sum, doc) => sum + doc.tokens.length, 0) / this.documents.size
    };
  }

  /**
   * Export vectors for persistence
   */
  exportVectors() {
    const vectors = {};
    
    this.documents.forEach((doc, id) => {
      const vector = this.vectorize(id);
      vectors[id] = {
        terms: Array.from(vector.entries())
          .filter(([term, weight]) => weight > 0.01)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 50)
      };
    });
    
    return {
      vectors,
      idf: Array.from(this.idf.entries()),
      stats: this.getStats()
    };
  }

  /**
   * Import vectors from persistence
   */
  importVectors(data) {
    if (data.idf) {
      this.idf = new Map(data.idf);
    }
    
    // Reconstruct vocabulary from IDF
    this.idf.forEach((value, term) => {
      this.vocabulary.add(term);
    });
  }
}

module.exports = Vectorizer;