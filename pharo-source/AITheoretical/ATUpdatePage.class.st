Class {
	#name : 'ATUpdatePage',
	#superclass : 'ATHtmlPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATUpdatePage >> content [
    ^ self contentHtml, String lf, self javascript
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> contentHtml [
    ^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>Manage Your Papers</h1>
    <hr>
</header>

<div class="section">
    <p>Authors can update or withdraw their published papers.</p>
    <p>Enter your email address and we will send you a secure link to manage all papers associated with that address.</p>
</div>

<div id="successMessage" class="message success hidden"></div>
<div id="errorMessage" class="message error hidden"></div>

<form id="updateRequestForm">
    <div class="form-group">
        <label for="email" class="required">Email Address</label>
        <input type="email" id="email" name="email" required placeholder="The email you used when submitting">
        <p class="help-text">This must match the email used in your original submission.</p>
    </div>
    
    <button type="submit" id="submitBtn">Request Update Link</button>
</form>

<div class="info-box">
    <h2>What you can do</h2>
    <ul>
        <li><strong>Create a new version:</strong> Upload an updated PDF while keeping the same DOI and citation info</li>
        <li><strong>Change track:</strong> Move your paper to a different category</li>
        <li><strong>Withdraw:</strong> Remove your paper from the repository (it will remain accessible with a "withdrawn" notice)</li>
    </ul>
</div>

', self footer, '

</div>'
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> css [
    ^ super css, String lf, '
/* UPDATE PAGE STYLES */
form {
    max-width: 500px;
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

input[type="email"] {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid var(--border);
    border-radius: 4px;
    font-family: inherit;
    font-size: 0.95rem;
}

input[type="email"]:focus {
    outline: none;
    border-color: var(--accent-blue);
}

.help-text {
    font-size: 0.85rem;
    color: var(--text-muted);
    margin-top: 0.25rem;
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
}

.info-box {
    background: #f8f9fa;
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 1.5rem;
    margin: 2rem 0;
}

.info-box h2 {
    font-size: 1rem;
    margin-top: 0;
    margin-bottom: 1rem;
}

.info-box ul {
    margin: 0;
    padding-left: 1.5rem;
}

.info-box li {
    margin-bottom: 0.5rem;
    font-size: 0.9rem;
}'
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> description [
    ^ 'Update, create new versions, or withdraw your published papers on AI-Theoretical.'
]

{ #category : 'accessing' }
ATUpdatePage >> fileName [
    ^ 'author-access.html'
]

{ #category : 'generating' }
ATUpdatePage >> formSection [
    ^ '
<div class="intro">
    <p>To withdraw a paper or submit a new version, enter your email address below. 
    We will send you a secure link to manage your published papers.</p>
</div>

<form id="updateForm" class="update-form">
    <div class="form-group">
        <label for="email">Your Email Address</label>
        <input type="email" id="email" name="email" required 
               placeholder="author@university.edu">
        <small>Enter the email address you used when submitting your paper(s).</small>
    </div>
    <button type="submit" id="submitBtn">Request Access Link</button>
</form>

<div id="message" class="message" style="display:none;"></div>

<style>
.update-form { max-width: 500px; }
.form-group { margin-bottom: 20px; }
.form-group label { display: block; margin-bottom: 8px; font-weight: 600; color: #333; }
.form-group input { width: 100%; padding: 12px; border: 1px solid #ddd; border-radius: 6px; font-size: 16px; box-sizing: border-box; }
.form-group input:focus { outline: none; border-color: #2196F3; box-shadow: 0 0 0 3px rgba(33,150,243,0.1); }
.form-group small { display: block; margin-top: 6px; color: #666; }
button[type="submit"] { background: #2196F3; color: white; padding: 14px 28px; border: none; border-radius: 6px; font-size: 16px; cursor: pointer; }
button[type="submit"]:hover { background: #1976D2; }
button[type="submit"]:disabled { background: #ccc; cursor: not-allowed; }
.message { margin-top: 20px; padding: 15px; border-radius: 6px; }
.message.success { background: #e8f5e9; color: #2e7d32; border: 1px solid #a5d6a7; }
.message.error { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; }
</style>

<script>
document.getElementById("updateForm").addEventListener("submit", async function(e) {
    e.preventDefault();
    const btn = document.getElementById("submitBtn");
    const msg = document.getElementById("message");
    const email = document.getElementById("email").value.trim();
    
    btn.disabled = true;
    btn.textContent = "Sending...";
    msg.style.display = "none";
    
    try {
        const response = await fetch("https://ai-theoretical.org/api/author-access/request", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: email })
        });
        
        const data = await response.json();
        
        msg.style.display = "block";
        if (data.success) {
            msg.className = "message success";
            msg.innerHTML = "<strong>Check your email!</strong><br>If you have published papers with this address, we have sent a secure link to <strong>" + email + "</strong>. The link expires in 24 hours.";
            document.getElementById("updateForm").reset();
        } else {
            msg.className = "message error";
            msg.textContent = data.error || "Something went wrong. Please try again.";
        }
    } catch (err) {
        msg.style.display = "block";
        msg.className = "message error";
        msg.textContent = "Network error. Please check your connection and try again.";
    }
    
    btn.disabled = false;
    btn.textContent = "Request Access Link";
});
</script>
'
]

{ #category : 'generating' }
ATUpdatePage >> generate [
    ^ String streamContents: [ :s |
        s nextPutAll: (self htmlHead: 'Author Access').
        s nextPutAll: '<body><div class="container">'.
        s nextPutAll: '<nav><a href="/">← Back to Home</a></nav>'.
        s nextPutAll: '<h1>Author Access</h1>'.
        s nextPutAll: self formSection.
        s nextPutAll: self htmlFooter ]
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> head [
    ^ String streamContents: [ :s |
        s << '<head>'; << String lf.
        s << '    <meta charset="UTF-8">'; << String lf.
        s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
        s << '    <link rel="icon" type="image/svg+xml" href="favicon.svg">'; << String lf.
        s << '    <title>'; << self title; << '</title>'; << String lf.
        s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
        s << '    <meta property="og:title" content="'; << self title; << '">'; << String lf.
        s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
        s << self fonts.
        s << '    <style>'; << String lf.
        s << self css.
        s << '    </style>'; << String lf.
        s << '</head>'; << String lf ]
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> javascript [
    ^ '<script>
    const form = document.getElementById(''updateRequestForm'');
    const submitBtn = document.getElementById(''submitBtn'');
    const successMessage = document.getElementById(''successMessage'');
    const errorMessage = document.getElementById(''errorMessage'');
    
    form.addEventListener(''submit'', async (e) => {
        e.preventDefault();
        
        successMessage.classList.add(''hidden'');
        errorMessage.classList.add(''hidden'');
        
        submitBtn.disabled = true;
        submitBtn.textContent = ''Sending...'';
        
        try {
            const email = document.getElementById(''email'').value;
            
            const response = await fetch(''/api/update-request'', {
                method: ''POST'',
                headers: { ''Content-Type'': ''application/json'' },
                body: JSON.stringify({ email })
            });
            
            const result = await response.json();
            
            if (response.ok && result.success) {
                successMessage.innerHTML = ''<strong>Check your inbox!</strong> If there are papers associated with '' + 
                    email + '', you will receive an email with a link to manage them. The link expires in 24 hours.'';
                successMessage.classList.remove(''hidden'');
                form.reset();
                window.scrollTo(0, 0);
            } else {
                throw new Error(result.error || ''Request failed'');
            }
            
        } catch (error) {
            errorMessage.textContent = ''Error: '' + error.message;
            errorMessage.classList.remove(''hidden'');
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = ''Request Update Link'';
        }
    });
</script>'
]

{ #category : 'as yet unclassified' }
ATUpdatePage >> title [
    ^ 'Manage Your Papers — AI-Theoretical'
]
