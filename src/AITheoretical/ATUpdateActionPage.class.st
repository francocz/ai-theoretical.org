Class {
	#name : 'ATUpdateActionPage',
	#superclass : 'Object',
	#instVars : [
		'token',
		'request',
		'papers'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATUpdateActionPage class >> forToken: aToken request: aRequest papers: aPaperCollection [
    ^ self new
        token: aToken;
        request: aRequest;
        papers: aPaperCollection;
        yourself
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> css [
    ^ '
body {
    font-family: "Inter", system-ui, sans-serif;
    margin: 0;
    padding: 20px;
    background: #fafafa;
    color: #1a1a1a;
}
.container {
    max-width: 800px;
    margin: 0 auto;
    background: white;
    padding: 40px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}
header { margin-bottom: 2rem; }
h1 { font-size: 1.8rem; margin: 1rem 0; }
hr { border: none; border-top: 1px solid #eee; margin: 1rem 0; }
.nav { color: #666; text-decoration: none; font-size: 0.9rem; }
.nav:hover { color: #2196F3; }
.section { margin-bottom: 2rem; }
.paper-card {
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 1rem;
    background: #fafafa;
}
.paper-card h3 {
    margin: 0 0 0.5rem 0;
    font-size: 1.1rem;
}
.paper-meta {
    font-size: 0.85rem;
    color: #666;
    margin-bottom: 1rem;
}
.paper-actions {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
}
.btn {
    padding: 8px 16px;
    font-size: 0.85rem;
    font-weight: 500;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-family: inherit;
    transition: 0.2s;
}
.btn-primary {
    background: #1a1a1a;
    color: white;
}
.btn-primary:hover { background: #2196F3; }
.btn-secondary {
    background: #f0f0f0;
    color: #333;
}
.btn-secondary:hover { background: #e0e0e0; }
.btn-danger {
    background: white;
    color: #c00;
    border: 1px solid #c00;
}
.btn-danger:hover { background: #fff0f0; }
.message {
    padding: 1rem;
    border-radius: 4px;
    margin: 1rem 0;
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
.hidden { display: none; }
.no-papers {
    text-align: center;
    padding: 3rem;
    color: #666;
}
footer {
    margin-top: 3rem;
    padding-top: 1rem;
    border-top: 1px solid #eee;
    font-size: 0.8rem;
    color: #999;
    text-align: center;
}
footer a { color: #666; }

/* Modal styles */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
}
.modal {
    background: white;
    padding: 2rem;
    border-radius: 8px;
    max-width: 500px;
    width: 90%;
}
.modal h2 { margin-top: 0; }
.modal-actions {
    display: flex;
    gap: 0.5rem;
    justify-content: flex-end;
    margin-top: 1.5rem;
}

/* File input styles */
.file-input-wrapper {
    margin: 1rem 0;
}
.file-input-wrapper label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
}
.file-input-wrapper input[type="file"] {
    width: 100%;
}
select {
    width: 100%;
    padding: 0.5rem;
    font-family: inherit;
    font-size: 0.9rem;
    border: 1px solid #ddd;
    border-radius: 4px;
}
'
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> footer [
    ^ '<footer>
    <p>Powered by <a href="https://www.anthropic.com/claude" target="_blank">Claude AI</a> and <a href="https://pharo.org" target="_blank">Pharo Smalltalk</a></p>
</footer>'
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> generateHtml [
    "Genera l'HTML della pagina di azione"
    ^ String streamContents: [ :s |
        s << '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/svg+xml" href="/favicon.svg">
    <title>Manage Your Papers — AI-Theoretical</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&display=swap" rel="stylesheet">
    <style>'.
        s << self css.
        s << '</style>
</head>
<body>
<div class="container">
    <header>
        <a href="/" class="nav">← Back to Home</a>
        <h1>Manage Your Papers</h1>
        <hr>
    </header>
    
    <div class="section">
        <p>Papers associated with <strong>'; << request email; << '</strong></p>
    </div>'.
    
        self papers isEmpty 
            ifTrue: [ s << self noPapersContent ]
            ifFalse: [ s << self papersListContent ].
    
        s << '
    <div id="resultMessage" class="message hidden"></div>
    '; << self footer; << '
</div>
'; << self javascript; << '
</body>
</html>' ]
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> noPapersContent [
    ^ '
    <div class="no-papers">
        <p><strong>No papers found</strong></p>
        <p>There are no published papers associated with this email address.</p>
        <p>If you believe this is an error, please <a href="mailto:papers@ai-theoretical.org">contact us</a>.</p>
    </div>'
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> paperCardFor: aPaper [
    | track version q html |
    track := aPaper track ifNil: [ 'Unknown' ].
    version := aPaper version ifNil: [ 1 ].
    q := $' asString.
    
    html := '<div class="paper-card" data-slug="', aPaper slug, '">',
        '<h3>', aPaper title asString, '</h3>',
        '<div class="paper-meta">',
        'Track: ', track, ' · Version: ', version asString, 
        ' · Published: ', aPaper publishedAt asDate asString.
    
    aPaper isWithdrawn ifTrue: [
        html := html, ' · <span style="color: #c00">WITHDRAWN</span>' ].
    
    html := html, '</div>'.
    
    aPaper isWithdrawn ifFalse: [
        html := html, '<div class="paper-actions">',
            '<button class="btn btn-primary" onclick="showNewVersionModal(', q, aPaper slug, q, ')">New Version</button>',
            '<button class="btn btn-secondary" onclick="showChangeTrackModal(', q, aPaper slug, q, ', ', q, track, q, ')">Change Track</button>',
            '<button class="btn btn-danger" onclick="showWithdrawModal(', q, aPaper slug, q, ')">Withdraw</button>',
            '</div>' ].
    
    html := html, '</div>'.
    ^ html
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> papers [
    ^ papers ifNil: [ #() ]
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> papers: aCollection [
    papers := aCollection
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> papersListContent [
    ^ String streamContents: [ :s |
        s << '<div class="papers-list">'.
        self papers do: [ :paper |
            s << (self paperCardFor: paper) ].
        s << '</div>' ]
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> request [
    ^ request
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> request: anATUpdateRequest [
    request := anATUpdateRequest
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> token [
    ^ token
]

{ #category : 'as yet unclassified' }
ATUpdateActionPage >> token: aToken [
    token := aToken
]
