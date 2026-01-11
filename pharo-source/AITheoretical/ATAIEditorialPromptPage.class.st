Class {
	#name : 'ATAIEditorialPromptPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATAIEditorialPromptPage class >> generatePromptsJs [
    "Genera il file ai-prompt.js con tutti i prompt per i diversi track"
    | stream prompts |
    stream := WriteStream on: String new.
    prompts := ATPromptRegistry current prompts.
    
    stream nextPutAll: '/**
 * AI Editorial Assessment Prompts
 * Platform: AI-Theoretical
 * 
 * This file contains the evaluation prompts used for each submission track.
 * The prompts are public by design, as part of the platform''s
 * commitment to transparency and methodological clarity.
 */

const AI_PROMPTS = {
'.
    
    prompts doWithIndex: [ :prompt :index |
        stream nextPutAll: '    '.
        stream nextPutAll: prompt track asString.
        stream nextPutAll: ': {
        version: "'.
        stream nextPutAll: prompt version asString.
        stream nextPutAll: '",
        content: `'.
        stream nextPutAll: (prompt content copyReplaceAll: '`' with: '\`').
        stream nextPutAll: '`
    }'.
        index < prompts size ifTrue: [ stream nextPutAll: ',' ].
        stream cr ].
    
    stream nextPutAll: '};
'.
    
    ^ stream contents
]

{ #category : 'generating' }
ATAIEditorialPromptPage >> content [
    ^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>AI Editorial Prompts</h1>
    <hr>
</header>

<div class="section">
    <p>
        Here you find the prompts used to ask the AI to assess papers before they are published on this site.
        Each submission track has its own prompt with specific evaluation criteria.
    </p>
    <p>
        When a paper satisfies these criteria, the resulting AI-assisted editorial assessment is published alongside the text.
        Making both the prompts and the assessments public guarantees transparency and allows the evaluation process to be repeated,
        within the limits imposed by differences between AI models and versions.
    </p>
</div>

<div class="track-selector">
    <button class="track-tab active" data-track="researchPreprint">Research Preprint</button>
    <button class="track-tab" data-track="workingPaper">Working Paper</button>
    <button class="track-tab" data-track="expositoryEssay">Expository Essay</button>
    <button class="track-tab" data-track="criticalReview">Critical Review</button>
</div>

<div class="prompt-frame">
    <div id="prompt-version" class="prompt-version">
        Loading version…
    </div>
    <div id="prompt-content" class="prompt-content">
        Loading prompt…
    </div>
</div>

', self footer, '

</div>

<script src="ai-prompt.js"></script>
<script>
    const content = document.getElementById("prompt-content");
    const version = document.getElementById("prompt-version");
    const tabs = document.querySelectorAll(".track-tab");
    
    function showPrompt(track) {
        if (typeof AI_PROMPTS !== "undefined" && AI_PROMPTS[track]) {
            content.textContent = AI_PROMPTS[track].content.trim();
            version.textContent = "Prompt version " + AI_PROMPTS[track].version;
        } else {
            content.textContent = "Prompt not available.";
            version.textContent = "";
        }
    }
    
    tabs.forEach(tab => {
        tab.addEventListener("click", () => {
            tabs.forEach(t => t.classList.remove("active"));
            tab.classList.add("active");
            showPrompt(tab.dataset.track);
        });
    });
    
    // Show first prompt on load
    showPrompt("researchPreprint");
</script>'
]

{ #category : 'generating' }
ATAIEditorialPromptPage >> css [
    ^ super css, String lf, '
.track-selector {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin: 30px 0 20px;
}

.track-tab {
    background: #f5f5f3;
    border: 1px solid var(--border);
    padding: 10px 18px;
    font-size: 0.85rem;
    font-family: inherit;
    cursor: pointer;
    transition: all 0.2s;
    color: var(--text-muted);
}

.track-tab:hover {
    background: #eee;
}

.track-tab.active {
    background: var(--text-main);
    color: white;
    border-color: var(--text-main);
}

.prompt-frame {
    border: 1px solid var(--border);
    padding: 30px;
    margin: 20px 0 40px;
    background: #fafafa;
}

.prompt-version {
    font-size: 0.75rem;
    color: var(--text-muted);
    margin-bottom: 15px;
}

.prompt-content {
    white-space: pre-wrap;
    font-size: 0.9rem;
}'
]

{ #category : 'accessing' }
ATAIEditorialPromptPage >> description [
	^ 'Transparency in evaluation: read the exact system prompt used for the AI-assisted editorial assessment of our papers.'
]

{ #category : 'accessing' }
ATAIEditorialPromptPage >> fileName [
	^ 'ai-editorial-prompt.html'
]

{ #category : 'accessing' }
ATAIEditorialPromptPage >> title [
	^ 'AI Editorial Prompt — AI-Theoretical'
]
