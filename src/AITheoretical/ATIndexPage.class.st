Class {
	#name : 'ATIndexPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATIndexPage >> content [
	^ self contentHtml, String lf, self javascript
]

{ #category : 'generating' }
ATIndexPage >> contentHtml [
    ^ '<div class="container">
    <header>
        <div class="top-subtitle">Human-AI Theoretical Laboratory</div>
        <h1>AI-Theoretical</h1>
        <hr>
    </header>

    <div class="manifesto-grid">
        <div class="manifesto-label">
            <a href="manifesto.html">Manifesto</a>
            <a href="editorial-principles.html">Editorial framework</a>
            <a href="ai-editorial-prompt.html">AI editorial prompt</a>
            <a href="invite.html">Invitation to participate</a>
            <a href="submit.html">Submit a paper</a>
        </div>
        <div>
            <div class="manifesto-quote">
                "This platform collects and publishes scholarly papers openly co-authored by humans and frontier AI models. We experiment with new forms of knowledge production to reflect on authorship and epistemology in the age of synthetic intelligence."
            </div>
        </div>
    </div>
    <hr>

    <div class="search-section">
        <div class="search-box">
            <input type="text" id="searchInput" class="search-input" placeholder="Search papers by title, author, abstract...">
        </div>
        
        <div class="track-filters">
            <button class="track-btn active" data-track="all">All</button>
            <button class="track-btn" data-track="researchPreprint">Research Preprints</button>
            <button class="track-btn" data-track="workingPaper">Working Papers</button>
            <button class="track-btn" data-track="expositoryEssay">Expository Essays</button>
            <button class="track-btn" data-track="criticalReview">Critical Reviews</button>
        </div>
        
        <div class="view-controls">
            <div class="view-toggle">
                <button class="view-btn active" data-view="full" title="Full view">☰</button>
                <button class="view-btn" data-view="compact" title="Compact view">▤</button>
            </div>
            <select id="sortSelect" class="sort-select">
                <option value="date-desc">Newest first</option>
                <option value="date-asc">Oldest first</option>
                <option value="title-asc">Title A-Z</option>
                <option value="title-desc">Title Z-A</option>
            </select>
        </div>
        
        <div id="searchStatus" class="search-results-count"></div>
    </div>

    <div id="repository"></div>
    
    ', self footer, '
</div>'
]

{ #category : 'generating' }
ATIndexPage >> css [
    ^ ATStyles baseCss, String lf, ATStyles indexCss, String lf, ATStyles trackFiltersCss
]

{ #category : 'accessing' }
ATIndexPage >> description [
	^ 'A platform for scholarly works openly co-authored by humans and frontier AI models. Explore theoretical papers in philosophy, science, and epistemology.'
]

{ #category : 'accessing' }
ATIndexPage >> fileName [
	^ 'index.html'
]

{ #category : 'html generation' }
ATIndexPage >> footer [
	^ '<footer>
    Interested in participating? Contact <a href="mailto:franco.cazzaniga@uninsubria.it">franco.cazzaniga@uninsubria.it</a>
    <div class="powered-by">
        Powered by <a href="https://www.anthropic.com/claude" target="_blank">Claude AI</a> and <a href="https://pharo.org" target="_blank">Pharo Smalltalk</a>
    </div>
</footer>'
]

{ #category : 'generating' }
ATIndexPage >> head [
    ^ String streamContents: [ :s |
        s << '<head>'; << String lf.
        s << '    <meta charset="UTF-8">'; << String lf.
        s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
        s << '    <link rel="icon" type="image/svg+xml" href="favicon.svg">'; << String lf.
        s << '    <title>'; << self title; << '</title>'; << String lf.
        s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
        s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
        s << '    <meta name="keywords" content="AI, theoretical papers, human-AI collaboration, epistemology, philosophy of AI, Franco Cazzaniga">'; << String lf.
        s << '    <meta property="og:title" content="AI-Theoretical | Human-AI Research">'; << String lf.
        s << '    <meta property="og:description" content="Publishing high-quality theoretical papers co-authored by humans and AI.">'; << String lf.
        s << '    <meta property="og:url" content="https://ai-theoretical.org">'; << String lf.
        s << '    <meta property="og:type" content="website">'; << String lf.
        s << self fonts.
        s << '    <style>'; << String lf.
        s << self css.
        s << '    </style>'; << String lf.
        s << '</head>'; << String lf ]
]

{ #category : 'generating' }
ATIndexPage >> javascript [
    ^ '<script src="papers.js"></script>
<script src="index-app.js"></script>'
]

{ #category : 'accessing' }
ATIndexPage >> title [
	^ 'AI-Theoretical | Human-AI Co-Authored Theoretical Papers'
]
