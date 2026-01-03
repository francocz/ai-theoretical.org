Class {
	#name : 'ATAIEditorialPromptPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATAIEditorialPromptPage >> content [
	^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>AI Editorial Prompt</h1>
    <hr>
</header>

<div class="section">
    <p>
        Here you find the prompt used to ask the AI to assess papers before they are published on this site.
        The prompt specifies how the AI evaluates a text with respect to the platform''s editorial criteria.
    </p>
    <p>
        When a paper satisfies these criteria, the resulting AI-assisted editorial assessment is published alongside the text.
        Making both the prompt and the assessment public guarantees transparency and allows the evaluation process to be repeated,
        within the limits imposed by differences between AI models and versions.
    </p>
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
    const content = document.getElementById(''prompt-content'');
    const version = document.getElementById(''prompt-version'');

    if (typeof AI_EDITORIAL_PROMPT !== ''undefined'') {
        content.textContent = AI_EDITORIAL_PROMPT.trim();
    } else {
        content.textContent = ''Prompt not available.'';
    }

    if (typeof Version !== ''undefined'') {
        version.textContent = `Prompt version ${Version}`;
    } else {
        version.textContent = ''Prompt version unknown'';
    }
</script>'
]

{ #category : 'generating' }
ATAIEditorialPromptPage >> css [
	^ super css, String lf, '
.prompt-frame {
    border: 1px solid var(--border);
    padding: 30px;
    margin: 40px 0;
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
