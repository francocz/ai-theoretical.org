Class {
	#name : 'ATStyles',
	#superclass : 'Object',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'css' }
ATStyles class >> baseCss [
	^ ':root {
    --accent-blue: #2563eb;
    --text-main: #1a1a1a;
    --text-muted: #666;
    --border: #e5e5e0;
}

* { margin: 0; padding: 0; box-sizing: border-box; }
body {
    font-family: ''Inter'', sans-serif;
    background: #fff;
    color: var(--text-main);
    line-height: 1.6;
    padding: 0 40px;
}
.container {
    max-width: 1000px;
    margin: 0 auto;
}

header {
    padding: 60px 0 30px;
}

.nav {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-decoration: none;
    display: inline-block;
    margin-bottom: 10px;
}

h1 {
    font-family: ''Playfair Display'', serif;
    font-size: 2.4rem;
    font-weight: 700;
    letter-spacing: -1px;
    margin-bottom: 20px;
}

hr {
    border: 0;
    border-top: 1px solid var(--border);
    margin-bottom: 40px;
}

.section {
    max-width: 720px;
    font-size: 0.95rem;
    margin-bottom: 30px;
}

footer {
    margin: 80px 0 60px;
    padding-top: 40px;
    border-top: 1px solid var(--border);
    font-size: 0.85rem;
    color: var(--text-muted);
    text-align: center;
}

footer a {
    color: var(--text-muted);
    text-decoration: none;
}

footer a:hover {
    color: var(--accent-blue);
}'
]

{ #category : 'css' }
ATStyles class >> indexCss [
    ^ '
/* HEADER */
header { padding: 60px 0 30px; }
.top-subtitle { 
    font-size: 0.7rem; 
    text-transform: uppercase; 
    letter-spacing: 4px; 
    color: var(--accent-blue); 
    margin-bottom: 15px;
    font-weight: 400;
}
h1 { 
    font-family: ''Playfair Display'', serif; 
    font-size: 3.2rem; 
    font-weight: 700; 
    letter-spacing: -1.5px; 
    margin-bottom: 30px;
}
hr { border: 0; border-top: 1px solid var(--border); margin-bottom: 50px; }

/* MANIFESTO */
.manifesto-grid {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 60px;
    margin-bottom: 80px;
    align-items: start;
}
.manifesto-label {
    font-size: 0.65rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    border-top: 2px solid var(--text-main);
    padding-top: 10px;
    width: fit-content;
}
.manifesto-label a {
    font-size: 0.65rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    color: var(--text-main);
    text-decoration: none;
    display: block;
    margin-bottom: 4px;
}
.manifesto-label a:hover {
    color: var(--accent-blue);
}
.manifesto-quote {
    font-size: 1.15rem;
    font-weight: 300;
    font-style: italic;
    color: var(--text-muted);
    line-height: 1.5;
    margin-bottom: 15px;
}

/* SEARCH */
.search-section {
    margin-bottom: 40px;
}
.search-box {
    display: flex;
    gap: 0;
    flex-wrap: wrap;
    align-items: center;
}
.search-input {
    flex: 1;
    min-width: 200px;
    padding: 12px 16px;
    font-size: 0.95rem;
    border: 1px solid var(--border);
    border-radius: 4px 0 0 4px;
    font-family: inherit;
}
.search-input:focus {
    outline: none;
    border-color: var(--accent-blue);
}
.search-btn {
    padding: 12px 16px;
    font-size: 1rem;
    border: 1px solid var(--border);
    border-left: none;
    border-radius: 0 4px 4px 0;
    background: var(--text-main);
    color: #fff;
    cursor: pointer;
    transition: 0.2s;
}
.search-btn:hover {
    background: var(--accent-blue);
    border-color: var(--accent-blue);
}
.search-filters {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
    margin-top: 10px;
}
.filter-select {
    padding: 8px 12px;
    font-size: 0.85rem;
    border: 1px solid var(--border);
    border-radius: 4px;
    background: #fff;
    font-family: inherit;
    cursor: pointer;
}
.search-results-count {
    font-size: 0.85rem;
    color: var(--text-muted);
    margin-top: 15px;
}
.clear-search {
    font-size: 0.85rem;
    color: var(--accent-blue);
    cursor: pointer;
    text-decoration: underline;
    margin-left: 10px;
}

/* PAPER SECTION */
.paper-entry { border-left: 1px solid var(--border); padding-left: 30px; margin-bottom: 50px; }
.paper-title { font-family: ''Playfair Display'', serif; font-size: 1.5rem; margin-bottom: 8px; }
.paper-meta { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 15px; }
.ai-tag { color: var(--accent-blue); font-weight: 600; }

.btn-group { display: flex; gap: 12px; flex-wrap: wrap; }
.btn { 
    padding: 8px 16px; font-size: 0.75rem; font-weight: 600; text-decoration: none; 
    cursor: pointer; border: 1px solid var(--text-main); transition: 0.2s;
}
.btn-black { background: var(--text-main); color: #fff; }
.btn-black:hover { background: var(--accent-blue); border-color: var(--accent-blue); }
.btn-white { background: #fff; color: var(--text-main); }
.btn-white:hover { border-color: var(--accent-blue); color: var(--accent-blue); }

.abstract-panel { 
    max-height: 0; overflow: hidden; transition: 0.4s ease; 
    background: #f9f9f9; font-size: 0.9rem;
}
.abstract-panel.show { max-height: 800px; padding: 20px; margin: 15px 0; border: 1px solid var(--border); }

.highlight {
    background-color: #fff3cd;
    padding: 1px 3px;
    border-radius: 2px;
}

/* FOOTER INDEX */
footer a {
    color: var(--accent-blue);
    text-decoration: none;
}
.powered-by {
    margin-top: 30px;
    font-size: 0.8rem;
    color: var(--text-muted);
}
.powered-by a {
    color: var(--text-muted);
    text-decoration: none;
}
.powered-by a:hover {
    color: var(--accent-blue);
}

@media (max-width: 768px) {
    .manifesto-grid { grid-template-columns: 1fr; gap: 30px; }
    body { padding: 0 20px; }
    h1 { font-size: 2.2rem; }
}'
]

{ #category : 'as yet unclassified' }
ATStyles class >> trackFiltersCss [
    ^ '
/* Track filters */
.track-filters {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin: 20px 0;
}

.track-btn {
    background: #f5f5f3;
    border: 1px solid var(--border);
    padding: 8px 16px;
    font-size: 0.85rem;
    font-family: inherit;
    cursor: pointer;
    transition: all 0.2s;
    color: var(--text-muted);
}

.track-btn:hover {
    background: #eee;
}

.track-btn.active {
    background: var(--text-main);
    color: white;
    border-color: var(--text-main);
}

.track-count {
    display: inline-block;
    background: rgba(0,0,0,0.1);
    padding: 2px 6px;
    border-radius: 10px;
    font-size: 0.75rem;
    margin-left: 6px;
}

.track-btn.active .track-count {
    background: rgba(255,255,255,0.2);
}

/* View controls */
.view-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin: 15px 0;
}

.view-toggle {
    display: flex;
    gap: 4px;
}

.view-btn {
    background: #f5f5f3;
    border: 1px solid var(--border);
    padding: 6px 12px;
    font-size: 1rem;
    cursor: pointer;
    color: var(--text-muted);
}

.view-btn:hover {
    background: #eee;
}

.view-btn.active {
    background: var(--text-main);
    color: white;
    border-color: var(--text-main);
}

.sort-select {
    padding: 8px 12px;
    font-size: 0.85rem;
    font-family: inherit;
    border: 1px solid var(--border);
    background: white;
    color: var(--text-main);
}

/* Track badges - pastel colors */
.paper-track-badge {
    display: inline-block;
    font-size: 0.75rem;
    padding: 4px 10px;
    border-radius: 3px;
    margin-bottom: 10px;
    font-weight: 500;
}

.track-researchPreprint {
    background: #e8f4f8;
    color: #2c5f6e;
}

.track-workingPaper {
    background: #f0f4e8;
    color: #4a5f3c;
}

.track-expositoryEssay {
    background: #faf3e8;
    color: #6b5a3f;
}

.track-criticalReview {
    background: #f3e8f4;
    color: #5f3c6b;
}

/* Compact view */
.compact-list {
    border-top: 1px solid var(--border);
}

.compact-item {
    display: grid;
    grid-template-columns: 30px 1fr auto auto;
    gap: 15px;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid var(--border);
    font-size: 0.9rem;
}

.compact-track {
    font-size: 1.1rem;
}

.compact-title {
    color: var(--text-main);
    text-decoration: none;
    font-weight: 500;
}

.compact-title:hover {
    color: var(--accent-blue);
}

.compact-author {
    color: var(--text-muted);
    font-size: 0.85rem;
}

.compact-date {
    color: var(--text-muted);
    font-size: 0.8rem;
    white-space: nowrap;
}

/* Pagination */
.pagination {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 20px;
    margin: 40px 0;
    padding-top: 20px;
    border-top: 1px solid var(--border);
}

.pagination button {
    background: white;
    border: 1px solid var(--border);
    padding: 8px 16px;
    font-family: inherit;
    font-size: 0.85rem;
    cursor: pointer;
    color: var(--text-main);
}

.pagination button:hover {
    background: #f5f5f3;
}

.page-info {
    color: var(--text-muted);
    font-size: 0.85rem;
}
'
]
