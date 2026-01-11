const repo = document.getElementById("repository");
const searchInput = document.getElementById("searchInput");
const searchStatus = document.getElementById("searchStatus");
const sortSelect = document.getElementById("sortSelect");

let allPapers = [];
let currentTrack = "all";
let currentView = "full";
let currentPage = 1;
let searchId = 0;
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

function getActivePapers() {
    return allPapers.filter(function(p) { return p.status === "active"; });
}

function applyTrackFilter(papers) {
    if (currentTrack === "all") return papers;
    return papers.filter(function(p) { return p.track === currentTrack; });
}

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

function highlightText(text, query) {
    if (!query || !text) return text;
    var words = query.toLowerCase().split(/\s+/).filter(function(w) { return w.length > 2; });
    if (words.length === 0) return text;
    var regex = new RegExp("(" + words.join("|") + ")", "gi");
    return text.replace(regex, '<span class="highlight">$1</span>');
}

// Verify that a paper actually contains the search terms
function paperContainsQuery(paper, query) {
    var q = query.toLowerCase();
    var words = q.split(/\s+/).filter(function(w) { return w.length > 0; });
    var text = (paper.title + " " + paper.author + " " + (paper.abstract || "")).toLowerCase();
    return words.every(function(word) { return text.indexOf(word) >= 0; });
}

function doRender(papers, query) {
    if (currentView === "full") {
        renderFull(papers, query);
    } else {
        renderCompact(papers, query);
    }
    updateStatus(papers, query);
    updateTrackCounts();
}

function render() {
    currentPage = 1;
    var query = searchInput.value.trim();
    var activePapers = getActivePapers();
    
    // No search or too short: show filtered papers
    if (query.length < 3) {
        var filtered = applyTrackFilter(activePapers);
        doRender(sortPapers(filtered), "");
        return;
    }
    
    // Algolia search
    if (algoliaIndex) {
        searchId++;
        var thisSearchId = searchId;
        var thisQuery = query;
        
        algoliaIndex.search(thisQuery, { hitsPerPage: 100 }).then(function(results) {
            if (thisSearchId !== searchId) return;
            
            // Get slugs from Algolia results
            var slugs = results.hits.map(function(h) { return h.slug; });
            
            // Find matching local papers
            var candidatePapers = activePapers.filter(function(p) {
                return slugs.indexOf(p.slug) >= 0;
            });
            
            // VERIFY: filter out false positives from Algolia
            var verifiedPapers = candidatePapers.filter(function(p) {
                return paperContainsQuery(p, thisQuery);
            });
            
            // Apply track filter
            var filtered = applyTrackFilter(verifiedPapers);
            
            doRender(sortPapers(filtered), thisQuery);
        }).catch(function(err) {
            console.error("Algolia error:", err);
            doRender([], query);
        });
    } else {
        // No Algolia: local search only
        var results = activePapers.filter(function(p) {
            return paperContainsQuery(p, query);
        });
        var filtered = applyTrackFilter(results);
        doRender(sortPapers(filtered), query);
    }
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
                (p.code_archive ? '<a href="' + p.code_archive + '" class="btn btn-black download-link">Download Code</a>' : '') +
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
    attachDownloadHandlers();
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
    attachDownloadHandlers();
}

function attachDownloadHandlers() {
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

function updateStatus(papers, query) {
    var total = getActivePapers().length;
    
    if (query && query.length >= 3) {
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
    
    document.querySelectorAll(".track-btn").forEach(function(btn) {
        btn.addEventListener("click", function() {
            document.querySelectorAll(".track-btn").forEach(function(b) { b.classList.remove("active"); });
            btn.classList.add("active");
            currentTrack = btn.dataset.track;
            render();
        });
    });
    
    document.querySelectorAll(".view-btn").forEach(function(btn) {
        btn.addEventListener("click", function() {
            document.querySelectorAll(".view-btn").forEach(function(b) { b.classList.remove("active"); });
            btn.classList.add("active");
            currentView = btn.dataset.view;
            render();
        });
    });
    
    searchInput.addEventListener("input", function() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(render, 300);
    });
    
    sortSelect.addEventListener("change", render);
    
    render();
}

window.onload = init;
