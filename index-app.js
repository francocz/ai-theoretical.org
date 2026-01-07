const repo = document.getElementById("repository");
const searchInput = document.getElementById("searchInput");
const searchStatus = document.getElementById("searchStatus");
const sortSelect = document.getElementById("sortSelect");

let currentTrack = "all";
let currentView = "full";

const TRACK_INFO = {
    researchPreprint: { label: "Research Preprint", icon: "📚" },
    workingPaper: { label: "Working Paper", icon: "📝" },
    expositoryEssay: { label: "Expository Essay", icon: "📖" },
    criticalReview: { label: "Critical Review", icon: "🔍" }
};

// Algolia configuration
const ALGOLIA_APP_ID = 'KXM87UO2YZ';
const ALGOLIA_SEARCH_KEY = '9007e1d3d632c25e106acd34be41425c';
const ALGOLIA_INDEX = 'papers';

const searchClient = algoliasearch(ALGOLIA_APP_ID, ALGOLIA_SEARCH_KEY);
const index = searchClient.initIndex(ALGOLIA_INDEX);

// Also keep local papers.js for fallback and initial load
let localPapers = typeof papers !== 'undefined' ? papers : [];

function highlightText(text, query) {
    if (!query || !text) return text;
    const words = query.toLowerCase().split(/\\s+/).filter(w => w.length > 2);
    if (words.length === 0) return text;
    const regex = new RegExp("(" + words.join("|") + ")", "gi");
    return text.replace(regex, '<span class="highlight">$1</span>');
}

function renderPaper(paper, query = "") {
    const trackInfo = TRACK_INFO[paper.track] || { label: paper.track || "Paper", icon: "📄" };
    const title = highlightText(paper.title, query);
    const authors = highlightText(paper.authors?.join?.(", ") || paper.author || "", query);
    
    if (currentView === "compact") {
        return `
            <article class="paper-item compact">
                <a href="papers/${paper.slug}.html" class="paper-link">
                    <span class="track-icon">${trackInfo.icon}</span>
                    <span class="paper-title">${title}</span>
                    <span class="paper-authors">${authors}</span>
                </a>
            </article>`;
    }
    
    const abstractText = paper.abstract || "";
    const abstract = highlightText(
        abstractText.length > 250 ? abstractText.substring(0, 250) + "..." : abstractText,
        query
    );
    
    return `
        <article class="paper-item">
            <span class="paper-track">${trackInfo.icon} ${trackInfo.label}</span>
            <h2 class="paper-title"><a href="papers/${paper.slug}.html">${title}</a></h2>
            <p class="paper-authors">${authors}</p>
            <p class="paper-abstract">${abstract}</p>
            <div class="paper-actions">
                <a href="papers/${paper.slug}.pdf" class="btn btn-black">Download PDF</a>
                <a href="papers/${paper.slug}.html" class="btn btn-outline">View Details</a>
            </div>
        </article>`;
}

async function searchAndRender() {
    const query = searchInput.value.trim();
    
    let filters = "";
    if (currentTrack !== "all") {
        filters = `track:${currentTrack}`;
    }
    
    try {
        if (query.length > 0) {
            const results = await index.search(query, {
                filters: filters,
                hitsPerPage: 50
            });
            renderResults(results.hits, query, results.nbHits);
        } else {
            let filtered = localPapers.filter(p => p.status === "active");
            if (currentTrack !== "all") {
                filtered = filtered.filter(p => p.track === currentTrack);
            }
            filtered = sortPapers(filtered);
            renderResults(filtered, "", filtered.length);
        }
    } catch (error) {
        console.error("Algolia search error:", error);
        fallbackSearch(query);
    }
}

function fallbackSearch(query) {
    let filtered = localPapers.filter(p => {
        if (p.status !== "active") return false;
        if (currentTrack !== "all" && p.track !== currentTrack) return false;
        if (query) {
            const searchable = (p.title + " " + p.author + " " + (p.abstract || "")).toLowerCase();
            return query.toLowerCase().split(/\\s+/).every(w => searchable.includes(w));
        }
        return true;
    });
    filtered = sortPapers(filtered);
    renderResults(filtered, query, filtered.length);
}

function sortPapers(papers) {
    const sort = sortSelect.value;
    return [...papers].sort((a, b) => {
        if (sort === "date-desc") return (b.date || "").localeCompare(a.date || "");
        if (sort === "date-asc") return (a.date || "").localeCompare(b.date || "");
        if (sort === "title-asc") return (a.title || "").localeCompare(b.title || "");
        if (sort === "title-desc") return (b.title || "").localeCompare(a.title || "");
        return 0;
    });
}

function renderResults(papers, query, total) {
    if (papers.length === 0) {
        repo.innerHTML = '<p class="no-results">No papers found matching your criteria.</p>';
        searchStatus.textContent = "No results";
        return;
    }
    
    if (query.length === 0) {
        papers = sortPapers(papers);
    }
    
    repo.innerHTML = papers.map(p => renderPaper(p, query)).join("");
    
    const statusText = query 
        ? `${total} result${total !== 1 ? 's' : ''} for "${query}"`
        : `${total} paper${total !== 1 ? 's' : ''}`;
    searchStatus.textContent = statusText;
}

let searchTimeout;
searchInput.addEventListener("input", () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(searchAndRender, 200);
});

sortSelect.addEventListener("change", searchAndRender);

document.querySelectorAll(".track-btn").forEach(btn => {
    btn.addEventListener("click", () => {
        document.querySelectorAll(".track-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        currentTrack = btn.dataset.track;
        searchAndRender();
    });
});

document.querySelectorAll(".view-btn").forEach(btn => {
    btn.addEventListener("click", () => {
        document.querySelectorAll(".view-btn").forEach(b => b.classList.remove("active"));
        btn.classList.add("active");
        currentView = btn.dataset.view;
        searchAndRender();
    });
});

searchAndRender();
