const repo = document.getElementById("repository");
const searchInput = document.getElementById("searchInput");
const searchStatus = document.getElementById("searchStatus");
const sortSelect = document.getElementById("sortSelect");

let allPapers = [];
let currentTrack = "all";
let currentView = "full";
let currentPage = 1;
let searchResults = null; // null = no search active, array = search results
const PAPERS_PER_PAGE = 10;

// Algolia configuration
const ALGOLIA_APP_ID = "KXM87UO2YZ";
const ALGOLIA_SEARCH_KEY = "9007e1d3d632c25e106acd34be41425c";
let algoliaIndex = null;

const TRACK_INFO = {
    researchPreprint: { label: "Research Preprint", icon: "📚" },
    workingPaper: { label: "Working Paper", icon: "📝" },
    expositoryEssay: { label: "Expository Essay", icon: "📖" },
    criticalReview: { label: "Critical Review", icon: "🔍" }
};

function initAlgolia() {
    if (typeof algoliasearch !== "undefined") {
        algoliaIndex = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY).initIndex("papers");
    }
}

// Get active papers from local data
function getActivePapers() {
    return allPapers.filter(function(p) { return p.status === "active"; });
}

// Apply track filter to a list of papers
function applyTrackFilter(papers) {
    if (currentTrack === "all") return papers;
    return papers.filter(function(p) { return p.track === currentTrack; });
}

// Sort papers
function sortPapers(papers) {
    var sort = sortSelect.value;
    return papers.slice().sort(function(a, b) {
        if (sort === "date-desc") return (b.date || "").localeCompare(a.date || "");
        if (sort === "date-asc") return (a.date || "").localeCompare(b.date || "");
        if (sort === "title-asc") return a.title.localeCompare(b.title);
        if (sort === "title-desc") return b.title.localeCompare(a.title);
        return 0;
    });
}

// Get papers to display (combines search results with track filter)
function getPapersToDisplay() {
    var base = searchResults !== null ? searchResults : getActivePapers();
    var filtered = applyTrackFilter(base);
    return sortPapers(filtered);
}

// Execute Algolia search
function doSearch() {
    var query = searchInput.value.trim();
    
    // Less than 3 chars: clear search, show all
    if (query.length < 3) {
        searchResults = null;
        currentPage = 1;
        render();
        return;
    }
    
    // No Algolia: fallback to local search
    if (!algoliaIndex) {
        doLocalSearch(query);
        return;
    }
    
    // Algolia search (no track filter here - we filter after)
    algoliaIndex.search(query, { hitsPerPage: 100 }).then(function(results) {
        // Map to local papers to get full data and verify they exist
        var papers = [];
        results.hits.forEach(function(hit) {
            var local = allPapers.find(function(p) { return p.slug === hit.slug && p.status === "active"; });
            if (local) {
                papers.push(local);
            }
        });
        searchResults = papers;
        currentPage = 1;
        render();
    }).catch(function(err) {
        console.error("Algolia error:", err);
        doLocalSearch(query);
    });
}

// Local search fallback
function doLocalSearch(query) {
    var q = query.toLowerCase();
    var words = q.split(/\s+/).filter(function(w) { return w.length > 0; });
    
    searchResults = getActivePapers().filter(function(p) {
        var text = (p.title + " " + p.author + " " + (p.abstract || "")).toLowerCase();
        return words.every(function(word) { return text.indexOf(word) >= 0; });
    });
    currentPage = 1;
    render();
}

// Main render function
function render() {
    var papers = getPapersToDisplay();
    var query = searchInput.value.trim();
    var highlightQuery = query.length >= 3 ? query : "";
    
    if (currentView === "full") {
        renderFull(papers, highlightQuery);
    } else {
        renderCompact(papers, highlightQuery);
    }
    
    updateStatus(papers);
    updateTrackCounts();
}

function highlightText(text, query) {
    if (!query || !text) return text;
    var words = query.toLowerCase().split(/\s+/).filter(function(w) { return w.length > 2; });
    if (words.length === 0) return text;
    var regex = new RegExp("(" + words.join("|") + ")", "gi");
    return text.replace(regex, '<span class="highlight">$1</span>');
}

function renderFull(papers, query) {
    var start = (currentPage - 1) * PAPERS_PER_PAGE;
    var pageItems = papers.slice(start, start + PAPERS_PER_PAGE);
    
    var html = pageItems.map(function(p, idx) {
        var i = start + idx;
        var title = highlightText(p.title, query);
        var author = highlightText(p.author, query);
        var abstract = highlightText(p.abstract, query);
        var trackInfo = TRACK_INFO[p.track] || { label: "Paper", icon: "📄" };
        
        return '<article class="paper-entry">' +
            '<div class="paper-track-badge track-' + p.track + '">' + trackInfo.icon + ' ' + trackInfo.label + '</div>' +
            '<h2 class="paper-title">' + title + '</h2>' +
            '<div class="paper-meta">' +
                'By <strong>' + author + '</strong> · <span class="ai-tag">' + p.ai_model + '</span>' + 
                (p.date ? ' · ' + p.date : '') + (p.pages ? ' · ' + p.pages + ' pages' : '') +
            '</div>' +
            '<div class="btn-group">' +
                '<a href="' + p.pdf_file + '" class="btn btn-black download-link">Download PDF</a>' +
                '<button class="btn btn-white" onclick="toggle(\'abs-' + i + '\')">Abstract</button>' +
                '<button class="btn btn-white" onclick="toggle(\'ass-' + i + '\')">AI Assessment</button>' +
                (p.notes ? '<button class="btn btn-white" onclick="toggle(\'notes-' + i + '\')">Notes</button>' : '') +
            '</div>' +
            '<div id="abs-' + i + '" class="abstract-panel">' +
                '<strong>Abstract:</strong><br><br>' + abstract +
            '</div>' +
            '<div id="ass-' + i + '" class="abstract-panel"><strong>AI Editorial Assessment:</strong><br><br><pre style="white-space: pre-wrap; font-family: inherit;">' + p.ai_assessment + '</pre></div>' +
            (p.notes ? '<div id="notes-' + i + '" class="abstract-panel"><strong>Notes on AI Collaboration:</strong><br><br><pre style="white-space: pre-wrap; font-family: inherit;">' + p.notes + '</pre></div>' : '') +
        '</article>';
    }).join("");
    
    html += renderPagination(papers.length);
    repo.innerHTML = html;
    
    // Attach download confirmation handlers
    document.querySelectorAll(".download-link").forEach(function(link) {
        link.addEventListener("click", function(e) {
            var filename = link.href.split("/").pop();
            if (!confirm("Download " + filename + "?")) {
                e.preventDefault();
            }
        });
    });
}

function renderCompact(papers, query) {
    var start = (currentPage - 1) * PAPERS_PER_PAGE;
    var pageItems = papers.slice(start, start + PAPERS_PER_PAGE);
    
    var html = '<div class="compact-list">';
    html += pageItems.map(function(p) {
        var title = highlightText(p.title, query);
        var trackInfo = TRACK_INFO[p.track] || { label: "Paper", icon: "📄" };
        
        return '<div class="compact-item">' +
            '<span class="compact-track track-' + p.track + '">' + trackInfo.icon + '</span>' +
            '<a href="' + p.pdf_file + '" class="compact-title download-link">' + title + '</a>' +
            '<span class="compact-author">' + p.author + '</span>' +
            '<span class="compact-date">' + (p.date || "") + '</span>' +
        '</div>';
    }).join("");
    html += '</div>';
    
    html += renderPagination(papers.length);
    repo.innerHTML = html;
    
    // Attach download confirmation handlers
    document.querySelectorAll(".download-link").forEach(function(link) {
        link.addEventListener("click", function(e) {
            var filename = link.href.split("/").pop();
            if (!confirm("Download " + filename + "?")) {
                e.preventDefault();
            }
        });
    });
}

function renderPagination(total) {
    var totalPages = Math.ceil(total / PAPERS_PER_PAGE);
    if (totalPages <= 1) return "";
    
    var html = '<div class="pagination">';
    if (currentPage > 1) {
        html += '<button onclick="goToPage(' + (currentPage - 1) + ')">← Prev</button>';
    }
    html += '<span class="page-info">Page ' + currentPage + ' of ' + totalPages + '</span>';
    if (currentPage < totalPages) {
        html += '<button onclick="goToPage(' + (currentPage + 1) + ')">Next →</button>';
    }
    html += '</div>';
    return html;
}

function goToPage(page) {
    currentPage = page;
    render();
    repo.scrollIntoView({ behavior: "smooth" });
}

function updateStatus(papers) {
    var total = getActivePapers().length;
    var query = searchInput.value.trim();
    
    if (query.length >= 3) {
        searchStatus.innerHTML = '<strong>' + papers.length + '</strong> result' + (papers.length !== 1 ? 's' : '') + ' for "' + query + '"';
    } else if (currentTrack !== "all") {
        searchStatus.innerHTML = 'Showing <strong>' + papers.length + '</strong> of ' + total + ' papers';
    } else {
        searchStatus.innerHTML = '<strong>' + total + '</strong> papers published';
    }
}

function updateTrackCounts() {
    var activePapers = getActivePapers();
    document.querySelectorAll(".track-btn").forEach(function(btn) {
        var track = btn.dataset.track;
        var count;
        if (track === "all") {
            count = activePapers.length;
        } else {
            count = activePapers.filter(function(p) { return p.track === track; }).length;
        }
        var existing = btn.querySelector(".track-count");
        if (existing) existing.remove();
        btn.childNodes.forEach(function(node) {
            if (node.nodeType === 3) {
                node.textContent = node.textContent.replace(/\s*\d+\s*$/, '');
            }
        });
        var countSpan = document.createElement("span");
        countSpan.className = "track-count";
        countSpan.textContent = count;
        btn.appendChild(countSpan);
    });
}

function toggle(id) { 
    document.getElementById(id).classList.toggle("show"); 
}

var searchTimeout = null;

function init() {
    if (typeof PAPERS_DATA === "undefined") return;
    allPapers = PAPERS_DATA;
    
    initAlgolia();
    
    // Track buttons
    document.querySelectorAll(".track-btn").forEach(function(btn) {
        btn.addEventListener("click", function() {
            document.querySelectorAll(".track-btn").forEach(function(b) { b.classList.remove("active"); });
            btn.classList.add("active");
            currentTrack = btn.dataset.track;
            currentPage = 1;
            render();
        });
    });
    
    // View buttons
    document.querySelectorAll(".view-btn").forEach(function(btn) {
        btn.addEventListener("click", function() {
            document.querySelectorAll(".view-btn").forEach(function(b) { b.classList.remove("active"); });
            btn.classList.add("active");
            currentView = btn.dataset.view;
            render();
        });
    });
    
    // Search input with debounce
    searchInput.addEventListener("input", function() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(doSearch, 300);
    });
    
    // Sort change
    sortSelect.addEventListener("change", function() {
        render();
    });
    
    render();
}

window.onload = init;
