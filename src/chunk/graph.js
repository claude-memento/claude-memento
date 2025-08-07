#!/usr/bin/env node

/**
 * Claude Memento - Graph Database for Chunk Relationships
 * Manages relationships between chunks for intelligent context loading
 */

const fs = require('fs').promises;
const path = require('path');

class GraphDB {
    constructor(mementoDir) {
        this.mementoDir = mementoDir;
        this.graphFile = path.join(mementoDir, 'chunks', 'graph.json');
        this.nodes = {}; // chunk nodes
        this.edges = []; // relationships between chunks
        this.index = {}; // quick lookup indices
    }

    /**
     * Initialize or load existing graph
     */
    async initialize() {
        try {
            const data = await fs.readFile(this.graphFile, 'utf8');
            const graph = JSON.parse(data);
            this.nodes = graph.nodes || {};
            this.edges = graph.edges || [];
            this.index = graph.index || {};
        } catch (error) {
            // Initialize empty graph if file doesn't exist
            this.nodes = {};
            this.edges = [];
            this.index = {};
        }
    }

    /**
     * Add a chunk node to the graph
     */
    addNode(chunkId, metadata) {
        this.nodes[chunkId] = {
            id: chunkId,
            created: metadata.timestamp || new Date().toISOString(),
            keywords: metadata.keywords || [],
            tokens: metadata.tokens || 0,
            position: metadata.position || 0,
            checkpoint: metadata.checkpoint || null,
            embedding: metadata.embedding || null
        };

        // Update keyword index
        if (metadata.keywords) {
            metadata.keywords.forEach(keyword => {
                if (!this.index[keyword]) {
                    this.index[keyword] = [];
                }
                if (!this.index[keyword].includes(chunkId)) {
                    this.index[keyword].push(chunkId);
                }
            });
        }
    }

    /**
     * Add a relationship between chunks
     */
    addRelation(fromId, toId, type, weight = 1.0, metadata = {}) {
        // Validate nodes exist
        if (!this.nodes[fromId] || !this.nodes[toId]) {
            throw new Error(`Node not found: ${!this.nodes[fromId] ? fromId : toId}`);
        }

        // Check if edge already exists
        const existingEdge = this.edges.find(
            e => e.from === fromId && e.to === toId && e.type === type
        );

        if (existingEdge) {
            // Update weight if edge exists
            existingEdge.weight = Math.max(existingEdge.weight, weight);
            return;
        }

        // Add new edge
        this.edges.push({
            from: fromId,
            to: toId,
            type: type, // sequential, semantic, hierarchical, reference
            weight: weight,
            created: new Date().toISOString(),
            ...metadata
        });
    }

    /**
     * Find related chunks using BFS
     */
    findRelated(chunkId, depth = 2, types = null) {
        if (!this.nodes[chunkId]) {
            return [];
        }

        const visited = new Set();
        const queue = [{ id: chunkId, level: 0 }];
        const related = [];

        while (queue.length > 0) {
            const { id, level } = queue.shift();

            if (visited.has(id) || level > depth) {
                continue;
            }

            visited.add(id);

            if (id !== chunkId) {
                related.push({
                    id: id,
                    level: level,
                    node: this.nodes[id]
                });
            }

            // Find all edges from this node
            const outgoingEdges = this.edges.filter(e => {
                if (types && !types.includes(e.type)) {
                    return false;
                }
                return e.from === id;
            });

            // Add neighbors to queue
            outgoingEdges.forEach(edge => {
                if (!visited.has(edge.to)) {
                    queue.push({ id: edge.to, level: level + 1 });
                }
            });
        }

        // Sort by level and return
        return related.sort((a, b) => a.level - b.level);
    }

    /**
     * Calculate semantic similarity between chunks
     */
    calculateSimilarity(chunkId1, chunkId2) {
        const node1 = this.nodes[chunkId1];
        const node2 = this.nodes[chunkId2];

        if (!node1 || !node2) {
            return 0;
        }

        // Simple keyword overlap similarity
        const keywords1 = new Set(node1.keywords || []);
        const keywords2 = new Set(node2.keywords || []);
        
        if (keywords1.size === 0 || keywords2.size === 0) {
            return 0;
        }

        const intersection = new Set([...keywords1].filter(x => keywords2.has(x)));
        const union = new Set([...keywords1, ...keywords2]);

        return intersection.size / union.size;
    }

    /**
     * Build semantic relationships automatically
     */
    async buildSemanticRelations(threshold = 0.3) {
        const chunkIds = Object.keys(this.nodes);
        
        for (let i = 0; i < chunkIds.length; i++) {
            for (let j = i + 1; j < chunkIds.length; j++) {
                const similarity = this.calculateSimilarity(chunkIds[i], chunkIds[j]);
                
                if (similarity >= threshold) {
                    this.addRelation(
                        chunkIds[i],
                        chunkIds[j],
                        'semantic',
                        similarity,
                        { similarity: similarity }
                    );
                    // Add bidirectional relation for semantic similarity
                    this.addRelation(
                        chunkIds[j],
                        chunkIds[i],
                        'semantic',
                        similarity,
                        { similarity: similarity }
                    );
                }
            }
        }
    }

    /**
     * Find chunks by keyword
     */
    findByKeyword(keyword) {
        const normalizedKeyword = keyword.toLowerCase();
        const chunkIds = this.index[normalizedKeyword] || [];
        
        return chunkIds.map(id => ({
            id: id,
            node: this.nodes[id]
        }));
    }

    /**
     * Get subgraph for a checkpoint
     */
    getCheckpointGraph(checkpointId) {
        const checkpointNodes = Object.values(this.nodes)
            .filter(node => node.checkpoint === checkpointId);
        
        const nodeIds = new Set(checkpointNodes.map(n => n.id));
        
        const checkpointEdges = this.edges.filter(edge => 
            nodeIds.has(edge.from) && nodeIds.has(edge.to)
        );

        return {
            nodes: checkpointNodes,
            edges: checkpointEdges
        };
    }

    /**
     * Prune old relationships
     */
    pruneOldRelations(daysOld = 30) {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysOld);
        const cutoffISO = cutoffDate.toISOString();

        this.edges = this.edges.filter(edge => {
            return !edge.created || edge.created > cutoffISO;
        });
    }

    /**
     * Save graph to disk
     */
    async save() {
        const graphData = {
            nodes: this.nodes,
            edges: this.edges,
            index: this.index,
            metadata: {
                version: '1.0.0',
                updated: new Date().toISOString(),
                nodeCount: Object.keys(this.nodes).length,
                edgeCount: this.edges.length
            }
        };

        await fs.mkdir(path.dirname(this.graphFile), { recursive: true });
        await fs.writeFile(
            this.graphFile,
            JSON.stringify(graphData, null, 2),
            'utf8'
        );
    }

    /**
     * Get graph statistics
     */
    getStats() {
        const edgeTypes = {};
        this.edges.forEach(edge => {
            edgeTypes[edge.type] = (edgeTypes[edge.type] || 0) + 1;
        });

        return {
            nodeCount: Object.keys(this.nodes).length,
            edgeCount: this.edges.length,
            edgeTypes: edgeTypes,
            indexedKeywords: Object.keys(this.index).length,
            avgDegree: this.edges.length / Math.max(1, Object.keys(this.nodes).length)
        };
    }

    /**
     * Export graph for visualization
     */
    exportForVisualization() {
        return {
            nodes: Object.values(this.nodes).map(node => ({
                id: node.id,
                label: `Chunk ${node.position}`,
                group: node.checkpoint || 'orphan',
                value: node.tokens
            })),
            edges: this.edges.map(edge => ({
                from: edge.from,
                to: edge.to,
                label: edge.type,
                value: edge.weight,
                arrows: edge.type === 'sequential' ? 'to' : undefined
            }))
        };
    }
}

// CLI interface
if (require.main === module) {
    const mementoDir = process.env.MEMENTO_DIR || path.join(process.env.HOME, '.claude', 'memento');
    const graph = new GraphDB(mementoDir);

    const command = process.argv[2];
    const args = process.argv.slice(3);

    (async () => {
        await graph.initialize();

        switch (command) {
            case 'stats':
                console.log(JSON.stringify(graph.getStats(), null, 2));
                break;

            case 'find':
                if (args[0]) {
                    const related = graph.findRelated(args[0], parseInt(args[1] || 2));
                    console.log(JSON.stringify(related, null, 2));
                }
                break;

            case 'keyword':
                if (args[0]) {
                    const chunks = graph.findByKeyword(args[0]);
                    console.log(JSON.stringify(chunks, null, 2));
                }
                break;

            case 'build-semantic':
                await graph.buildSemanticRelations(parseFloat(args[0] || 0.3));
                await graph.save();
                console.log('Semantic relations built');
                break;

            case 'export':
                const vizData = graph.exportForVisualization();
                console.log(JSON.stringify(vizData, null, 2));
                break;

            default:
                console.log('Usage: graph.js <command> [args]');
                console.log('Commands:');
                console.log('  stats - Show graph statistics');
                console.log('  find <chunkId> [depth] - Find related chunks');
                console.log('  keyword <keyword> - Find chunks by keyword');
                console.log('  build-semantic [threshold] - Build semantic relations');
                console.log('  export - Export for visualization');
        }
    })().catch(console.error);
}

module.exports = GraphDB;