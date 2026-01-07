const repo = document.getElementById("repository");
const searchInput = document.getElementById("searchInput");
const searchBtn = document.getElementById("searchBtn");
const searchStatus = document.getElementById("searchStatus");
const sortSelect = document.getElementById("sortSelect");

let allPapers = [];
let currentTrack = "all";
let currentView = "full";
let currentPage = 1;
const PAPERS_PER_PAGE = 10;

// Algolia configuration
const ALGOLIA_APP_ID = 'KXM87UO2YZ';
const ALGOLIA_SEARCH_KEY = '9007e1d3d632c25e106acd34be41425c';
const ALGOLIA_INDEX = 'papers';
let algoliaIndex = null;

const TRACK_INFO = {
    researchPreprint: { label: "Research Preprint", icon: "📚" },
    workingPaper: { label: "Working Paper", icon: "📝" },
    expositoryEssay: { label: "Expository Essay", icon: "📖" },
    criticalReview: { label: "Critical Review", icon: "🔍" }
};

function initAlgolia() {
    if (typeof algoliasearch !== 'undefined') {
        const client = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY);
        algoliaIndex = client.initIndex(ALGOLIA_INDEX);
    }
}

function highlightText(text, query) {
    if (!query || !text) return text;
    const words = query.toLowerCase().split(/\\s+/).filter(w => w.length > 2);
    if (words.length === 0) return text;
    const regex = new RegExp("(" + words.join("|") + ")", "gi");
    return text.replace(regex, '<span class="highlight">$1</span>');
}

function getActivePapers() {
    return allPapers.filter(p => p.status === "active");
}

function getFilteredPapers() {
    let filtered = getActivePapers();
    if (currentTrack !== "all") {
        filtered = filtered.filter(p => p.track === currentTrack);
    }
    return sortPapers(filtered);
}

function sortPapers(papers) {
    const sort = sortSelect.value;
    return [...papers].sort((a, b) => {
        if (sort === "date-desc") return (b.date || "").localeCompare(a.date || "");
        if (sort === "date-asc") return (a.date || "").localeCompare(b.date || "");
        if (sort === "title-asc") return a.title.localeCompare(b.title);
        if (sort === "title-desc") return b.title.localeCompare(a.title);
        return 0;
    });
}

async function doSearch() {
    const query = searchInput.value.trim();
    if (!query) {
        renderAll();
        return;
    }
    
    if (!algoliaIndex) {
        // Fallback to local search
        localSearch(query);
        return;
    }
    
    try {
        let filters = "";
        if (currentTrack !== "all") {
            filters = "track:" + currentTrack;
        }
        
        const results = await algoliaIndex.search(query, {
            filters: filters,
            hitsPerPage: 50
        });
        
        renderSearchResults(results.hits, query);
    } catch (error) {
        console.error("Algolia error:", error);
        localSearch(query);
    }
}

function localSearch(query) {
    const q = query.toLowerCase();
    const words = q.split(/\\s+/).filter(w => w.length > 0);
    let filtered = getActivePapers().filter(p => {
        const searchable = (p.title + " " + p.author + " " + (p.abstract || "")).toLowerCase();
        return words.every(word => searchable.includes(word));
    });
    if (currentTrack !== "all") {
        filtered = filtered.filter(p => p.track === currentTrack);
    }
    renderSearchResults(sortPapers(filtered), query);
}

function renderSearchResults(papers, query) {
    currentPage = 1;
    if (currentView === "full") {
        renderPapersFull(papers, query);
    } else {
        renderPapersCompact(papers, query);
    }
    updateSearchStatus(papers.length, query);
}

function filterAndRender() {
    currentPage = 1;
    const query = searchInput.value.trim();
    if (query) {
        doSearch();
    } else {
        renderAll();
    }
}

function renderAll() {
    const filtered = getFilteredPapers();
    
    if (currentView === "full") {
        renderPapersFull(filtered, "");
    } else {
        renderPapersCompact(filtered, "");
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
        const author = highlightText(p.author || (p.authors ? p.authors.join(", ") : ""), query);
        const abstract = highlightText(p.abstract, query);
        const trackInfo = TRACK_INFO[p.track] || { label: "Paper", icon: "📄" };
        const pdfFile = p.pdf_file || ("papers/" + p.slug + ".pdf");
        const aiModel = p.ai_model || p.aiModels || "";
        
        return '<article class="paper-entry">' +
            '<div class="paper-track-badge track-' + p.track + '">' + trackInfo.icon + ' ' + trackInfo.label + '</div>' +
            '<h2 class="paper-title">' + title + '</h2>' +
            '<div class="paper-meta">' +
                'By <strong>' + author + '</strong>' + (aiModel ? ' · <span class="ai-tag">' + aiModel + '</span>' : '') + 
                (p.date ? ' · ' + p.date : '') + (p.pages ? ' · ' + p.pages + ' pages' : '') +
            '</div>' +
            '<div class="btn-group">' +
                '<a href="' + pdfFile + '" class="btn btn-black" download>Download PDF</a>' +
                '<button class="btn btn-white" onclick="toggle(''abs-' + i + ''')">Abstract</button>' +
                (p.ai_assessment ? '<button class="btn btn-white" onclick="toggle(''ass-' + i + ''')">AI Assessment</button>' : '') +
                (p.notes ? '<button class="btn btn-white" onclick="toggle(''notes-' + i + ''')">Notes</button>' : '') +
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
        const pdfFile = p.pdf_file || ("papers/" + p.slug + ".pdf");
        const author = p.author || (p.authors ? p.authors.join(", ") : "");
        
        return '<div class="compact-item">' +
            '<span class="compact-track track-' + p.track + '">' + trackInfo.icon + '</span>' +
            '<a href="' + pdfFile + '" class="compact-title" download>' + title + '</a>' +
            '<span class="compact-author">' + author + '</span>' +
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
    const query = searchInput.value.trim();
    if (query) {
        doSearch();
    } else {
        renderAll();
    }
    repo.scrollIntoView({ behavior: "smooth" });
}

function updateStatus(shown, total) {
    const hasFilters = currentTrack !== "all";
    if (hasFilters) {
        searchStatus.innerHTML = 'Showing <strong>' + shown + '</strong> of ' + total + ' papers <span class="clear-search" onclick="clearFilters()">Clear filters</span>';
    } else {
        searchStatus.innerHTML = '<strong>' + total + '</strong> papers published';
    }
}

function updateSearchStatus(count, query) {
    searchStatus.innerHTML = '<strong>' + count + '</strong> result' + (count !== 1 ? 's' : '') + ' for "' + query + '" <span class="clear-search" onclick="clearFilters()">Clear search</span>';
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
                node.textContent = node.textContent.replace(/\\s*\\d+\\s*$/, '');
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
    renderAll();
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
            filterAndRender();
        });
    });
    
    document.querySelectorAll(".view-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            document.querySelectorAll(".view-btn").forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            currentView = btn.dataset.view;
            filterAndRender();
        });
    });
    
    // Search only on button click or Enter key
    searchBtn.addEventListener("click", doSearch);
    searchInput.addEventListener("keypress", (e) => {
        if (e.key === "Enter") doSearch();
    });
    
    sortSelect.addEventListener("change", filterAndRender);
    
    renderAll();
}

window.onload = init;
