const repo = document.getElementById("repository");
const searchInput = document.getElementById("searchInput");
const searchStatus = document.getElementById("searchStatus");
const sortSelect = document.getElementById("sortSelect");

let allPapers = [];
let currentTrack = "all";
let currentView = "full";
let currentPage = 1;
const PAPERS_PER_PAGE = 10;

// Algolia configuration
const ALGOLIA_APP_ID = "KXM87UO2YZ";
const ALGOLIA_SEARCH_KEY = "9007e1d3d632c25e106acd34be41425c";
let algoliaIndex = null;

function initAlgolia() {
    if (typeof algoliasearch !== "undefined") {
        algoliaIndex = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY).initIndex("papers");
    }
}

function doAlgoliaSearch() {
    var query = searchInput.value.trim();
    
    // If empty query, reset to normal view
    if (!query) { 
        filterAndRender(); 
        return; 
    }
    
    // Minimum 3 characters
    if (query.length < 3) {
        filterAndRender();
        return;
    }
    
    if (!algoliaIndex) { 
        filterAndRender(); 
        return; 
    }
    
    var filters = currentTrack !== "all" ? "track:" + currentTrack : "";
    algoliaIndex.search(query, { filters: filters, hitsPerPage: 50 }).then(function(results) {
        // Map Algolia results back to local papers to get full data (ai_assessment, notes, etc)
        var papers = [];
        results.hits.forEach(function(h) {
            var localPaper = allPapers.find(function(p) { return p.slug === h.slug; });
            if (localPaper && localPaper.status === "active") {
                papers.push(localPaper);
            }
        });
        
        currentPage = 1;
        if (currentView === "full") { 
            renderPapersFull(papers, query); 
        } else { 
            renderPapersCompact(papers, query); 
        }
        searchStatus.innerHTML = "<strong>" + papers.length + "</strong> result" + (papers.length !== 1 ? "s" : "") + " for \"" + query + "\"";
    }).catch(function() { 
        filterAndRender(); 
    });
}

const TRACK_INFO = {
    researchPreprint: { label: "Research Preprint", icon: "📚" },
    workingPaper: { label: "Working Paper", icon: "📝" },
    expositoryEssay: { label: "Expository Essay", icon: "📖" },
    criticalReview: { label: "Critical Review", icon: "🔍" }
};

function highlightText(text, query) {
    if (!query || !text) return text;
    const words = query.toLowerCase().split(/\s+/).filter(w => w.length > 2);
    if (words.length === 0) return text;
    const regex = new RegExp("(" + words.join("|") + ")", "gi");
    return text.replace(regex, '<span class="highlight">$1</span>');
}

function matchesPaper(paper, query) {
    if (!query) return true;
    const q = query.toLowerCase();
    const words = q.split(/\s+/).filter(w => w.length > 0);
    const searchable = (paper.title + " " + paper.author + " " + (paper.abstract || "") + " " + (paper.ai_model || "")).toLowerCase();
    return words.every(word => searchable.includes(word));
}

function getActivePapers() {
    return allPapers.filter(p => p.status === "active");
}

function getFilteredPapers() {
    const query = searchInput.value.trim();
    let filtered = getActivePapers().filter(p => {
        if (!matchesPaper(p, query)) return false;
        if (currentTrack !== "all" && p.track !== currentTrack) return false;
        return true;
    });
    return sortPapers(filtered);
}

function sortPapers(papers) {
    const sort = sortSelect.value;
    return papers.sort((a, b) => {
        if (sort === "date-desc") return (b.date || "").localeCompare(a.date || "");
        if (sort === "date-asc") return (a.date || "").localeCompare(b.date || "");
        if (sort === "title-asc") return a.title.localeCompare(b.title);
        if (sort === "title-desc") return b.title.localeCompare(a.title);
        return 0;
    });
}

function filterAndRender() {
    currentPage = 1;
    renderAll();
}

function renderAll() {
    const filtered = getFilteredPapers();
    const query = searchInput.value.trim();
    
    if (currentView === "full") {
        renderPapersFull(filtered, query);
    } else {
        renderPapersCompact(filtered, query);
    }
    
    updateStatus(filtered.length, getActivePapers().length);
    updateTrackCounts();
}

function renderPapersFull(papers, query) {
    const start = (currentPage - 1) * PAPERS_PER_PAGE;
    const pageItems = papers.slice(start, start + PAPERS_PER_PAGE);
    
    let html = pageItems.map((p, idx) => {
        const i = start + idx;
        const title = highlightText(p.title, query);
        const author = highlightText(p.author, query);
        const abstract = highlightText(p.abstract, query);
        const trackInfo = TRACK_INFO[p.track] || { label: "Paper", icon: "📄" };
        
        return '<article class="paper-entry">' +
            '<div class="paper-track-badge track-' + p.track + '">' + trackInfo.icon + ' ' + trackInfo.label + '</div>' +
            '<h2 class="paper-title">' + title + '</h2>' +
            '<div class="paper-meta">' +
                'By <strong>' + author + '</strong> · <span class="ai-tag">' + p.ai_model + '</span>' + 
                (p.date ? ' · ' + p.date : '') + (p.pages ? ' · ' + p.pages + ' pages' : '') +
            '</div>' +
            '<div class="btn-group">' +
                '<a href="' + p.pdf_file + '" class="btn btn-black" download>Download PDF</a>' +
                '<button class="btn btn-white" onclick="toggle(\'abs-' + i + '\')">Abstract</button>' +
                (p.ai_assessment ? '<button class="btn btn-white" onclick="toggle(\'ass-' + i + '\')">AI Assessment</button>' : '') +
                (p.notes ? '<button class="btn btn-white" onclick="toggle(\'notes-' + i + '\')">Notes</button>' : '') +
            '</div>' +
            '<div id="abs-' + i + '" class="abstract-panel">' +
                '<strong>Abstract:</strong><br><br>' + abstract +
            '</div>' +
            (p.ai_assessment ? '<div id="ass-' + i + '" class="abstract-panel"><strong>AI Editorial Assessment:</strong><br><br><pre style="white-space: pre-wrap; font-family: inherit;">' + p.ai_assessment + '</pre></div>' : '') +
            (p.notes ? '<div id="notes-' + i + '" class="abstract-panel"><strong>Notes on AI Collaboration:</strong><br><br><pre style="white-space: pre-wrap; font-family: inherit;">' + p.notes + '</pre></div>' : '') +
        '</article>';
    }).join("");
    
    html += renderPagination(papers.length);
    repo.innerHTML = html;
}

function renderPapersCompact(papers, query) {
    const start = (currentPage - 1) * PAPERS_PER_PAGE;
    const pageItems = papers.slice(start, start + PAPERS_PER_PAGE);
    
    let html = '<div class="compact-list">';
    html += pageItems.map(p => {
        const title = highlightText(p.title, query);
        const trackInfo = TRACK_INFO[p.track] || { label: "Paper", icon: "📄" };
        
        return '<div class="compact-item">' +
            '<span class="compact-track track-' + p.track + '">' + trackInfo.icon + '</span>' +
            '<a href="' + p.pdf_file + '" class="compact-title" download>' + title + '</a>' +
            '<span class="compact-author">' + p.author + '</span>' +
            '<span class="compact-date">' + (p.date || "") + '</span>' +
        '</div>';
    }).join("");
    html += '</div>';
    
    html += renderPagination(papers.length);
    repo.innerHTML = html;
}

function renderPagination(total) {
    const totalPages = Math.ceil(total / PAPERS_PER_PAGE);
    if (totalPages <= 1) return "";
    
    let html = '<div class="pagination">';
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
    renderAll();
    repo.scrollIntoView({ behavior: "smooth" });
}

function updateStatus(shown, total) {
    const query = searchInput.value.trim();
    const hasFilters = query || currentTrack !== "all";
    if (hasFilters) {
        searchStatus.innerHTML = 'Showing <strong>' + shown + '</strong> of ' + total + ' papers';
    } else {
        searchStatus.innerHTML = '<strong>' + total + '</strong> papers published';
    }
}

function updateTrackCounts() {
    const activePapers = getActivePapers();
    document.querySelectorAll(".track-btn").forEach(btn => {
        const track = btn.dataset.track;
        let count;
        if (track === "all") {
            count = activePapers.length;
        } else {
            count = activePapers.filter(p => p.track === track).length;
        }
        const existing = btn.querySelector(".track-count");
        if (existing) existing.remove();
        btn.childNodes.forEach(node => {
            if (node.nodeType === 3) {
                node.textContent = node.textContent.replace(/\s*\d+\s*$/, '');
            }
        });
        const countSpan = document.createElement("span");
        countSpan.className = "track-count";
        countSpan.textContent = count;
        btn.appendChild(countSpan);
    });
}

function clearFilters() {
    searchInput.value = "";
    currentTrack = "all";
    document.querySelectorAll(".track-btn").forEach(b => b.classList.remove("active"));
    document.querySelector('.track-btn[data-track="all"]').classList.add("active");
    filterAndRender();
}

function toggle(id) { 
    document.getElementById(id).classList.toggle("show"); 
}

function init() {
    if (typeof PAPERS_DATA === "undefined") return;
    allPapers = PAPERS_DATA;
    
    initAlgolia();
    
    document.querySelectorAll(".track-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            document.querySelectorAll(".track-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            currentTrack = btn.dataset.track;
            // If there's a search query, re-run Algolia search with new track filter
            if (searchInput.value.trim().length >= 3) {
                doAlgoliaSearch();
            } else {
                filterAndRender();
            }
        });
    });
    
    document.querySelectorAll(".view-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            document.querySelectorAll(".view-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            currentView = btn.dataset.view;
            renderAll();
        });
    });
    
    // Search on Enter
    searchInput.addEventListener("keypress", function(e) {
        if (e.key === "Enter") doAlgoliaSearch();
    });
    
    // Reset when clearing the search field
    searchInput.addEventListener("input", function() {
        if (searchInput.value.trim() === "") {
            filterAndRender();
        }
    });
    
    sortSelect.addEventListener("change", filterAndRender);
    
    renderAll();
}

window.onload = init;
