// Test per la ricerca client-side di AI-Theoretical
// Eseguire con: node search.test.js

// Mock dei dati papers
const PAPERS_DATA = [
    {
        title: "Quantum Consciousness and AI",
        author: "John Smith",
        abstract: "This paper explores quantum mechanics and artificial intelligence.",
        date: "2025-01-15",
        ai_model: "Claude 3.5"
    },
    {
        title: "Ethics of Machine Learning",
        author: "Jane Doe",
        abstract: "A study on ethical considerations in ML systems.",
        date: "2024-06-20",
        ai_model: "GPT-4"
    },
    {
        title: "Philosophical Foundations of AI",
        author: "John Smith",
        abstract: "Examining philosophical roots of AI research.",
        date: "2025-03-10",
        ai_model: "Claude 3.5"
    }
];

// Funzione di ricerca (copiata da index.html)
function matchesPaper(paper, query) {
    if (!query) return true;
    const q = query.toLowerCase();
    const words = q.split(/\s+/).filter(w => w.length > 0);
    const searchable = `${paper.title} ${paper.author} ${paper.abstract || ''} ${paper.ai_model || ''}`.toLowerCase();
    return words.every(word => searchable.includes(word));
}

// Test framework minimale
let passed = 0;
let failed = 0;

function test(name, fn) {
    try {
        fn();
        console.log(`✓ ${name}`);
        passed++;
    } catch (e) {
        console.log(`✗ ${name}: ${e.message}`);
        failed++;
    }
}

function assertEqual(actual, expected, msg = '') {
    if (actual !== expected) {
        throw new Error(`Expected ${expected}, got ${actual}. ${msg}`);
    }
}

// TEST SUITE

test("Search empty query returns all papers", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, ''));
    assertEqual(results.length, 3);
});

test("Search by author name", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'John Smith'));
    assertEqual(results.length, 2);
});

test("Search by author case insensitive", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'john smith'));
    assertEqual(results.length, 2);
});

test("Search by title keyword", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'Quantum'));
    assertEqual(results.length, 1);
});

test("Search by abstract keyword", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'ethical'));
    assertEqual(results.length, 1);
});

test("Search by AI model", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'Claude'));
    assertEqual(results.length, 2);
});

test("Search multi-word query (AND logic)", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'John Quantum'));
    assertEqual(results.length, 1);
});

test("Search no results", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'Nonexistent'));
    assertEqual(results.length, 0);
});

test("Search partial word match", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'philos'));
    assertEqual(results.length, 1);
});

test("Search with mixed case", () => {
    const results = PAPERS_DATA.filter(p => matchesPaper(p, 'MACHINE learning'));
    assertEqual(results.length, 1);
});

// Risultato
console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
