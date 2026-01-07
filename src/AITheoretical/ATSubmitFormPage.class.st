Class {
	#name : 'ATSubmitFormPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATSubmitFormPage >> content [
	^ self contentHtml, String lf, self javascript
]

{ #category : 'generating' }
ATSubmitFormPage >> contentHtml [
    ^ '<div class="container">

<header>
    <a href="submit.html" class="nav">← Back</a>
    <h1>Submit a Paper</h1>
    <hr>
</header>

<div class="section">
    <p>Propose your work for publication on AI-Theoretical.</p>
</div>

<div id="successMessage" class="message success hidden">
    <strong>Submission received.</strong> Thank you for your submission. We will review it and contact you at the provided email address.
</div>

<div id="errorMessage" class="message error hidden"></div>

<form id="submissionForm">
    <div class="form-group">
        <label for="track" class="required">Submission Track</label>
        <select id="track" name="track" required>
            <option value="">-- Select a track --</option>
            <option value="researchPreprint">Research Preprint</option>
            <option value="workingPaper">Working Paper</option>
            <option value="expositoryEssay">Expository/Theoretical Essay</option>
            <option value="criticalReview">Critical Review</option>
        </select>
        <p class="help-text">See our <a href="editorial-principles.html">Editorial Framework</a> for track descriptions.</p>
    </div>

    <div class="form-section-title">Author Information</div>
    
    <div class="form-group">
        <label for="authorName" class="required">Corresponding Author</label>
        <input type="text" id="authorName" name="authorName" required placeholder="Full name">
        <p class="help-text">The corresponding author will receive all communications about this submission.</p>
    </div>
    
    <div class="form-group">
        <label for="authorEmail" class="required">Email</label>
        <input type="email" id="authorEmail" name="authorEmail" required>
        <p class="help-text">We will use this address to communicate about your submission.</p>
    </div>
    
    <div class="form-group">
        <label for="authorAffiliation">Affiliation</label>
        <input type="text" id="authorAffiliation" name="authorAffiliation" placeholder="University, Institute, or Independent">
        <p class="help-text">Optional. Will be displayed alongside your name if provided.</p>
    </div>
    
    <div class="form-group">
        <label for="coAuthors">Co-authors</label>
        <input type="text" id="coAuthors" name="coAuthors" placeholder="e.g., Maria Rossi (MIT), John Smith (Stanford)">
        <p class="help-text">Optional. List additional authors with their affiliations.</p>
    </div>
    
    <div class="form-section-title">Paper Information</div>
    
    <div class="form-group">
        <label for="title" class="required">Title</label>
        <input type="text" id="title" name="title" required>
    </div>
    
    <div class="form-group">
        <label for="abstract" class="required">Abstract</label>
        <textarea id="abstract" name="abstract" required placeholder="Provide a concise summary of your paper (recommended: 150-300 words)"></textarea>
    </div>
    
    <div class="form-group">
        <label for="aiModels" class="required">AI Models Used</label>
        <input type="text" id="aiModels" name="aiModels" required placeholder="e.g., Claude Opus 4.5, GPT-5">
        <p class="help-text">List the AI systems that contributed to the development of this paper.</p>
    </div>
    
    <div class="form-group">
        <label for="notes">Notes on AI Collaboration</label>
        <textarea id="notes" name="notes" placeholder="Describe how AI was used in the development of this paper (optional but encouraged)"></textarea>
        <p class="help-text">This will be displayed alongside the paper if accepted.</p>
    </div>
    
    <div class="form-group">
        <label for="pdf" class="required">PDF File</label>
        <input type="file" id="pdf" name="pdf" accept=".pdf" required>
        <p class="help-text">Maximum file size: 50 MB. The paper should be in its final or near-final form.</p>
    </div>
    
    <div class="form-group">
        <label for="code">Code Archive (optional)</label>
        <input type="file" id="code" name="code" accept=".zip">
        <p class="help-text">If your paper includes code, upload it as a ZIP file. Maximum size: 20 MB.</p>
    </div>
    
    <div class="disclaimer-box">
        <h2>Terms and Conditions</h2>
        <p>By submitting this paper, you confirm that:</p>
        <ul>
            <li><strong>Intellectual Property:</strong> You are the author of this work and hold the rights to submit it for publication.</li>
            <li><strong>Originality:</strong> This work is original and has not been published elsewhere in substantially the same form.</li>
            <li><strong>No Plagiarism:</strong> The submission does not contain plagiarized content.</li>
            <li><strong>AI Disclosure:</strong> You have accurately disclosed the AI systems used in developing this paper.</li>
            <li><strong>License:</strong> If accepted, the paper will be published under a <a href="https://creativecommons.org/licenses/by/4.0/" target="_blank">CC BY 4.0 License</a>.</li>
            <li><strong>AI Assessment:</strong> You consent to AI-assisted assessment as described in our <a href="editorial-principles.html">Editorial Framework</a>.</li>
        </ul>
        
        <div class="checkbox-group">
            <input type="checkbox" id="acceptTerms" name="acceptTerms" required>
            <label for="acceptTerms">I have read and accept these terms and conditions</label>
        </div>
    </div>
    
    <button type="submit" id="submitBtn">Submit Paper</button>
</form>

', self footer, '

</div>'
]

{ #category : 'generating' }
ATSubmitFormPage >> css [
	^ super css, String lf, '
/* FORM STYLES */
form {
    max-width: 720px;
    margin-top: 2rem;
}

.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    font-weight: 600;
    margin-bottom: 0.5rem;
    font-size: 0.9rem;
}

.required::after {
    content: " *";
    color: #c00;
}

input[type="text"],
input[type="email"],
textarea,
select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid var(--border);
    border-radius: 4px;
    font-family: inherit;
    font-size: 0.95rem;
}

input[type="text"]:focus,
input[type="email"]:focus,
textarea:focus,
select:focus {
    outline: none;
    border-color: var(--accent-blue);
}

input[type="file"] {
    padding: 0.5rem 0;
    font-size: 0.9rem;
}

textarea {
    min-height: 150px;
    resize: vertical;
}

.help-text {
    font-size: 0.85rem;
    color: var(--text-muted);
    margin-top: 0.25rem;
}

.form-section-title {
    font-size: 1.1rem;
    font-weight: 600;
    margin: 2rem 0 1rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid var(--border);
}

.disclaimer-box {
    background: #f9f9f9;
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 1.5rem;
    margin: 2rem 0;
    font-size: 0.9rem;
}

.disclaimer-box h2 {
    font-size: 1rem;
    margin-top: 0;
    margin-bottom: 1rem;
}

.disclaimer-box ul {
    margin: 0;
    padding-left: 1.5rem;
}

.disclaimer-box li {
    margin-bottom: 0.5rem;
}

.checkbox-group {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
    margin-top: 1rem;
    padding-top: 1rem;
    border-top: 1px solid var(--border);
}

.checkbox-group input[type="checkbox"] {
    margin-top: 0.25rem;
    width: 18px;
    height: 18px;
}

.checkbox-group label {
    font-weight: normal;
    margin-bottom: 0;
}

button[type="submit"] {
    background: var(--text-main);
    color: white;
    border: none;
    padding: 12px 24px;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    font-family: inherit;
    transition: 0.2s;
}

button[type="submit"]:hover {
    background: var(--accent-blue);
}

button[type="submit"]:disabled {
    background: #999;
    cursor: not-allowed;
}

.message {
    padding: 1rem;
    border-radius: 4px;
    margin-bottom: 1rem;
    font-size: 0.9rem;
}

.message.success {
    background: #d4edda;
    border: 1px solid #c3e6cb;
    color: #155724;
}

.message.error {
    background: #f8d7da;
    border: 1px solid #f5c6cb;
    color: #721c24;
}

.hidden {
    display: none;
}'
]

{ #category : 'accessing' }
ATSubmitFormPage >> description [
	^ 'Submit your human-AI co-authored theoretical paper for publication on AI-Theoretical.'
]

{ #category : 'accessing' }
ATSubmitFormPage >> fileName [
	^ 'submit-form.html'
]

{ #category : 'generating' }
ATSubmitFormPage >> javascript [
	^ '<script>
    const form = document.getElementById(''submissionForm'');
    const submitBtn = document.getElementById(''submitBtn'');
    const successMessage = document.getElementById(''successMessage'');
    const errorMessage = document.getElementById(''errorMessage'');
    
    form.addEventListener(''submit'', async (e) => {
        e.preventDefault();
        
        successMessage.classList.add(''hidden'');
        errorMessage.classList.add(''hidden'');
        
        submitBtn.disabled = true;
        submitBtn.textContent = ''Submitting...'';
        
        try {
            const formData = new FormData(form);
            formData.set(''acceptTerms'', document.getElementById(''acceptTerms'').checked ? ''true'' : ''false'');
            
            const response = await fetch(''/api/submit'', {
                method: ''POST'',
                body: formData
            });
            
            const result = await response.json();
            
            if (response.ok && result.success) {
                successMessage.innerHTML = ''<strong>Almost there!</strong> We have sent a confirmation email to '' + 
                    result.email + ''. Please click the link in that email to complete your submission. '' +
                    ''The link will expire in 24 hours.'';
                successMessage.classList.remove(''hidden'');
                form.reset();
                form.classList.add(''hidden'');
                window.scrollTo(0, 0);
            } else {
                throw new Error(result.error || ''Submission failed'');
            }
            
        } catch (error) {
            errorMessage.textContent = ''Error: '' + error.message;
            errorMessage.classList.remove(''hidden'');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = ''Submit Paper'';
        }
    });
</script>'
]

{ #category : 'accessing' }
ATSubmitFormPage >> title [
	^ 'Submit a Paper — AI-Theoretical'
]
