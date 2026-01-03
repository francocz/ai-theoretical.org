Class {
	#name : 'ATWebConsole',
	#superclass : 'Object',
	#instVars : [
		'teapot',
		'port',
		'tunnelProcess'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATWebConsole class >> current [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
ATWebConsole class >> reset [
	Current ifNotNil: [ Current stop ].
	Current := nil
]

{ #category : 'instance creation' }
ATWebConsole class >> startOn: aPort [
	^ self new port: aPort; start
]

{ #category : 'actions' }
ATWebConsole >> approveAtIndex: indexString [
	| index pending |
	index := indexString asInteger.
	pending := ATAutomation current pendingApprovals.
	(index > 0 and: [ index <= pending size ]) ifTrue: [
		ATAutomation current approvePending: (pending at: index) ]
]

{ #category : 'private' }
ATWebConsole >> cloudflaredPath [
	"Trova il percorso di cloudflared"
	#('/opt/homebrew/bin/cloudflared' '/usr/local/bin/cloudflared') do: [ :path |
		path asFileReference exists ifTrue: [ ^ path ] ].
	^ 'cloudflared' "Spera che sia nel PATH"
]

{ #category : 'actions' }
ATWebConsole >> deletePaperAtIndex: anIndexString [
	| idx paper |
	idx := anIndexString asInteger.
	paper := ATRepository current papers at: idx ifAbsent: [ ^ self ].
	[ ATRepository current deletePaper: paper ]
		on: Error
		do: [ :ex | "ignora errori" ]
]

{ #category : 'actions' }
ATWebConsole >> deletePaperAtSlug: aSlug [
	[ ATRepository current deletePaperBySlug: aSlug ]
		on: Error
		do: [ :ex | "ignora errori" ]
]

{ #category : 'actions' }
ATWebConsole >> doBackup [
	| repo backupDir timestamp papersFile submissionsFile |
	repo := ATRepository current.
	backupDir := (repo gitRepoPath, '/backups') asFileReference.
	backupDir ensureCreateDirectory.
	timestamp := DateAndTime now asString copyReplaceAll: ':' with: '-'.
	"Backup papers.json"
	papersFile := backupDir / ('papers-', timestamp, '.json').
	papersFile writeStreamDo: [ :s | s nextPutAll: repo asJSON ].
	"Backup submissions"
	submissionsFile := backupDir / ('submissions-', timestamp, '.json').
	submissionsFile writeStreamDo: [ :s | 
		s nextPutAll: (NeoJSONWriter toString: (repo submissions collect: #asDictionary)) ].
	^ 'Backup created: ', timestamp
]

{ #category : 'actions' }
ATWebConsole >> doExportKV [
	"Esporta tutte le submissions da KV (via API) in un file JSON locale"
	| repo submissions backupDir timestamp file |
	repo := ATRepository current.
	submissions := repo fetchRemoteSubmissions.
	backupDir := (repo gitRepoPath, '/backups') asFileReference.
	backupDir ensureCreateDirectory.
	timestamp := DateAndTime now asString copyReplaceAll: ':' with: '-'.
	file := backupDir / ('kv-export-', timestamp, '.json').
	file writeStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toString: submissions) ].
	^ 'KV exported: ', submissions size asString, ' submissions'
]

{ #category : 'actions' }
ATWebConsole >> doExportPackage [
	| repo srcPath |
	repo := ATRepository current.
	srcPath := repo gitRepoPath, '/src'.
	TonelWriter new exportPackage: (Package named: 'AITheoretical') to: srcPath asFileReference.
	^ 'Package exported to: ', srcPath
]

{ #category : 'actions' }
ATWebConsole >> doGitPull [
	| repo result |
	repo := ATRepository current.
	result := LibC resultOfCommand: 'cd "', repo gitRepoPath, '" && git pull'.
	^ result
]

{ #category : 'actions' }
ATWebConsole >> doGitPush [
	| repo result |
	repo := ATRepository current.
	result := LibC resultOfCommand: 'cd "', repo gitRepoPath, '" && git add . && git commit -m "Console sync" && git push'.
	^ result
]

{ #category : 'actions' }
ATWebConsole >> doGitStatus [
	| repo result |
	repo := ATRepository current.
	result := LibC resultOfCommand: 'cd "', repo gitRepoPath, '" && git status'.
	^ result
]

{ #category : 'private' }
ATWebConsole >> escapeHtml: aString [
	^ aString 
		copyReplaceAll: '&' with: '&amp;';
		copyReplaceAll: '<' with: '&lt;';
		copyReplaceAll: '>' with: '&gt;';
		copyReplaceAll: '"' with: '&quot;'
]

{ #category : 'actions' }
ATWebConsole >> handleAIConfiguration: aRequest [
	| formData provider apiKey model gen |
	formData := aRequest entity.
	provider := formData at: 'provider' ifAbsent: [ 'anthropic' ].
	apiKey := formData at: 'apiKey' ifAbsent: [ '' ].
	model := formData at: 'model' ifAbsent: [ '' ].
	
	apiKey ifEmpty: [ ^ self redirectTo: '/ai' ].
	
	gen := ATAssessmentGenerator new.
	provider = 'anthropic' ifTrue: [ 
		gen useAnthropic: apiKey.
		model ifNotEmpty: [ gen model: model ] ].
	provider = 'openai' ifTrue: [ 
		gen useOpenAI: apiKey.
		model ifNotEmpty: [ gen model: model ] ].
	provider = 'google' ifTrue: [ 
		gen useGoogle: apiKey.
		model ifNotEmpty: [ gen model: model ] ].
	
	ATAutomation current assessmentGenerator: gen.
	^ self redirectTo: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleAITest: aRequest [
	| gen testPrompt result |
	gen := ATAutomation current assessmentGenerator.
	gen ifNil: [ 
		^ self renderResultPage: 'AI Test' message: 'ERROR: No AI configured' backLink: '/ai' ].
	
	testPrompt := 'Reply with exactly: "AI-Theoretical assessment system operational." Nothing else.'.
	[ result := gen assessPaper: testPrompt ]
		on: Error
		do: [ :e | ^ self renderResultPage: 'AI Test' message: 'ERROR: ', e messageText backLink: '/ai' ].
	
	^ self renderResultPage: 'AI Test' message: 'SUCCESS!', String cr, String cr, 'Response:', String cr, result backLink: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleAuditClear [
	ATAuditLog current clear.
	^ self redirectTo: '/audit'
]

{ #category : 'actions' }
ATWebConsole >> handleModelChange: req [
	| params model |
	params := req entity.
	model := params at: 'model' ifAbsent: [ 'gemini-3-flash-preview' ].
	ATAutomation current assessmentGenerator ifNotNil: [ :gen |
		gen model: model.
		ATAutomation current saveConfiguration ].
	^ self redirectTo: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleOAuthConfigure: req [
	| params clientId clientSecret |
	params := req entity.
	clientId := params at: 'clientId' ifAbsent: [ '' ].
	clientSecret := params at: 'clientSecret' ifAbsent: [ '' ].
	
	ATGoogleAuth current
		clientId: clientId;
		clientSecret: clientSecret;
		save.
	
	^ self redirectTo: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleOAuthLogout: req [
	ATGoogleAuth reset.
	^ self redirectTo: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleOAuthStart: req [
	| auth |
	auth := ATGoogleAuth current.
	auth load.
	(auth clientId isNil or: [ auth clientSecret isNil ]) ifTrue: [
		^ self renderResultPage: 'OAuth Error' message: 'Client ID or Secret not configured' backLink: '/ai' ].
	auth startAuthFlow.
	^ self renderResultPage: 'OAuth Started' 
		message: 'Browser opened. Please authorize the application, then return here.' 
		backLink: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleOAuthTest: req [
	| auth result |
	auth := ATGoogleAuth current.
	[ result := auth testConnection ]
		on: Error
		do: [ :e | result := 'Error: ', e messageText ].
	^ self renderResultPage: 'OAuth Test' message: result backLink: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handleOAuthUse: req [
	"Configura ATAssessmentGenerator per usare OAuth con Gemini 3 Flash"
	| gen |
	gen := ATAssessmentGenerator googleWithOAuth.
	gen model: 'gemini-3-flash-preview'.
	ATAutomation current assessmentGenerator: gen.
	ATAutomation current saveConfiguration.
	^ self renderResultPage: 'OAuth Configured' 
		message: 'Now using Gemini 3 Flash with OAuth authentication' 
		backLink: '/ai'
]

{ #category : 'actions' }
ATWebConsole >> handlePromptUpload: aRequest [
	| entity file content version gen |
	entity := aRequest entity.
	file := entity partNamed: 'promptFile' ifNone: [ nil ].
	version := (entity partNamed: 'version' ifNone: [ nil ]) ifNotNil: [ :p | p fieldValue ] ifNil: [ '2.0' ].
	file ifNil: [ ^ self redirectTo: '/prompt' ].
	content := file fieldValue.
	gen := ATAutomation current assessmentGenerator.
	gen ifNotNil: [ 
		gen editorialPrompt: content.
		gen promptVersion: version ]
]

{ #category : 'initialization' }
ATWebConsole >> initialize [

	super initialize.
	port := 8081
]

{ #category : 'accessing' }
ATWebConsole >> port [
	^ port
]

{ #category : 'accessing' }
ATWebConsole >> port: aNumber [
	port := aNumber
]

{ #category : 'actions' }
ATWebConsole >> redirectTo: aPath [
	^ ZnResponse redirect: aPath
]

{ #category : 'private' }
ATWebConsole >> redirectToRoot [
	^ ZnResponse redirect: '/'
]

{ #category : 'actions' }
ATWebConsole >> rejectAtIndex: indexString [
	| index pending |
	index := indexString asInteger.
	pending := ATAutomation current pendingApprovals.
	(index > 0 and: [ index <= pending size ]) ifTrue: [
		ATAutomation current rejectPending: (pending at: index) ]
]

{ #category : 'rendering' }
ATWebConsole >> renderAIConfigPage [
	| gen config auth |
	gen := ATAutomation current assessmentGenerator.
	config := gen ifNil: [ Dictionary new ] ifNotNil: [ gen configurationDictionary ].
	auth := ATGoogleAuth current.
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><title>AI Configuration - AI-Theoretical</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
		h nextPutAll: '.section{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
		h nextPutAll: '.config-table{width:100%;border-collapse:collapse}'.
		h nextPutAll: '.config-table td,.config-table th{padding:10px;text-align:left;border-bottom:1px solid #ddd}'.
		h nextPutAll: '.config-table th{background:#e0e0e0;width:200px}'.
		h nextPutAll: '.btn{padding:12px 24px;margin:5px;cursor:pointer;border:none;border-radius:4px;font-size:14px}'.
		h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-blue{background:#2196F3;color:white}'.
		h nextPutAll: '.btn-orange{background:#ff9800;color:white}.btn-red{background:#f44336;color:white}'.
		h nextPutAll: 'input[type=text],input[type=password],select{padding:10px;width:300px;border:1px solid #ccc;border-radius:4px}'.
		h nextPutAll: '.warning{background:#fff3cd;padding:15px;border-radius:8px;border-left:4px solid #ffc107;margin:15px 0}'.
		h nextPutAll: '.success{background:#d4edda;padding:15px;border-radius:8px;border-left:4px solid #28a745;margin:15px 0}'.
		h nextPutAll: '.error{background:#f8d7da;padding:15px;border-radius:8px;border-left:4px solid #dc3545;margin:15px 0}'.
		h nextPutAll: '.code{background:#1e1e1e;color:#d4d4d4;padding:15px;border-radius:8px;font-family:monospace;font-size:12px;overflow-x:auto}'.
		h nextPutAll: '.oauth-section{background:#e3f2fd;padding:20px;border-radius:8px;margin:20px 0;border-left:4px solid #2196F3}'.
		h nextPutAll: '</style></head><body>'.
		h nextPutAll: '<h1>🤖 AI Configuration</h1>'.
		h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
		
		"Stato attuale"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>Current Configuration</h2>'.
		gen ifNil: [
			h nextPutAll: '<div class="warning"><strong>Not configured.</strong> Select a provider and enter API key below.</div>'
		] ifNotNil: [
			h nextPutAll: '<div class="success"><strong>Configured and ready.</strong></div>'.
			h nextPutAll: '<table class="config-table">'.
			#(provider model temperature seed maxTokens promptVersion promptLength promptHash) do: [ :k |
				| v |
				v := config at: k asString ifAbsent: [ 'n/a' ].
				h nextPutAll: '<tr><th>'; nextPutAll: k asString; nextPutAll: '</th><td>'; nextPutAll: v asString; nextPutAll: '</td></tr>' ].
			h nextPutAll: '</table>'.
			
			"Selettore modello"
			h nextPutAll: '<br><h3>Change Model</h3>'.
			h nextPutAll: '<form method="post" action="/ai/model">'.
			h nextPutAll: '<select name="model" style="width:350px">'.
			gen provider = #google ifTrue: [
				#('gemini-3-flash-preview' 'gemini-3-pro-preview' 'gemini-2.5-flash' 'gemini-2.5-pro' 'gemini-1.5-pro' 'gemini-1.5-flash') do: [ :m |
					h nextPutAll: '<option value="'; nextPutAll: m; nextPutAll: '"'.
					m = gen model ifTrue: [ h nextPutAll: ' selected' ].
					h nextPutAll: '>'; nextPutAll: m; nextPutAll: '</option>' ] ].
			gen provider = #anthropic ifTrue: [
				#('claude-sonnet-4-5-20250514' 'claude-3-5-sonnet-20241022' 'claude-3-opus-20240229' 'claude-3-haiku-20240307') do: [ :m |
					h nextPutAll: '<option value="'; nextPutAll: m; nextPutAll: '"'.
					m = gen model ifTrue: [ h nextPutAll: ' selected' ].
					h nextPutAll: '>'; nextPutAll: m; nextPutAll: '</option>' ] ].
			gen provider = #openai ifTrue: [
				#('gpt-4o' 'gpt-4o-mini' 'gpt-4-turbo' 'o1-preview' 'o1-mini') do: [ :m |
					h nextPutAll: '<option value="'; nextPutAll: m; nextPutAll: '"'.
					m = gen model ifTrue: [ h nextPutAll: ' selected' ].
					h nextPutAll: '>'; nextPutAll: m; nextPutAll: '</option>' ] ].
			h nextPutAll: '</select> '.
			h nextPutAll: '<button type="submit" class="btn btn-blue">Change Model</button>'.
			h nextPutAll: '</form>'.
			
			h nextPutAll: '<br><form method="post" style="display:inline"><button class="btn btn-blue" formaction="/ai/test">Test Connection</button></form>' ].
		h nextPutAll: '</div>'.
		
		"Form configurazione API Key"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>Configure with API Key</h2>'.
		h nextPutAll: '<form method="post" action="/ai/configure">'.
		h nextPutAll: '<p><label><strong>Provider:</strong></label><br>'.
		h nextPutAll: '<select name="provider">'.
		h nextPutAll: '<option value="anthropic"'; nextPutAll: ((gen notNil and: [gen provider = #anthropic]) ifTrue: [' selected'] ifFalse: ['']); nextPutAll: '>Anthropic (Claude)</option>'.
		h nextPutAll: '<option value="openai"'; nextPutAll: ((gen notNil and: [gen provider = #openai]) ifTrue: [' selected'] ifFalse: ['']); nextPutAll: '>OpenAI (GPT-4)</option>'.
		h nextPutAll: '<option value="google"'; nextPutAll: ((gen notNil and: [gen provider = #google]) ifTrue: [' selected'] ifFalse: ['']); nextPutAll: '>Google (Gemini)</option>'.
		h nextPutAll: '</select></p>'.
		h nextPutAll: '<p><label><strong>API Key:</strong></label><br>'.
		h nextPutAll: '<input type="password" name="apiKey" placeholder="Enter API key..." required></p>'.
		h nextPutAll: '<p><label><strong>Model (optional):</strong></label><br>'.
		h nextPutAll: '<input type="text" name="model" placeholder="e.g. claude-sonnet-4-5-20250514" value="'.
		gen ifNotNil: [ h nextPutAll: (gen model ifNil: ['']) ].
		h nextPutAll: '"></p>'.
		h nextPutAll: '<button type="submit" class="btn btn-green">Save Configuration</button>'.
		h nextPutAll: '</form>'.
		h nextPutAll: '</div>'.
		
		"Sezione Google OAuth"
		h nextPutAll: '<div class="oauth-section">'.
		h nextPutAll: '<h2>🔐 Google OAuth (Alternative for Gemini)</h2>'.
		h nextPutAll: '<p>Use your Google Cloud app credentials instead of API key.</p>'.
		
		auth isAuthenticated ifTrue: [
			h nextPutAll: '<div class="success"><strong>✓ Authenticated</strong>'.
			auth refreshToken ifNotNil: [ h nextPutAll: ' (with refresh token)' ].
			h nextPutAll: '</div>'.
			h nextPutAll: '<form method="post" style="display:inline">'.
			h nextPutAll: '<button class="btn btn-green" formaction="/ai/oauth/use">Use OAuth for Gemini</button>'.
			h nextPutAll: '<button class="btn btn-blue" formaction="/ai/oauth/test">Test OAuth</button>'.
			h nextPutAll: '<button class="btn btn-red" formaction="/ai/oauth/logout">Logout</button>'.
			h nextPutAll: '</form>'
		] ifFalse: [
			(auth clientId notNil and: [ auth clientSecret notNil ]) ifTrue: [
				h nextPutAll: '<div class="warning">App configured but not authenticated.</div>'.
				h nextPutAll: '<form method="post"><button class="btn btn-orange" formaction="/ai/oauth/start">Start OAuth Flow</button></form>'
			] ifFalse: [
				h nextPutAll: '<p><strong>Configure your Google Cloud app:</strong></p>'.
				h nextPutAll: '<form method="post" action="/ai/oauth/configure">'.
				h nextPutAll: '<p><label>Client ID:</label><br>'.
				h nextPutAll: '<input type="text" name="clientId" placeholder="xxx.apps.googleusercontent.com" '.
				auth clientId ifNotNil: [ h nextPutAll: 'value="'; nextPutAll: auth clientId; nextPutAll: '" ' ].
				h nextPutAll: '></p>'.
				h nextPutAll: '<p><label>Client Secret:</label><br>'.
				h nextPutAll: '<input type="password" name="clientSecret" placeholder="GOCSPX-xxx"></p>'.
				h nextPutAll: '<button type="submit" class="btn btn-blue">Configure OAuth</button>'.
				h nextPutAll: '</form>' ] ].
		h nextPutAll: '</div>'.
		
		"Sezione riproducibilità"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>📋 Reproducibility Info</h2>'.
		h nextPutAll: '<p>To reproduce an assessment, use these exact parameters:</p>'.
		h nextPutAll: '<div class="code">'.
		h nextPutAll: '# API Call Parameters<br><br>'.
		h nextPutAll: 'temperature: 0<br>'.
		h nextPutAll: 'max_tokens: 4096<br>'.
		gen ifNotNil: [
			h nextPutAll: 'model: '; nextPutAll: gen model; nextPutAll: '<br>'.
			h nextPutAll: 'prompt_version: '; nextPutAll: gen promptVersion; nextPutAll: '<br>'.
			h nextPutAll: 'prompt_hash: '; nextPutAll: gen currentPrompt hash asString; nextPutAll: '<br>'.
			gen provider = #openai ifTrue: [ h nextPutAll: 'seed: 42<br>' ] ].
		h nextPutAll: '</div>'.
		h nextPutAll: '<p><a href="/prompt" class="btn btn-blue" style="text-decoration:none">View/Edit Prompt</a></p>'.
		h nextPutAll: '</div>'.
		
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderApprovals [
	| approvals |
	approvals := ATAutomation current pendingApprovals.
	approvals ifEmpty: [ 
		^ '<h2>Awaiting Approval</h2><p>No papers awaiting approval.</p>' ].
	^ String streamContents: [ :h |
		h nextPutAll: '<h2>Awaiting Approval</h2>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/approve-all">Approve All Recommended</button></form>'.
		approvals doWithIndex: [ :appr :idx |
			h nextPutAll: '<div class="approval">'.
			h nextPutAll: '<h3>'; nextPutAll: appr submission title; nextPutAll: '</h3>'.
			h nextPutAll: '<p><strong>Author:</strong> '; nextPutAll: appr submission authorName; nextPutAll: '</p>'.
			h nextPutAll: '<p><strong>AI Verdict:</strong> <span class="verdict-'.
			h nextPutAll: (appr verdict = #accept ifTrue: [ 'accept">Accept' ] ifFalse: [ 'reject">Reject' ]).
			h nextPutAll: '</span></p>'.
			h nextPutAll: '<details><summary>Show Assessment</summary><pre>'.
			h nextPutAll: appr assessment.
			h nextPutAll: '</pre></details>'.
			h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/approve/'.
			h nextPutAll: idx asString; nextPutAll: '">Approve</button></form>'.
			h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-red" formaction="/reject/'.
			h nextPutAll: idx asString; nextPutAll: '">Reject</button></form>'.
			h nextPutAll: '</div>' ] ]
]

{ #category : 'rendering' }
ATWebConsole >> renderAuditLogPage [
	| log stats recent |
	log := ATAuditLog current.
	stats := log statistics.
	recent := log recentEntries: 50.
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><title>Audit Log - AI-Theoretical</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:1100px;margin:40px auto;padding:20px}'.
		h nextPutAll: '.section{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
		h nextPutAll: '.stats{display:flex;gap:20px;flex-wrap:wrap}'.
		h nextPutAll: '.stat-box{background:white;padding:15px 25px;border-radius:8px;text-align:center;min-width:100px}'.
		h nextPutAll: '.stat-value{font-size:2em;font-weight:bold}'.
		h nextPutAll: '.stat-label{color:#666;font-size:0.9em}'.
		h nextPutAll: '.accept{color:#4CAF50}.reject{color:#f44336}.review{color:#ff9800}.error{color:#9c27b0}'.
		h nextPutAll: 'table{width:100%;border-collapse:collapse;margin-top:15px}'.
		h nextPutAll: 'th,td{padding:10px;text-align:left;border-bottom:1px solid #ddd}'.
		h nextPutAll: 'th{background:#e0e0e0}'.
		h nextPutAll: 'tr:hover{background:#f5f5f5}'.
		h nextPutAll: '.type-assessment{background:#e3f2fd}.type-decision{background:#e8f5e9}.type-error{background:#ffebee}'.
		h nextPutAll: '.btn{padding:10px 20px;margin:5px;cursor:pointer;border:none;border-radius:4px}'.
		h nextPutAll: '.btn-red{background:#f44336;color:white}'.
		h nextPutAll: 'details{margin:5px 0}summary{cursor:pointer;color:#2196F3}'.
		h nextPutAll: 'pre{background:#1e1e1e;color:#d4d4d4;padding:10px;border-radius:4px;font-size:11px;max-height:200px;overflow:auto}'.
		h nextPutAll: '</style></head><body>'.
		h nextPutAll: '<h1>📋 Audit Log</h1>'.
		h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
		
		"Statistiche"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>Statistics</h2>'.
		h nextPutAll: '<div class="stats">'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value">'; nextPutAll: (stats at: 'totalAssessments') asString; nextPutAll: '</div><div class="stat-label">Total Assessments</div></div>'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value accept">'; nextPutAll: (stats at: 'accepts') asString; nextPutAll: '</div><div class="stat-label">Accepts</div></div>'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value reject">'; nextPutAll: (stats at: 'rejects') asString; nextPutAll: '</div><div class="stat-label">Rejects</div></div>'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value review">'; nextPutAll: (stats at: 'reviews') asString; nextPutAll: '</div><div class="stat-label">Reviews</div></div>'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value error">'; nextPutAll: (stats at: 'errors') asString; nextPutAll: '</div><div class="stat-label">Errors</div></div>'.
		h nextPutAll: '<div class="stat-box"><div class="stat-value">'; nextPutAll: ((stats at: 'acceptRate') printShowingDecimalPlaces: 1); nextPutAll: '%</div><div class="stat-label">Accept Rate</div></div>'.
		h nextPutAll: '</div></div>'.
		
		"Recent entries"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>Recent Entries (last 50)</h2>'.
		h nextPutAll: '<form method="post" style="display:inline" onsubmit="return confirm(''Clear all audit log entries?'')">'.
		h nextPutAll: '<button class="btn btn-red" formaction="/audit/clear">Clear Log</button></form>'.
		recent ifEmpty: [
			h nextPutAll: '<p>No entries yet.</p>'
		] ifNotEmpty: [
			h nextPutAll: '<table>'.
			h nextPutAll: '<tr><th>Timestamp</th><th>Type</th><th>Title</th><th>Verdict/Decision</th><th>Details</th></tr>'.
			recent reverseDo: [ :entry |
				| type |
				type := entry at: 'type' ifAbsent: ['unknown'].
				h nextPutAll: '<tr class="type-'; nextPutAll: type; nextPutAll: '">'.
				h nextPutAll: '<td>'; nextPutAll: ((entry at: 'timestamp' ifAbsent: ['']) copyFrom: 1 to: 19); nextPutAll: '</td>'.
				h nextPutAll: '<td>'; nextPutAll: type; nextPutAll: '</td>'.
				h nextPutAll: '<td>'; nextPutAll: (self escapeHtml: (entry at: 'title' ifAbsent: ['—'])); nextPutAll: '</td>'.
				h nextPutAll: '<td class="'; nextPutAll: (entry at: 'verdict' ifAbsent: [(entry at: 'decision' ifAbsent: ['—'])]); nextPutAll: '">'.
				h nextPutAll: (entry at: 'verdict' ifAbsent: [(entry at: 'decision' ifAbsent: [(entry at: 'error' ifAbsent: ['—'])])]); nextPutAll: '</td>'.
				h nextPutAll: '<td>'.
				(entry includesKey: 'assessment') ifTrue: [
					h nextPutAll: '<details><summary>View</summary>'.
					h nextPutAll: '<p><strong>Provider:</strong> '; nextPutAll: (entry at: 'provider' ifAbsent: ['—']); nextPutAll: ' | '.
					h nextPutAll: '<strong>Model:</strong> '; nextPutAll: (entry at: 'model' ifAbsent: ['—']); nextPutAll: ' | '.
					h nextPutAll: '<strong>Prompt:</strong> v'; nextPutAll: (entry at: 'promptVersion' ifAbsent: ['—']); nextPutAll: '</p>'.
					h nextPutAll: '<pre>'; nextPutAll: (self escapeHtml: (entry at: 'assessment' ifAbsent: [''])); nextPutAll: '</pre>'.
					h nextPutAll: '</details>' ].
				(entry includesKey: 'error') ifTrue: [
					h nextPutAll: (self escapeHtml: (entry at: 'error' ifAbsent: [''])) ].
				h nextPutAll: '</td></tr>' ].
			h nextPutAll: '</table>' ].
		h nextPutAll: '</div>'.
		
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPage [
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><meta http-equiv="refresh" content="30"><title>AI-Theoretical Console</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
		h nextPutAll: '.status{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
		h nextPutAll: '.btn{padding:10px 20px;margin:5px;cursor:pointer;border:none;border-radius:4px}'.
		h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-red{background:#f44336;color:white}'.
		h nextPutAll: '.btn-blue{background:#2196F3;color:white}.btn-gray{background:#9e9e9e;color:white}'.
		h nextPutAll: '.approval{background:#fff3cd;padding:15px;margin:10px 0;border-radius:8px;border:1px solid #ffc107}'.
		h nextPutAll: '.verdict-accept{color:#4CAF50}.verdict-reject{color:#f44336}'.
		h nextPutAll: '.nav{margin-bottom:20px}</style></head><body>'.
		h nextPutAll: '<div class="nav"><a href="/ai">🤖 AI Config</a> | <a href="/audit">📋 Audit Log</a> | <a href="/settings">⚙️ Settings</a> | <a href="/prompt">📝 Edit Prompt</a></div>'.
		h nextPutAll: '<h1>AI-Theoretical Console</h1>'.
		h nextPutAll: self renderStatus.
		h nextPutAll: '<div class="actions">'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/start">Start</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-red" formaction="/stop">Stop</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/sync">Sync</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/deploy">Deploy</button></form>'.
		h nextPutAll: '</div>'.
		h nextPutAll: '<div class="actions" style="margin-top:10px">'.
		h nextPutAll: '<strong>Mode:</strong> '.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-gray" formaction="/mode/full">Full Auto</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-gray" formaction="/mode/semi">Semi Auto</button></form>'.
		h nextPutAll: '</div>'.
		h nextPutAll: self renderApprovals.
		h nextPutAll: self renderPending.
		h nextPutAll: self renderPapers.
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPapers [
	| papers |
	papers := ATRepository current papers.
	papers ifEmpty: [ 
		^ '<h2>Published Papers</h2><p>No papers yet.</p>' ].
	^ String streamContents: [ :h |
		h nextPutAll: '<h2>Published Papers</h2>'.
		h nextPutAll: '<table style="width:100%;border-collapse:collapse">'.
		h nextPutAll: '<tr style="background:#f5f5f5"><th style="padding:8px;text-align:left">Title</th><th style="padding:8px;text-align:left">Author</th><th style="padding:8px;text-align:left">Status</th><th style="padding:8px">Actions</th></tr>'.
		papers doWithIndex: [ :p :idx |
			h nextPutAll: '<tr style="border-bottom:1px solid #ddd">'.
			h nextPutAll: '<td style="padding:8px"><strong>'; nextPutAll: (self escapeHtml: p title); nextPutAll: '</strong></td>'.
			h nextPutAll: '<td style="padding:8px">'; nextPutAll: (self escapeHtml: p authors); nextPutAll: '</td>'.
			h nextPutAll: '<td style="padding:8px">'; nextPutAll: p status asString; nextPutAll: '</td>'.
			h nextPutAll: '<td style="padding:8px;text-align:center">'.
			h nextPutAll: '<form method="post" style="display:inline" onsubmit="return confirm(''Delete this paper and all associated files?'')">'.
			h nextPutAll: '<button class="btn btn-red" style="padding:5px 10px" formaction="/paper/delete/'.
			h nextPutAll: idx asString.
			h nextPutAll: '">Delete</button></form>'.
			h nextPutAll: '</td></tr>' ].
		h nextPutAll: '</table>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPending [
	| pending |
	pending := ATRepository current pendingSubmissions.
	pending ifEmpty: [ 
		^ '<h2>Pending Submissions</h2><p>No pending submissions.</p>' ].
	^ String streamContents: [ :h |
		h nextPutAll: '<h2>Pending Submissions</h2>'.
		h nextPutAll: '<ul>'.
		pending do: [ :sub |
			h nextPutAll: '<li><strong>'; nextPutAll: sub title; nextPutAll: '</strong> by '; nextPutAll: sub authorName; nextPutAll: '</li>' ].
		h nextPutAll: '</ul>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPromptPage [
	| gen prompt version |
	gen := ATAutomation current assessmentGenerator.
	prompt := gen ifNil: [ '(No assessment generator configured)' ] ifNotNil: [ gen currentPrompt ifNil: [ '' ] ].
	version := gen ifNil: [ '2.0' ] ifNotNil: [ gen promptVersion ].
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><title>Edit Prompt - AI-Theoretical</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
		h nextPutAll: 'textarea{width:100%;height:400px;font-family:monospace;font-size:13px;padding:15px}'.
		h nextPutAll: '.btn{padding:10px 20px;margin:5px;cursor:pointer;border:none;border-radius:4px}'.
		h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-gray{background:#9e9e9e;color:white}'.
		h nextPutAll: '.btn-blue{background:#2196F3;color:white}'.
		h nextPutAll: '.info{background:#e3f2fd;padding:15px;border-radius:8px;margin:15px 0}'.
		h nextPutAll: 'input[type=text]{padding:8px;width:100px}</style></head><body>'.
		h nextPutAll: '<h1>AI Editorial Prompt</h1>'.
		h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
		h nextPutAll: '<div class="info">'.
		h nextPutAll: '<strong>Current Version:</strong> '; nextPutAll: version; nextPutAll: ' | '.
		h nextPutAll: '<strong>Length:</strong> '; nextPutAll: prompt size asString; nextPutAll: ' chars'.
		h nextPutAll: '</div>'.
		"Form per edit manuale"
		h nextPutAll: '<form method="post">'.
		h nextPutAll: '<label><strong>Version:</strong></label> '.
		h nextPutAll: '<input type="text" name="version" value="'; nextPutAll: version; nextPutAll: '"><br><br>'.
		h nextPutAll: '<textarea name="prompt">'; nextPutAll: (self escapeHtml: prompt); nextPutAll: '</textarea>'.
		h nextPutAll: '<br><br>'.
		h nextPutAll: '<button type="submit" class="btn btn-green">Save Prompt</button>'.
		h nextPutAll: '<a href="/" class="btn btn-gray" style="text-decoration:none">Cancel</a>'.
		h nextPutAll: '</form>'.
		"Form per upload da file"
		h nextPutAll: '<hr><h2>Load from File</h2>'.
		h nextPutAll: '<form method="post" action="/prompt/upload" enctype="multipart/form-data">'.
		h nextPutAll: '<input type="file" name="promptFile" accept=".txt,.md">'.
		h nextPutAll: '<input type="text" name="version" placeholder="Version" value="'; nextPutAll: version; nextPutAll: '" style="margin-left:10px">'.
		h nextPutAll: '<button type="submit" class="btn btn-blue" style="margin-left:10px">Upload</button>'.
		h nextPutAll: '</form>'.
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderResultPage: title message: message backLink: link [
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><title>'; nextPutAll: title; nextPutAll: ' - AI-Theoretical</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
		h nextPutAll: '.result{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
		h nextPutAll: 'pre{background:#1e1e1e;color:#d4d4d4;padding:15px;border-radius:8px;overflow-x:auto}'.
		h nextPutAll: '.btn{padding:10px 20px;background:#2196F3;color:white;border:none;border-radius:4px;text-decoration:none}</style></head><body>'.
		h nextPutAll: '<h1>'; nextPutAll: title; nextPutAll: '</h1>'.
		h nextPutAll: '<div class="result"><pre>'; nextPutAll: (self escapeHtml: message); nextPutAll: '</pre></div>'.
		h nextPutAll: '<a href="'; nextPutAll: link; nextPutAll: '" class="btn">← Back</a>'.
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderSearchPage [
	^ self renderSearchPageWithResults: #() query: Dictionary new
]

{ #category : 'rendering' }
ATWebConsole >> renderSettingsPage [
	| repo backupPath |
	repo := ATRepository current.
	backupPath := repo gitRepoPath, '/backups'.
	^ String streamContents: [ :h |
		h nextPutAll: '<!DOCTYPE html><html><head>'.
		h nextPutAll: '<meta charset="UTF-8"><title>Settings - AI-Theoretical</title>'.
		h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
		h nextPutAll: '.btn{padding:12px 24px;margin:5px;cursor:pointer;border:none;border-radius:4px;font-size:14px}'.
		h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-red{background:#f44336;color:white}'.
		h nextPutAll: '.btn-blue{background:#2196F3;color:white}.btn-orange{background:#ff9800;color:white}'.
		h nextPutAll: '.section{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
		h nextPutAll: '.warning{background:#fff3cd;padding:15px;border-radius:8px;border-left:4px solid #ffc107}'.
		h nextPutAll: '.success{background:#d4edda;padding:15px;border-radius:8px;border-left:4px solid #28a745}'.
		h nextPutAll: '</style></head><body>'.
		h nextPutAll: '<h1>⚙️ Settings & Sync</h1>'.
		h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
		"Sezione Sync"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>🔄 Synchronization</h2>'.
		h nextPutAll: '<p><strong>Repository:</strong> '; nextPutAll: repo gitRepoPath; nextPutAll: '</p>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/settings/sync-from-remote">Pull from Remote API</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/settings/sync-to-remote">Push to GitHub</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-orange" formaction="/settings/full-sync">Full Sync (Pull + Deploy)</button></form>'.
		h nextPutAll: '</div>'.
		"Sezione Backup"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>💾 Local Backup</h2>'.
		h nextPutAll: '<p>Creates a timestamped backup of papers.json and all submissions.</p>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/settings/backup">Create Backup Now</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-orange" formaction="/settings/export-kv">Export KV to JSON</button></form>'.
		h nextPutAll: '</div>'.
		"Sezione Prompt"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>📝 Editorial Prompt</h2>'.
		h nextPutAll: '<p><a href="/prompt" class="btn btn-blue" style="text-decoration:none">Edit Prompt</a></p>'.
		h nextPutAll: '</div>'.
		"Sezione Git"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>📦 Git Operations</h2>'.
		h nextPutAll: '<div class="warning"><strong>Warning:</strong> These operations modify the repository directly.</div><br>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/settings/git-pull">Git Pull</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/settings/git-push">Git Push</button></form>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-orange" formaction="/settings/git-status">Git Status</button></form>'.
		h nextPutAll: '</div>'.
		"Sezione Export Package"
		h nextPutAll: '<div class="section">'.
		h nextPutAll: '<h2>📚 Pharo Package</h2>'.
		h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/settings/export-package">Export AITheoretical Package</button></form>'.
		h nextPutAll: '</div>'.
		h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderStatus [
	| auto pending papers approvals |
	auto := ATAutomation current.
	pending := ATRepository current pendingSubmissions size.
	papers := ATRepository current papers size.
	approvals := auto pendingApprovals size.
	^ String streamContents: [ :h |
		h nextPutAll: '<div class="status">'.
		h nextPutAll: '<p>Automation: <strong>'.
		h nextPutAll: (auto isRunning ifTrue: [ 'Running' ] ifFalse: [ 'Stopped' ]).
		h nextPutAll: '</strong> - Mode: <strong>'.
		h nextPutAll: auto mode asString.
		h nextPutAll: '</strong></p>'.
		h nextPutAll: '<p>Pending submissions: <strong>'; nextPutAll: pending asString; nextPutAll: '</strong></p>'.
		h nextPutAll: '<p>Awaiting approval: <strong>'; nextPutAll: approvals asString; nextPutAll: '</strong></p>'.
		h nextPutAll: '<p>Published papers: <strong>'; nextPutAll: papers asString; nextPutAll: '</strong></p>'.
		h nextPutAll: '<p>Last check: '; nextPutAll: (auto lastCheck ifNil: [ 'never' ] ifNotNil: [ :d | d asString ]); nextPutAll: '</p>'.
		h nextPutAll: '</div>' ]
]

{ #category : 'setup' }
ATWebConsole >> setupRoutes [
	teapot
		"Main pages"
		GET: '/' -> [ :req | self renderPage ];
		GET: '/settings' -> [ :req | self renderSettingsPage ];
		GET: '/prompt' -> [ :req | self renderPromptPage ];
		GET: '/ai' -> [ :req | self renderAIConfigPage ];
		GET: '/audit' -> [ :req | self renderAuditLogPage ];
		
		"Automation controls"
		POST: '/start' -> [ :req | ATAutomation current start. self redirectToRoot ];
		POST: '/stop' -> [ :req | ATAutomation current stop. self redirectToRoot ];
		POST: '/sync' -> [ :req | ATRepository current syncSubmissions. self redirectToRoot ];
		POST: '/deploy' -> [ :req | ATRepository current deploy. self redirectToRoot ];
		POST: '/mode/full' -> [ :req | ATAutomation current fullAuto. self redirectToRoot ];
		POST: '/mode/semi' -> [ :req | ATAutomation current semiAuto. self redirectToRoot ];
		
		"Approval actions"
		POST: '/approve/:index' -> [ :req | self approveAtIndex: (req at: #index). self redirectToRoot ];
		POST: '/reject/:index' -> [ :req | self rejectAtIndex: (req at: #index). self redirectToRoot ];
		POST: '/approve-all' -> [ :req | ATAutomation current approveAllPending. ATRepository current deploy. self redirectToRoot ];
		
		"Paper management - usa indice invece di slug"
		POST: '/paper/delete/:index' -> [ :req | 
			self deletePaperAtIndex: (req at: #index). 
			self redirectToRoot ];
		
		"Prompt management"
		POST: '/prompt' -> [ :req | self updatePrompt: req. self redirectTo: '/prompt' ];
		POST: '/prompt/upload' -> [ :req | self handlePromptUpload: req. self redirectTo: '/prompt' ];
		
		"AI Configuration"
		POST: '/ai/configure' -> [ :req | self handleAIConfiguration: req ];
		POST: '/ai/test' -> [ :req | self handleAITest: req ];
		POST: '/ai/model' -> [ :req | self handleModelChange: req ];
		
		"OAuth routes"
		POST: '/ai/oauth/configure' -> [ :req | self handleOAuthConfigure: req ];
		POST: '/ai/oauth/start' -> [ :req | self handleOAuthStart: req ];
		POST: '/ai/oauth/test' -> [ :req | self handleOAuthTest: req ];
		POST: '/ai/oauth/use' -> [ :req | self handleOAuthUse: req ];
		POST: '/ai/oauth/logout' -> [ :req | self handleOAuthLogout: req ];
		
		"Audit Log"
		POST: '/audit/clear' -> [ :req | self handleAuditClear ];
		
		"Settings actions"
		POST: '/settings/sync-from-remote' -> [ :req | 
			ATRepository current syncSubmissions. 
			self renderResultPage: 'Sync from Remote' message: 'Submissions synced from API' backLink: '/settings' ];
		POST: '/settings/sync-to-remote' -> [ :req | 
			| result |
			result := self doGitPush.
			self renderResultPage: 'Push to GitHub' message: result backLink: '/settings' ];
		POST: '/settings/full-sync' -> [ :req | 
			ATRepository current syncSubmissions.
			ATRepository current deploy.
			self renderResultPage: 'Full Sync' message: 'Pull + Deploy completed' backLink: '/settings' ];
		POST: '/settings/backup' -> [ :req | 
			| result |
			result := self doBackup.
			self renderResultPage: 'Backup' message: result backLink: '/settings' ];
		POST: '/settings/export-kv' -> [ :req | 
			| result |
			result := self doExportKV.
			self renderResultPage: 'Export KV' message: result backLink: '/settings' ];
		POST: '/settings/git-pull' -> [ :req | 
			| result |
			result := self doGitPull.
			self renderResultPage: 'Git Pull' message: result backLink: '/settings' ];
		POST: '/settings/git-push' -> [ :req | 
			| result |
			result := self doGitPush.
			self renderResultPage: 'Git Push' message: result backLink: '/settings' ];
		POST: '/settings/git-status' -> [ :req | 
			| result |
			result := self doGitStatus.
			self renderResultPage: 'Git Status' message: result backLink: '/settings' ];
		POST: '/settings/export-package' -> [ :req | 
			| result |
			result := self doExportPackage.
			self renderResultPage: 'Export Package' message: result backLink: '/settings' ]
]

{ #category : 'lifecycle' }
ATWebConsole >> start [
	self stop.
	teapot := Teapot configure: { #port -> port }.
	self setupRoutes.
	teapot start.
	self startTunnel.
	^ 'Console running on https://console.ai-theoretical.org'
]

{ #category : 'tunnel' }
ATWebConsole >> startTunnel [
	"Avvia cloudflared tunnel in background"
	tunnelProcess ifNotNil: [ tunnelProcess isRunning ifTrue: [ ^ self ] ].
	tunnelProcess := OSSUnixSubprocess new
		command: self cloudflaredPath;
		arguments: #('tunnel' 'run' 'at-console');
		redirectStdout;
		redirectStderr;
		run
]

{ #category : 'lifecycle' }
ATWebConsole >> stop [
	self stopTunnel.
	teapot ifNotNil: [
		teapot stop.
		teapot := nil ]
]

{ #category : 'tunnel' }
ATWebConsole >> stopTunnel [
	"Ferma cloudflared tunnel"
	tunnelProcess ifNil: [ ^ self ].
	tunnelProcess isRunning ifTrue: [
		tunnelProcess terminate.
		tunnelProcess waitForExit ].
	tunnelProcess := nil
]

{ #category : 'accessing' }
ATWebConsole >> teapot [
	^ teapot
]

{ #category : 'accessing' }
ATWebConsole >> tunnelProcess [
	^ tunnelProcess
]

{ #category : 'actions' }
ATWebConsole >> updatePrompt: aRequest [
	| formData newPrompt version gen |
	formData := aRequest entity.
	newPrompt := (formData at: 'prompt' ifAbsent: [ '' ]).
	version := (formData at: 'version' ifAbsent: [ '2.0' ]).
	gen := ATAutomation current assessmentGenerator.
	gen ifNotNil: [ 
		gen editorialPrompt: newPrompt.
		gen promptVersion: version ]
]
