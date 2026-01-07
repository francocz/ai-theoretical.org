Class {
	#name : 'ATSubmitPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATSubmitPage >> content [
	^ self contentHtml
]

{ #category : 'generating' }
ATSubmitPage >> contentHtml [
    ^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>Submissions</h1>
    <hr>
</header>

<div class="panels">
    <div class="panel">
        <h2>Submit a New Paper</h2>
        <p>Propose your work for publication on AI-Theoretical.</p>
        <a href="submit-form.html" class="panel-button">New Submission →</a>
    </div>
    
    <div class="panel">
        <h2>Manage Your Papers</h2>
        <p>Withdraw a paper or submit a new version of an existing publication.</p>
        <a href="author-access.html" class="panel-button">Author Access →</a>
    </div>
</div>

', self footer, '

</div>'
]

{ #category : 'generating' }
ATSubmitPage >> css [
	^ super css, String lf, '
/* PANELS LAYOUT */
.panels {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    margin-top: 2rem;
}

.panel {
    background: #f9f9f9;
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 2rem;
}

.panel h2 {
    font-family: inherit;
    font-size: 1.2rem;
    font-weight: 600;
    margin-bottom: 0.75rem;
}

.panel p {
    font-size: 0.9rem;
    color: var(--text-muted);
    margin-bottom: 1.5rem;
    line-height: 1.5;
}

.panel-button {
    display: inline-block;
    background: var(--text-main);
    color: white;
    text-decoration: none;
    padding: 10px 20px;
    font-size: 0.85rem;
    font-weight: 500;
    transition: 0.2s;
}

.panel-button:hover {
    background: var(--accent-blue);
}

@media (max-width: 700px) {
    .panels {
        grid-template-columns: 1fr;
    }
}'
]

{ #category : 'accessing' }
ATSubmitPage >> description [
	^ 'Submit a new paper or manage your existing publications on AI-Theoretical.'
]

{ #category : 'accessing' }
ATSubmitPage >> fileName [
	^ 'submit.html'
]

{ #category : 'generating' }
ATSubmitPage >> head [
    ^ String streamContents: [ :s |
        s << '<head>'; << String lf.
        s << '    <meta charset="UTF-8">'; << String lf.
        s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
        s << '    <link rel="icon" type="image/svg+xml" href="favicon.svg">'; << String lf.
        s << '    <title>'; << self title; << '</title>'; << String lf.
        s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
        s << '    <meta name="keywords" content="AI, theoretical papers, human-AI collaboration, submit paper, publication">'; << String lf.
        s << '    <meta property="og:title" content="'; << self title; << '">'; << String lf.
        s << '    <meta property="og:description" content="Submit your human-AI co-authored theoretical paper for publication.">'; << String lf.
        s << '    <meta property="og:url" content="https://ai-theoretical.org/submit.html">'; << String lf.
        s << '    <meta property="og:type" content="website">'; << String lf.
        s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
        s << self fonts.
        s << '    <style>'; << String lf.
        s << self css.
        s << '    </style>'; << String lf.
        s << '</head>'; << String lf ]
]

{ #category : 'generating' }
ATSubmitPage >> javascript [
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
ATSubmitPage >> title [
	^ 'Submissions — AI-Theoretical'
]
