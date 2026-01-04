Class {
	#name : 'ATPageGenerator',
	#superclass : 'Object',
	#instVars : [
		'outputPath'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'html' }
ATPageGenerator >> commonCSS [
    ^ ':root { --accent-blue: #2563eb; --text-main: #1a1a1a; --text-muted: #666; --border: #e5e5e0; --bg-light: #f9f9f9; --bg-inactive: #f0f0eb; }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: Inter, sans-serif; background: #fff; color: var(--text-main); line-height: 1.7; padding: 40px; }
.container { max-width: 900px; margin: 0 auto; }
nav { margin-bottom: 40px; }
nav a { color: var(--accent-blue); text-decoration: none; font-size: 0.9rem; }
h1 { font-family: Playfair Display, serif; font-size: 2.2rem; margin-bottom: 20px; }
h2 { font-size: 1.4rem; margin: 30px 0 15px 0; border-bottom: 1px solid var(--border); padding-bottom: 10px; }
h3 { font-size: 1.1rem; margin: 20px 0 10px 0; color: var(--text-main); }
p { margin-bottom: 15px; }
.intro { font-size: 1.1rem; color: var(--text-muted); margin-bottom: 30px; }
.track-card { background: var(--bg-light); padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid var(--accent-blue); }
.track-card h3 { margin-top: 0; }
.track-card p { margin-bottom: 10px; font-size: 0.95rem; }
select { padding: 8px 12px; font-size: 1rem; border: 1px solid var(--border); border-radius: 4px; margin-right: 10px; }
.prompt-display { background: var(--bg-light); padding: 20px; border-radius: 8px; margin-top: 20px; white-space: pre-wrap; font-family: monospace; font-size: 0.85rem; max-height: 500px; overflow-y: auto; }
.prompt-inactive { background: var(--bg-inactive); opacity: 0.8; }
.version-info { font-size: 0.85rem; color: var(--text-muted); margin: 10px 0; }
.changelog { font-style: italic; color: var(--text-muted); }
footer { margin-top: 60px; padding-top: 30px; border-top: 1px solid var(--border); text-align: center; font-size: 0.85rem; color: var(--text-muted); }
footer a { color: var(--text-main); }'
]

{ #category : 'private' }
ATPageGenerator >> escapeForJS: aString [
    | result backslash |
    aString ifNil: [ ^ '' ].
    backslash := String with: $\.
    result := aString copyReplaceAll: backslash with: backslash, backslash.
    result := result copyReplaceAll: '"' with: backslash, '"'.
    result := result copyReplaceAll: String lf with: backslash, 'n'.
    result := result copyReplaceAll: String cr with: backslash, 'n'.
    ^ result
]

{ #category : 'generating' }
ATPageGenerator >> generateAll [
    | results |
    results := OrderedCollection new.
    results add: ('Editorial Framework: ', self generateEditorialFramework).
    results add: ('Prompts Page: ', self generatePromptsPage).
    results add: ('Submit Page: ', self generateSubmitPage).
    ^ results
]

{ #category : 'generating' }
ATPageGenerator >> generateEditorialFramework [
    | html file |
    html := String streamContents: [ :s |
        s nextPutAll: (self htmlHeadWithTitle: 'Editorial Framework').
        s nextPutAll: '<body>'; lf.
        s nextPutAll: '<div class="container">'; lf.
        s nextPutAll: '<nav><a href="/">← Back to AI-Theoretical</a></nav>'; lf.
        
        s nextPutAll: '<h1>Editorial Framework</h1>'; lf.
        s nextPutAll: '<p class="intro">AI-Theoretical accepts submissions in four distinct tracks, each with specific evaluation criteria and standards.</p>'; lf.
        
        "Research Preprint"
        s nextPutAll: '<div class="track-card">'; lf.
        s nextPutAll: '<h3>Research Preprint</h3>'; lf.
        s nextPutAll: '<p>Original research contributions presenting new theoretical results, methods, or frameworks. Expected to meet higher standards of completeness, argumentation, and scholarly apparatus.</p>'; lf.
        s nextPutAll: '<p><strong>Key criteria:</strong> Novelty, correctness, contribution, bibliography adequacy. Original work with substantive contribution receives an acceptance bonus.</p>'; lf.
        s nextPutAll: '</div>'; lf.
        
        "Working Paper"
        s nextPutAll: '<div class="track-card">'; lf.
        s nextPutAll: '<h3>Working Paper</h3>'; lf.
        s nextPutAll: '<p>Original ideas that may still be developing. Originality and intellectual contribution are weighted more heavily than completeness of bibliography or polish of presentation.</p>'; lf.
        s nextPutAll: '<p><strong>Key criteria:</strong> Originality strongly weighted. Minor issues in bibliography, structure, or effectiveness should not block acceptance of genuinely original work.</p>'; lf.
        s nextPutAll: '</div>'; lf.
        
        "Expository Essay"
        s nextPutAll: '<div class="track-card">'; lf.
        s nextPutAll: '<h3>Expository/Theoretical Essay</h3>'; lf.
        s nextPutAll: '<p>Essays that clarify, synthesize, or pedagogically present existing theoretical material. Judged on clarity of exposition, accuracy of representation, and pedagogical effectiveness.</p>'; lf.
        s nextPutAll: '<p><strong>Key criteria:</strong> Pedagogical value, accuracy of representation, coverage relative to stated scope. Lower semantic opacity is strongly preferred.</p>'; lf.
        s nextPutAll: '</div>'; lf.
        
        "Critical Review"
        s nextPutAll: '<div class="track-card">'; lf.
        s nextPutAll: '<h3>Critical Review</h3>'; lf.
        s nextPutAll: '<p>Analytical engagement with existing work, arguments, or theoretical positions. Judged on quality of critical analysis, fairness to positions examined, and argumentative rigor.</p>'; lf.
        s nextPutAll: '<p><strong>Key criteria:</strong> Fairness (charitable interpretation), critical depth (engages fundamental assumptions), argumentative rigor. Unfairness or ad hominem is grounds for rejection.</p>'; lf.
        s nextPutAll: '</div>'; lf.
        
        s nextPutAll: '<h2>Common Standards</h2>'; lf.
        s nextPutAll: '<p>All tracks share these rejection criteria:</p>'; lf.
        s nextPutAll: '<ul style="margin-left: 20px; margin-bottom: 20px;">'; lf.
        s nextPutAll: '<li>Category mismatch (submission does not fit any track)</li>'; lf.
        s nextPutAll: '<li>Systematic or undermining errors in correctness</li>'; lf.
        s nextPutAll: '<li>Major coherence issues</li>'; lf.
        s nextPutAll: '<li>High semantic opacity (obfuscatory writing)</li>'; lf.
        s nextPutAll: '<li>Suspected plagiarism or harmful content</li>'; lf.
        s nextPutAll: '<li>Inadequate structure</li>'; lf.
        s nextPutAll: '</ul>'; lf.
        
        s nextPutAll: '<h2>AI Assessment</h2>'; lf.
        s nextPutAll: '<p>All submissions are assessed by Claude AI using track-specific prompts. The prompts are versioned and publicly available on the <a href="ai-editorial-prompts.html">AI Editorial Prompts</a> page.</p>'; lf.
        s nextPutAll: '<p>Each published paper includes the prompt version used for its assessment, ensuring full transparency and reproducibility.</p>'; lf.
        
        s nextPutAll: self htmlFooter ].
    
    file := (self outputPath asFileReference / 'editorial-framework.html').
    file writeStreamDo: [ :stream | stream nextPutAll: html ].
    ^ file fullName
]

{ #category : 'generating' }
ATPageGenerator >> generatePromptsPage [
    | html file registry |
    registry := ATPromptRegistry current.
    
    html := String streamContents: [ :s |
        s nextPutAll: (self htmlHeadWithTitle: 'AI Editorial Prompts').
        s nextPutAll: '<body>'; lf.
        s nextPutAll: '<div class="container">'; lf.
        s nextPutAll: '<nav><a href="/">← Back to AI-Theoretical</a></nav>'; lf.
        
        s nextPutAll: '<h1>AI Editorial Prompts</h1>'; lf.
        s nextPutAll: '<p class="intro">These are the exact prompts used by Claude AI to assess submissions. Select a track and version to view the prompt.</p>'; lf.
        
        "Selectors"
        s nextPutAll: '<div style="margin: 30px 0;">'; lf.
        s nextPutAll: '<label for="trackSelect"><strong>Track:</strong></label> '; lf.
        s nextPutAll: '<select id="trackSelect" onchange="updateVersions()">'; lf.
        registry allTracks do: [ :track |
            s nextPutAll: '<option value="'; nextPutAll: track asString; nextPutAll: '">'.
            s nextPutAll: (registry trackDisplayName: track).
            s nextPutAll: '</option>'; lf ].
        s nextPutAll: '</select>'; lf.
        
        s nextPutAll: '<label for="versionSelect" style="margin-left: 20px;"><strong>Version:</strong></label> '; lf.
        s nextPutAll: '<select id="versionSelect" onchange="showPrompt()">'; lf.
        s nextPutAll: '</select>'; lf.
        s nextPutAll: '</div>'; lf.
        
        "Version info"
        s nextPutAll: '<div id="versionInfo" class="version-info"></div>'; lf.
        
        "Prompt display"
        s nextPutAll: '<div id="promptDisplay" class="prompt-display"></div>'; lf.
        
        "JavaScript con dati dei prompt"
        s nextPutAll: '<script>'; lf.
        s nextPutAll: 'const prompts = '.
        self writePromptsJSONTo: s.
        s nextPutAll: ';'; lf; lf.
        
        s nextPutAll: self promptsPageJavaScript.
        s nextPutAll: '</script>'; lf.
        
        s nextPutAll: self htmlFooter ].
    
    file := (self outputPath asFileReference / 'ai-editorial-prompts.html').
    file writeStreamDo: [ :stream | stream nextPutAll: html ].
    ^ file fullName
]

{ #category : 'generating' }
ATPageGenerator >> generateSubmitPage [
    | file |
    file := (self outputPath asFileReference / 'submit.html').
    file writeStreamDo: [ :s | self writeSubmitPageTo: s ].
    ^ file fullName
]

{ #category : 'html' }
ATPageGenerator >> htmlFooter [
    ^ '<footer>
<p>Powered by <a href="https://www.anthropic.com/claude" target="_blank">Claude AI</a> and <a href="https://pharo.org" target="_blank">Pharo Smalltalk</a></p>
</footer>
</div>
</body>
</html>'
]

{ #category : 'html' }
ATPageGenerator >> htmlHeadWithTitle: aTitle [
    ^ String streamContents: [ :s |
        s nextPutAll: '<!DOCTYPE html>'; lf.
        s nextPutAll: '<html lang="en">'; lf.
        s nextPutAll: '<head>'; lf.
        s nextPutAll: '<meta charset="UTF-8">'; lf.
        s nextPutAll: '<meta name="viewport" content="width=device-width, initial-scale=1.0">'; lf.
        s nextPutAll: '<title>'; nextPutAll: aTitle; nextPutAll: ' - AI-Theoretical</title>'; lf.
        s nextPutAll: '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">'; lf.
        s nextPutAll: '<style>'; nextPutAll: self commonCSS; nextPutAll: '</style>'; lf.
        s nextPutAll: '</head>'; lf ]
]

{ #category : 'accessing' }
ATPageGenerator >> outputPath [ ^ outputPath ifNil: [ '/Users/Franco/Dropbox/ai-theoretical.org/site' ]
]

{ #category : 'accessing' }
ATPageGenerator >> outputPath: aPath [ outputPath := aPath
]

{ #category : 'html' }
ATPageGenerator >> promptsPageJavaScript [
    ^ '
function updateVersions() {
    const track = document.getElementById("trackSelect").value;
    const versionSelect = document.getElementById("versionSelect");
    const trackPrompts = prompts[track] || [];
    
    versionSelect.innerHTML = "";
    trackPrompts.forEach((p, idx) => {
        const opt = document.createElement("option");
        opt.value = idx;
        opt.textContent = "v" + p.version + (p.isActive ? " (current)" : " (archived)");
        versionSelect.appendChild(opt);
    });
    
    showPrompt();
}

function showPrompt() {
    const track = document.getElementById("trackSelect").value;
    const versionIdx = document.getElementById("versionSelect").value;
    const trackPrompts = prompts[track] || [];
    
    if (trackPrompts.length === 0) {
        document.getElementById("promptDisplay").textContent = "No prompts available.";
        document.getElementById("versionInfo").innerHTML = "";
        return;
    }
    
    const prompt = trackPrompts[versionIdx];
    const display = document.getElementById("promptDisplay");
    const info = document.getElementById("versionInfo");
    
    display.textContent = prompt.content;
    display.className = "prompt-display" + (prompt.isActive ? "" : " prompt-inactive");
    
    info.innerHTML = "<strong>Created:</strong> " + prompt.createdAt + 
                     "<br><span class=changelog><strong>Changelog:</strong> " + prompt.changelog + "</span>";
}

// Initialize on load
document.addEventListener("DOMContentLoaded", function() {
    updateVersions();
});
'
]

{ #category : 'html' }
ATPageGenerator >> writePromptsJSONTo: aStream [
    | registry backslash |
    registry := ATPromptRegistry current.
    backslash := String with: $\.
    aStream nextPutAll: '{'; lf.
    
    registry allTracks doWithIndex: [ :track :idx |
        | prompts |
        prompts := registry promptsForTrack: track.
        aStream nextPutAll: '  "'; nextPutAll: track asString; nextPutAll: '": ['; lf.
        
        prompts doWithIndex: [ :prompt :pidx |
            aStream nextPutAll: '    {'; lf.
            aStream nextPutAll: '      "version": "'; nextPutAll: prompt version; nextPutAll: '",'; lf.
            aStream nextPutAll: '      "isActive": '; nextPutAll: prompt isActive asString; nextPutAll: ','; lf.
            aStream nextPutAll: '      "createdAt": "'; nextPutAll: prompt createdAt asString; nextPutAll: '",'; lf.
            aStream nextPutAll: '      "changelog": "'; nextPutAll: (self escapeForJS: prompt changelog); nextPutAll: '",'; lf.
            aStream nextPutAll: '      "content": "'; nextPutAll: (self escapeForJS: prompt content); nextPutAll: '"'; lf.
            aStream nextPutAll: '    }'.
            pidx < prompts size ifTrue: [ aStream nextPut: $, ].
            aStream lf ].
        
        aStream nextPutAll: '  ]'.
        idx < registry allTracks size ifTrue: [ aStream nextPut: $, ].
        aStream lf ].
    
    aStream nextPutAll: '}'
]

{ #category : 'private' }
ATPageGenerator >> writeSubmitPageFormTo: s [
    s nextPutAll: '<div id="messageBox" class="message hidden"></div>'; lf.
    s nextPutAll: '<form id="submitForm" enctype="multipart/form-data">'; lf.
    "Track"
    s nextPutAll: '<div class="form-group required"><label for="track">Submission Track</label>'; lf.
    s nextPutAll: '<select name="track" id="track" required>'; lf.
    s nextPutAll: '<option value="">-- Select a track --</option>'; lf.
    s nextPutAll: '<option value="researchPreprint">Research Preprint</option>'; lf.
    s nextPutAll: '<option value="workingPaper">Working Paper</option>'; lf.
    s nextPutAll: '<option value="expositoryEssay">Expository/Theoretical Essay</option>'; lf.
    s nextPutAll: '<option value="criticalReview">Critical Review</option>'; lf.
    s nextPutAll: '</select><div id="trackInfo" class="track-info"></div></div>'; lf.
    "Author"
    s nextPutAll: '<div class="form-group required"><label for="authorName">Author Name</label><input type="text" name="authorName" id="authorName" required></div>'; lf.
    s nextPutAll: '<div class="form-group required"><label for="authorEmail">Email Address</label><input type="email" name="authorEmail" id="authorEmail" required><small>You will receive a confirmation email.</small></div>'; lf.
    s nextPutAll: '<div class="form-group"><label for="authorAffiliation">Affiliation (optional)</label><input type="text" name="authorAffiliation" id="authorAffiliation"></div>'; lf.
    "Paper"
    s nextPutAll: '<div class="form-group required"><label for="title">Paper Title</label><input type="text" name="title" id="title" required></div>'; lf.
    s nextPutAll: '<div class="form-group required"><label for="abstract">Abstract</label><textarea name="abstract" id="abstract" required></textarea></div>'; lf.
    s nextPutAll: '<div class="form-group required"><label for="aiModels">AI Models Used</label><input type="text" name="aiModels" id="aiModels" required placeholder="e.g., Claude 3.5 Sonnet, GPT-4"><small>List the AI models that contributed.</small></div>'; lf.
    "Files"
    s nextPutAll: '<div class="form-group"><label for="pdf">PDF File</label><input type="file" name="pdf" id="pdf" accept=".pdf"><small>Maximum 50MB.</small></div>'; lf.
    s nextPutAll: '<div class="form-group"><label for="code">Code Archive (optional)</label><input type="file" name="code" id="code" accept=".zip"><small>Maximum 20MB. ZIP format.</small></div>'; lf.
    s nextPutAll: '<div class="form-group"><label for="notes">Additional Notes (optional)</label><textarea name="notes" id="notes"></textarea></div>'; lf.
    "Terms"
    s nextPutAll: '<div class="form-group required"><div class="checkbox-group"><input type="checkbox" name="acceptTerms" id="acceptTerms" value="true" required>'; lf.
    s nextPutAll: '<label for="acceptTerms">I confirm this work is original and accept the <a href="/editorial-framework.html">editorial framework</a>.</label></div></div>'; lf.
    s nextPutAll: '<button type="submit" class="btn-submit" id="submitBtn">Submit Paper</button>'; lf.
    s nextPutAll: '</form>'; lf.
    s nextPutAll: '<footer><p>Powered by <a href="https://www.anthropic.com/claude">Claude AI</a> and <a href="https://pharo.org">Pharo Smalltalk</a></p></footer>'; lf.
    s nextPutAll: '</div>'; lf
]

{ #category : 'private' }
ATPageGenerator >> writeSubmitPageHeadTo: s [
    s nextPutAll: '<!DOCTYPE html>'; lf.
    s nextPutAll: '<html lang="en">'; lf.
    s nextPutAll: '<head>'; lf.
    s nextPutAll: '<meta charset="UTF-8">'; lf.
    s nextPutAll: '<meta name="viewport" content="width=device-width, initial-scale=1.0">'; lf.
    s nextPutAll: '<title>Submit Your Paper - AI-Theoretical</title>'; lf.
    s nextPutAll: '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">'; lf.
    s nextPutAll: '<style>'; lf.
    s nextPutAll: ':root { --accent-blue: #2563eb; --text-main: #1a1a1a; --text-muted: #666; --border: #e5e5e0; --bg-light: #f9f9f9; }'; lf.
    s nextPutAll: '* { margin: 0; padding: 0; box-sizing: border-box; }'; lf.
    s nextPutAll: 'body { font-family: Inter, sans-serif; background: #fff; color: var(--text-main); line-height: 1.7; padding: 40px 20px; }'; lf.
    s nextPutAll: '.container { max-width: 700px; margin: 0 auto; }'; lf.
    s nextPutAll: 'nav { margin-bottom: 40px; } nav a { color: var(--accent-blue); text-decoration: none; }'; lf.
    s nextPutAll: 'h1 { font-family: Playfair Display, serif; font-size: 2.2rem; margin-bottom: 10px; }'; lf.
    s nextPutAll: '.intro { color: var(--text-muted); margin-bottom: 30px; }'; lf.
    s nextPutAll: '.form-group { margin-bottom: 24px; }'; lf.
    s nextPutAll: '.form-group label { display: block; font-weight: 500; margin-bottom: 8px; }'; lf.
    s nextPutAll: '.form-group.required label::after { content: " *"; color: #e53e3e; }'; lf.
    s nextPutAll: '.form-group input, .form-group select, .form-group textarea { width: 100%; padding: 12px 16px; font-size: 1rem; border: 1px solid var(--border); border-radius: 6px; font-family: inherit; }'; lf.
    s nextPutAll: '.form-group input:focus, .form-group select:focus, .form-group textarea:focus { outline: none; border-color: var(--accent-blue); box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }'; lf.
    s nextPutAll: '.form-group textarea { min-height: 120px; resize: vertical; }'; lf.
    s nextPutAll: '.form-group small { display: block; margin-top: 6px; color: var(--text-muted); font-size: 0.85rem; }'; lf.
    s nextPutAll: '.track-info { background: var(--bg-light); padding: 16px; border-radius: 8px; margin-top: 12px; font-size: 0.9rem; display: none; }'; lf.
    s nextPutAll: '.track-info.visible { display: block; } .track-info h4 { margin: 0 0 8px 0; font-size: 0.95rem; color: var(--accent-blue); } .track-info p { margin: 0; color: var(--text-muted); }'; lf.
    s nextPutAll: '.checkbox-group { display: flex; align-items: flex-start; gap: 10px; } .checkbox-group input { width: auto; margin-top: 4px; } .checkbox-group label { font-weight: 400; }'; lf.
    s nextPutAll: '.btn-submit { display: inline-block; background: var(--accent-blue); color: white; padding: 14px 32px; border: none; border-radius: 6px; font-size: 1rem; font-weight: 500; cursor: pointer; }'; lf.
    s nextPutAll: '.btn-submit:hover { background: #1d4ed8; } .btn-submit:disabled { background: #9ca3af; cursor: not-allowed; }'; lf.
    s nextPutAll: '.message { padding: 20px; border-radius: 8px; margin-bottom: 24px; }'; lf.
    s nextPutAll: '.message.success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }'; lf.
    s nextPutAll: '.message.error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }'; lf.
    s nextPutAll: '.hidden { display: none; }'; lf.
    s nextPutAll: 'footer { margin-top: 60px; padding-top: 30px; border-top: 1px solid var(--border); text-align: center; font-size: 0.85rem; color: var(--text-muted); }'; lf.
    s nextPutAll: '</style>'; lf.
    s nextPutAll: '</head>'; lf.
    s nextPutAll: '<body>'; lf.
    s nextPutAll: '<div class="container">'; lf.
    s nextPutAll: '<nav><a href="/">← Back to AI-Theoretical</a></nav>'; lf.
    s nextPutAll: '<h1>Submit Your Paper</h1>'; lf.
    s nextPutAll: '<p class="intro">Submit your AI-assisted theoretical work for review. All submissions are assessed by Claude AI using track-specific evaluation criteria.</p>'; lf
]

{ #category : 'private' }
ATPageGenerator >> writeSubmitPageScriptTo: s [
    s nextPutAll: '<script>'; lf.
    s nextPutAll: 'const trackDescriptions = {'; lf.
    s nextPutAll: '  researchPreprint: { title: "Research Preprint", desc: "Original research with higher standards. Originality bonus for substantive contributions." },'; lf.
    s nextPutAll: '  workingPaper: { title: "Working Paper", desc: "Developing ideas where originality outweighs polish. Minor issues should not block original work." },'; lf.
    s nextPutAll: '  expositoryEssay: { title: "Expository Essay", desc: "Clarify or synthesize existing material. Judged on pedagogical value and accuracy." },'; lf.
    s nextPutAll: '  criticalReview: { title: "Critical Review", desc: "Analytical engagement with existing work. Judged on fairness and argumentative rigor." }'; lf.
    s nextPutAll: '};'; lf.
    s nextPutAll: 'document.getElementById("track").addEventListener("change", function() {'; lf.
    s nextPutAll: '  const info = document.getElementById("trackInfo"), track = this.value;'; lf.
    s nextPutAll: '  if (track && trackDescriptions[track]) {'; lf.
    s nextPutAll: '    info.innerHTML = "<h4>" + trackDescriptions[track].title + "</h4><p>" + trackDescriptions[track].desc + "</p>";'; lf.
    s nextPutAll: '    info.classList.add("visible");'; lf.
    s nextPutAll: '  } else { info.classList.remove("visible"); }'; lf.
    s nextPutAll: '});'; lf.
    s nextPutAll: 'document.getElementById("submitForm").addEventListener("submit", async function(e) {'; lf.
    s nextPutAll: '  e.preventDefault();'; lf.
    s nextPutAll: '  const btn = document.getElementById("submitBtn"), msgBox = document.getElementById("messageBox");'; lf.
    s nextPutAll: '  btn.disabled = true; btn.textContent = "Submitting..."; msgBox.className = "message hidden";'; lf.
    s nextPutAll: '  try {'; lf.
    s nextPutAll: '    const response = await fetch("/api/submit", { method: "POST", body: new FormData(this) });'; lf.
    s nextPutAll: '    const result = await response.json();'; lf.
    s nextPutAll: '    if (response.ok && result.success) {'; lf.
    s nextPutAll: '      msgBox.className = "message success";'; lf.
    s nextPutAll: '      msgBox.innerHTML = "<strong>Submission received!</strong><br>Please check your email to confirm. Link expires in 24 hours.";'; lf.
    s nextPutAll: '      this.reset(); document.getElementById("trackInfo").classList.remove("visible");'; lf.
    s nextPutAll: '    } else { msgBox.className = "message error"; msgBox.textContent = result.error || "Submission failed."; }'; lf.
    s nextPutAll: '  } catch (err) { msgBox.className = "message error"; msgBox.textContent = "Network error. Please try again."; }'; lf.
    s nextPutAll: '  btn.disabled = false; btn.textContent = "Submit Paper"; window.scrollTo(0, 0);'; lf.
    s nextPutAll: '});'; lf.
    s nextPutAll: '</script></body></html>'; lf
]

{ #category : 'private' }
ATPageGenerator >> writeSubmitPageTo: s [
    "Scrive submit.html completo"
    self writeSubmitPageHeadTo: s.
    self writeSubmitPageFormTo: s.
    self writeSubmitPageScriptTo: s
]
