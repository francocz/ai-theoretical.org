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
    (index < 1 or: [ index > pending size ]) ifTrue: [ ^ nil ].
    ATAutomation current approvePending: (pending at: index).
    ^ #approved
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
    (idx < 1 or: [ idx > ATRepository current papers size ]) ifTrue: [ ^ nil ].
    paper := ATRepository current papers at: idx.
    ATRepository current deletePaper: paper.
    ^ paper
]

{ #category : 'actions' }
ATWebConsole >> deletePaperAtSlug: aSlug [
	[ ATRepository current deletePaperBySlug: aSlug ]
		on: Error
		do: [ :ex | "ignora errori" ]
]

{ #category : 'actions' }
ATWebConsole >> deleteSubmissionAtIndex: indexString [
	| index pending sub |
	index := indexString asInteger.
	pending := ATRepository current pendingSubmissions reject: [ :s |
		((ATAutomation current instVarNamed: 'processedIds') includes: s id) or: [
			ATAutomation current pendingApprovals anySatisfy: [ :a | a submission id = s id ] ] ].
	(index < 1 or: [ index > pending size ]) ifTrue: [ ^ self ].
	sub := pending at: index.
	sub delete
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
	"Esporta tutte le submissions da KV in una cartella locale NON tracciata da Git"
	| repo submissions privateDir timestamp file publicFile publicData |
	repo := ATRepository current.
	submissions := repo fetchRemoteSubmissions.
	
	"Cartella per dati sensibili (deve essere in .gitignore)"
	privateDir := (repo gitRepoPath, '/private-data') asFileReference.
	privateDir ensureCreateDirectory.
	
	timestamp := DateAndTime now asString copyReplaceAll: ':' with: '-'.
	
	"Export completo con dati sensibili (solo locale)"
	file := privateDir / ('kv-full-export-', timestamp, '.json').
	file writeStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toStringPretty: (submissions collect: #asDictionary)) ].
	
	"Export pubblico senza email e dati personali (per backup tracciato)"
	publicData := submissions collect: [ :sub |
		| dict |
		dict := sub asDictionary copy.
		dict removeKey: 'authorEmail' ifAbsent: [].
		dict removeKey: 'email' ifAbsent: [].
		dict at: 'authorName' put: '[redacted]'.
		dict ].
	publicFile := (repo gitRepoPath, '/backups') asFileReference / ('kv-export-', timestamp, '.json').
	publicFile parent ensureCreateDirectory.
	publicFile writeStreamDo: [ :s | s nextPutAll: (NeoJSONWriter toStringPretty: publicData) ].
	
	^ 'KV exported: ', submissions size asString, ' submissions', String cr,
	  'Full data (with emails): ', file fullName, String cr,
	  'Redacted data: ', publicFile fullName
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
    "Escape caratteri HTML speciali"
    aString ifNil: [ ^ '' ].
    ^ aString asString
        copyReplaceAll: '&' with: '&amp;';
        copyReplaceAll: '<' with: '&lt;';
        copyReplaceAll: '>' with: '&gt;';
        copyReplaceAll: '"' with: '&quot;'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> formatNumber: aNumber [
    "Formatta numero con separatore migliaia"
    | str result digits |
    str := aNumber asString.
    digits := str size.
    digits <= 3 ifTrue: [ ^ str ].
    result := ''.
    str reversed doWithIndex: [ :c :i |
        result := c asString, result.
        (i \\\\ 3 = 0 and: [ i < digits ]) ifTrue: [ result := ',', result ] ].
    ^ result
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

{ #category : 'handlers' }
ATWebConsole >> handleDeletePaper: req [
    | index result |
    index := req at: #index ifAbsent: [ ^ self redirectToRoot ].
    [ result := self deletePaperAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Delete Error' message: e messageText backLink: '/' ].
    result ifNil: [ ^ self renderResultPage: 'Delete Error' message: 'Invalid index' backLink: '/' ].
    ^ self renderResultPage: 'Deleted' message: 'Paper deleted and pushed to site' backLink: '/'.

]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleDoApprove: req [
    | index |
    index := req at: #index.
    [ self approveAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Approve Error' message: e messageText backLink: '/' ].
    ^ self renderResultPage: 'Approval' message: 'Paper successfully approved and deployed' backLink: '/'.

]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleDoDelete: req [
    | index |
    index := req at: #index.
    [ self deleteSubmissionAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Delete Error' message: e messageText backLink: '/' ].
    self renderResultPage: 'Delete' message: 'Submission deleted successfully' backLink: '/'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleDoProcess: req [
    | index result |
    index := req at: #index.
    [ result := self processAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Process Error' message: e messageText backLink: '/' ].
    result ifNil: [ ^ self renderResultPage: 'Process Error' message: 'Invalid index or already processed' backLink: '/' ].
    self renderResultPage: 'Process' message: 'Submission processed successfully' backLink: '/'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleDoRegenerate: req [
    | index |
    index := req at: #index.
    [ self regenerateAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Regenerate Error' message: e messageText backLink: '/' ].
    self renderResultPage: 'Regenerate' message: 'Assessment regenerated' backLink: '/'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleDoReject: req [
    | index |
    index := req at: #index.
    [ self rejectAtIndex: index ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Reject Error' message: e messageText backLink: '/' ].
    self renderResultPage: 'Rejection' message: 'Paper successfully rejected' backLink: '/'
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

{ #category : 'api handlers' }
ATWebConsole >> handleNotifyNewVersion: req [
    "Riceve notifica dal worker che è stata sottomessa una nuova versione.
     Il paper torna in pending, quindi va rimosso dalla homepage."
    | body paperId paper |
    body := NeoJSONReader fromString: req entity string.
    paperId := body at: 'paperId' ifAbsent: [ '' ].
    
    paperId isEmpty ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"paperId required"}') ].
    
    "Trova il paper nel repository locale"
    paper := ATRepository current papers 
        detect: [ :p | p submissionId = paperId ] 
        ifNone: [ nil ].
    
    paper ifNil: [
        "Paper non trovato localmente"
        ^ ZnResponse ok: (ZnEntity json: '{"success":true,"message":"Paper not in local repository"}') ].
    
    "Il paper va in pending per review, quindi rimuoviamo dalla homepage"
    [ ATRepository current deletePaper: paper ]
        on: Error
        do: [ :e | 
            ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"', e messageText, '"}') ].
    
    ^ ZnResponse ok: (ZnEntity json: '{"success":true,"message":"Paper removed pending review, site regenerated"}')
]

{ #category : 'api handlers' }
ATWebConsole >> handleNotifyWithdraw: req [
    "Riceve notifica dal worker che un paper è stato ritirato"
    | body paperId slug paper |
    body := NeoJSONReader fromString: req entity string.
    paperId := body at: 'paperId' ifAbsent: [ '' ].
    slug := body at: 'slug' ifAbsent: [ '' ].
    
    paperId isEmpty ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"paperId required"}') ].
    
    "Trova il paper nel repository locale"
    paper := ATRepository current papers 
        detect: [ :p | p submissionId = paperId ] 
        ifNone: [ nil ].
    
    paper ifNil: [
        "Paper non trovato localmente, probabilmente già rimosso"
        ^ ZnResponse ok: (ZnEntity json: '{"success":true,"message":"Paper not in local repository"}') ].
    
    "Cancella il paper e rigenera"
    [ ATRepository current deletePaper: paper ]
        on: Error
        do: [ :e | 
            ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"', e messageText, '"}') ].
    
    ^ ZnResponse ok: (ZnEntity json: '{"success":true,"message":"Paper removed and site regenerated"}')
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

{ #category : 'as yet unclassified' }
ATWebConsole >> handlePrepareVersionUpdate: req [
    "Prepara update versione"
    | body token slug newTrack result |
    body := NeoJSONReader fromString: req entity string.
    token := body at: 'token' ifAbsent: [ '' ].
    slug := body at: 'slug' ifAbsent: [ '' ].
    newTrack := body at: 'newTrack' ifAbsent: [ nil ].
    
    (token isEmpty or: [ slug isEmpty ]) ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"Token and slug required"}') ].
    
    result := ATRepository current updatePaperVersion: slug withToken: token newTrack: newTrack.
    ^ ZnResponse ok: (ZnEntity json: (NeoJSONWriter toString: result))
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

{ #category : 'as yet unclassified' }
ATWebConsole >> handleRateLimitConfig: req [
    | params config |
    params := req entity.
    config := Dictionary new.
    
    (params at: 'dailyLimit' ifAbsent: [nil]) ifNotNil: [ :v |
        v asString ifNotEmpty: [ config at: 'dailyLimit' put: v asString asInteger ] ].
    (params at: 'ipLimit' ifAbsent: [nil]) ifNotNil: [ :v |
        v asString ifNotEmpty: [ config at: 'ipLimit' put: v asString asInteger ] ].
    (params at: 'alertEmail' ifAbsent: [nil]) ifNotNil: [ :v |
        v asString ifNotEmpty: [ config at: 'alertEmail' put: v asString ] ].
    config at: 'enabled' put: (params at: 'enabled' ifAbsent: [nil]) = 'true'.
    
    [ ATRepository current setRateLimitConfig: config ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Rate Limit' message: 'Error: ', e messageText backLink: '/rate-limit' ].
    
    ^ self redirectTo: '/rate-limit'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleUpdateRequest: req [
    "Gestisce richiesta di update da Worker"
    | body email result |
    body := NeoJSONReader fromString: req entity string.
    email := body at: 'email' ifAbsent: [ '' ].
    
    email isEmpty ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"Email required"}') ].
    
    result := ATRepository current processUpdateRequest: email.
    ^ ZnResponse ok: (ZnEntity json: (NeoJSONWriter toString: result))
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleUploadNewVersion: req [
    "Riceve upload nuova versione PDF"
    | parts uploadToken pdfBytes result |
    
    "Parse multipart"
    parts := ZnMultiPartFormDataEntity new.
    [ parts := req entity ]
        on: Error
        do: [ :e | ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"Invalid multipart data"}') ].
    
    uploadToken := ''.
    pdfBytes := nil.
    
    parts parts do: [ :part |
        part fieldName = 'uploadToken' ifTrue: [ uploadToken := part fieldValue ].
        part fieldName = 'pdf' ifTrue: [ pdfBytes := part entity bytes ] ].
    
    (uploadToken isEmpty or: [ pdfBytes isNil ]) ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"Upload token and PDF required"}') ].
    
    result := ATRepository current completeVersionUpdate: uploadToken pdfBytes: pdfBytes.
    ^ ZnResponse ok: (ZnEntity json: (NeoJSONWriter toString: result))
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleValidateUpdateToken: req [
    "Valida token e ritorna paper"
    | body token result |
    body := NeoJSONReader fromString: req entity string.
    token := body at: 'token' ifAbsent: [ '' ].
    
    token isEmpty ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"valid":false,"error":"Token required"}') ].
    
    result := ATRepository current validateUpdateToken: token.
    ^ ZnResponse ok: (ZnEntity json: (NeoJSONWriter toString: result))
]

{ #category : 'as yet unclassified' }
ATWebConsole >> handleWithdrawPaper: req [
    "Ritira un paper"
    | body token slug reason result |
    body := NeoJSONReader fromString: req entity string.
    token := body at: 'token' ifAbsent: [ '' ].
    slug := body at: 'slug' ifAbsent: [ '' ].
    reason := body at: 'reason' ifAbsent: [ '' ].
    
    (token isEmpty or: [ slug isEmpty ]) ifTrue: [
        ^ ZnResponse ok: (ZnEntity json: '{"success":false,"error":"Token and slug required"}') ].
    
    result := ATRepository current withdrawPaper: slug withToken: token reason: reason.
    ^ ZnResponse ok: (ZnEntity json: (NeoJSONWriter toString: result))
]

{ #category : 'as yet unclassified' }
ATWebConsole >> htmlHead: aTitle [
    "Genera l''head HTML standard per le pagine console con favicon"
    ^ String streamContents: [ :s |
        s nextPutAll: '<!DOCTYPE html><html><head>'.
        s nextPutAll: '<meta charset="UTF-8">'.
        s nextPutAll: '<meta name="viewport" content="width=device-width, initial-scale=1.0">'.
        s nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        s nextPutAll: '<title>'; nextPutAll: aTitle; nextPutAll: ' - AI-Theoretical Console</title>' ]
]

{ #category : 'as yet unclassified' }
ATWebConsole >> incrementVersion: aVersionString [
    "Incrementa la versione minore: 1.3 -> 1.4"
    | parts major minor |
    parts := aVersionString splitOn: '.'.
    parts size < 2 ifTrue: [ ^ aVersionString, '.1' ].
    major := parts first.
    minor := (parts second asInteger ifNil: [ 0 ]) + 1.
    ^ major, '.', minor asString
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
ATWebConsole >> processAtIndex: indexString [
    | index pending sub |
    index := indexString asInteger.
    pending := ATRepository current pendingSubmissions reject: [ :s |
        ((ATAutomation current instVarNamed: 'processedIds') includes: s id) or: [
            ATAutomation current pendingApprovals anySatisfy: [ :a | a submission id = s id ] ] ].
    (index < 1 or: [ index > pending size ]) ifTrue: [ ^ nil ].
    sub := pending at: index.
    ^ ATAutomation current processSubmission: sub
]

{ #category : 'actions' }
ATWebConsole >> redirectTo: aPath [
	^ ZnResponse redirect: aPath
]

{ #category : 'private' }
ATWebConsole >> redirectToRoot [
	^ ZnResponse redirect: '/'
]

{ #category : 'as yet unclassified' }
ATWebConsole >> regenerateAtIndex: indexString [
    | index pending |
    index := indexString asInteger.
    pending := ATAutomation current pendingApprovals.
    (index < 1 or: [ index > pending size ]) ifTrue: [ ^ nil ].
    ATAutomation current regenerateAssessmentFor: (pending at: index).
    ^ #regenerated
]

{ #category : 'as yet unclassified' }
ATWebConsole >> regeneratePublicPromptJs [
    "Rigenera il file ai-prompt.js per il sito pubblico e fa deploy"
    | js gitPath |
    gitPath := ATRepository current gitRepoPath.
    js := ATAIEditorialPromptPage generatePromptsJs.
    (gitPath, '/ai-prompt.js') asFileReference
        ensureDelete;
        writeStreamDo: [ :s | s nextPutAll: js ].
    ATDeployment deployGitRepoPath: gitPath withMessage: 'Update AI editorial prompts'
]

{ #category : 'actions' }
ATWebConsole >> rejectAtIndex: indexString [
    | index pending |
    index := indexString asInteger.
    pending := ATAutomation current pendingApprovals.
    (index < 1 or: [ index > pending size ]) ifTrue: [ ^ nil ].
    ATAutomation current rejectPending: (pending at: index).
    ^ #rejected
]

{ #category : 'rendering' }
ATWebConsole >> renderAIConfigPage [
    | gen config auth |
    gen := ATAutomation current assessmentGenerator.
    config := gen ifNil: [ Dictionary new ] ifNotNil: [ gen configurationDictionary ].
    auth := ATGoogleAuth current.
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>AI Configuration - AI-Theoretical</title>'.
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
        h nextPutAll: '<form method="post" action="/approve-all" style="display:inline"><button class="btn btn-green">Approve All Recommended</button></form>'.
        approvals doWithIndex: [ :appr :idx |
            h nextPutAll: '<div class="approval">'.
            h nextPutAll: '<h3>'; nextPutAll: (self escapeHtml: appr submission title); nextPutAll: '</h3>'.
            h nextPutAll: '<p><strong>Author:</strong> '; nextPutAll: (self escapeHtml: appr submission authorName); nextPutAll: '</p>'.
            h nextPutAll: '<p><strong>Track:</strong> '; nextPutAll: (appr submission track ifNil: ['?']); nextPutAll: '</p>'.
            
            "Verdict con colori appropriati"
            h nextPutAll: '<p><strong>AI Verdict:</strong> '.
            appr verdict = #accept ifTrue: [ 
                h nextPutAll: '<span class="verdict-accept">✓ Accept</span>' ].
            appr verdict = #reject ifTrue: [ 
                h nextPutAll: '<span class="verdict-reject">✗ Reject</span>' ].
            appr verdict = #review ifTrue: [ 
                h nextPutAll: '<span style="color:#ff9800;font-weight:bold">⚠ Needs Revision</span>' ].
            appr verdict = #aiFailure ifTrue: [ 
                h nextPutAll: '<span style="color:#9c27b0;font-weight:bold">⚡ AI Failure - Manual Review Required</span>' ].
            h nextPutAll: '</p>'.
            
            "Assessment (se presente)"
            h nextPutAll: '<details><summary>Show Assessment</summary><pre>'.
            h nextPutAll: (self escapeHtml: (appr assessment ifNil: ['No assessment available'])).
            h nextPutAll: '</pre></details>'.
            
            "Bottoni azione - uso hidden field per index"
            h nextPutAll: '<div style="margin-top:10px">'.
            h nextPutAll: '<form method="post" action="/do-approve" style="display:inline"><input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '"><button class="btn btn-green">Approve</button></form>'.
            h nextPutAll: '<form method="post" action="/do-reject" style="display:inline"><input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '"><button class="btn btn-red">Reject</button></form>'.
            h nextPutAll: '<form method="post" action="/do-regenerate" style="display:inline"><input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '"><button class="btn btn-blue">🔄 New Assessment</button></form>'.
            h nextPutAll: '</div>'.
            
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
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>Audit Log - AI-Theoretical</title>'.
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
    | isRunning mode |
    isRunning := ATAutomation current isRunning.
    mode := ATAutomation current mode.
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8"><meta http-equiv="refresh" content="30">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>AI-Theoretical Console</title>'.
        h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
        h nextPutAll: '.status{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
        h nextPutAll: '.btn{padding:10px 20px;margin:5px;cursor:pointer;border:none;border-radius:4px}'.
        h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-red{background:#f44336;color:white}'.
        h nextPutAll: '.btn-blue{background:#2196F3;color:white}.btn-gray{background:#9e9e9e;color:white}'.
        h nextPutAll: '.btn:disabled{opacity:0.5;cursor:not-allowed}'.
        h nextPutAll: '.approval{background:#fff3cd;padding:15px;margin:10px 0;border-radius:8px;border:1px solid #ffc107}'.
        h nextPutAll: '.verdict-accept{color:#4CAF50;font-weight:bold}.verdict-reject{color:#f44336;font-weight:bold}'.
        h nextPutAll: '.nav{margin-bottom:20px}'.
        h nextPutAll: 'details{margin:10px 0}summary{cursor:pointer;color:#2196F3;font-weight:500}'.
        h nextPutAll: 'details pre{background:#f8f8f8;border:1px solid #ddd;border-radius:4px;padding:15px;margin-top:10px;white-space:pre-wrap;word-wrap:break-word;max-height:400px;overflow-y:auto;font-size:13px}'.
        h nextPutAll: '.toast{position:fixed;top:20px;right:20px;padding:15px 25px;border-radius:8px;color:white;font-weight:bold;z-index:1000;animation:fadeIn 0.3s}'.
        h nextPutAll: '.toast-info{background:#2196F3}.toast-success{background:#4CAF50}.toast-error{background:#f44336}'.
        h nextPutAll: '@keyframes fadeIn{from{opacity:0;transform:translateY(-20px)}to{opacity:1;transform:translateY(0)}}'.
        h nextPutAll: '</style></head><body>'.
        h nextPutAll: '<div id="toast" class="toast" style="display:none"></div>'.
        h nextPutAll: '<div class="nav"><a href="/ai">🤖 AI Config</a> | <a href="/audit">📋 Audit Log</a> | <a href="/rate-limit">⚡ Rate Limit</a> | <a href="/usage">📊 Usage</a> | <a href="/settings">⚙️ Settings</a> | <a href="/prompt">📝 Edit Prompt</a></div>'.
        h nextPutAll: '<h1>AI-Theoretical Console</h1>'.
        h nextPutAll: self renderStatus.
        h nextPutAll: '<div class="actions">'.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-green" formaction="/start"'.
        isRunning ifTrue: [ h nextPutAll: ' disabled' ].
        h nextPutAll: '>Start</button></form>'.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-red" formaction="/stop"'.
        isRunning ifFalse: [ h nextPutAll: ' disabled' ].
        h nextPutAll: '>Stop</button></form>'.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/sync">Pull from Site</button></form>'.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-blue" formaction="/deploy">Push to Site</button></form>'.
        h nextPutAll: '</div>'.
        h nextPutAll: '<div class="actions" style="margin-top:10px">'.
        h nextPutAll: '<strong>Switch to:</strong> '.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-gray" formaction="/mode/full"'.
        mode = #fullAuto ifTrue: [ h nextPutAll: ' disabled' ].
        h nextPutAll: '>Full Auto</button></form>'.
        h nextPutAll: '<form method="post" style="display:inline"><button class="btn btn-gray" formaction="/mode/semi"'.
        mode = #semiAuto ifTrue: [ h nextPutAll: ' disabled' ].
        h nextPutAll: '>Semi Auto</button></form>'.
        h nextPutAll: '</div>'.
        h nextPutAll: self renderPending.
        h nextPutAll: self renderApprovals.
        h nextPutAll: self renderPapers.
        h nextPutAll: '<script>'.
        h nextPutAll: 'function showToast(msg,type){var t=document.getElementById("toast");t.textContent=msg;t.className="toast toast-"+type;t.style.display="block";setTimeout(function(){t.style.display="none"},3000)}'.
        h nextPutAll: 'document.querySelectorAll("form").forEach(function(f){f.addEventListener("submit",function(e){var btn=f.querySelector("button");if(!btn||btn.disabled)return;btn.disabled=true;btn.dataset.original=btn.textContent;btn.textContent="Working...";showToast("Operation started...","info")})})'.
        h nextPutAll: '</script>'.
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
			h nextPutAll: '<form method="post" action="/paper/delete" style="display:inline" onsubmit="return confirm(''Delete this paper and all associated files?'')">'.
			h nextPutAll: '<input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '">'.
			h nextPutAll: '<button class="btn btn-red" style="padding:5px 10px">Delete</button></form>'.
			h nextPutAll: '</td></tr>' ].
		h nextPutAll: '</table>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPending [
    | pending processedIds |
    pending := ATRepository current pendingSubmissions.
    processedIds := ATAutomation current instVarNamed: 'processedIds'.
    
    "Filtra: mostra solo quelle NON ancora in processedIds e NON in pendingApprovals"
    pending := pending reject: [ :sub |
        (processedIds includes: sub id) or: [
            ATAutomation current pendingApprovals anySatisfy: [ :a | a submission id = sub id ] ] ].
    
    pending ifEmpty: [ 
        ^ '<h2>Pending Submissions</h2><p>No pending submissions awaiting processing.</p>' ].
    
    ^ String streamContents: [ :h |
        h nextPutAll: '<h2>Pending Submissions</h2>'.
        h nextPutAll: '<p>These submissions need AI assessment:</p>'.
        pending doWithIndex: [ :sub :idx |
            h nextPutAll: '<div class="status" style="margin:10px 0">'.
            h nextPutAll: '<strong>'; nextPutAll: (self escapeHtml: sub title); nextPutAll: '</strong>'.
            h nextPutAll: ' by '; nextPutAll: (self escapeHtml: sub authorName).
            h nextPutAll: '<br><small>Submitted: '; nextPutAll: sub submittedAt asString; nextPutAll: '</small>'.
            h nextPutAll: '<form method="post" action="/do-process" style="display:inline;margin-left:20px">'.
            h nextPutAll: '<input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '">'.
            h nextPutAll: '<button class="btn btn-blue">Process</button>'.
            h nextPutAll: '</form>'.
            h nextPutAll: '<form method="post" action="/do-delete" style="display:inline">'.
            h nextPutAll: '<input type="hidden" name="index" value="'; nextPutAll: idx asString; nextPutAll: '">'.
            h nextPutAll: '<button class="btn btn-red">Delete</button>'.
            h nextPutAll: '</form>'.
            h nextPutAll: '</div>' ] ]
]

{ #category : 'rendering' }
ATWebConsole >> renderPromptPage [
    | prompts |
    prompts := ATPromptRegistry current prompts.
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>Edit Prompts - AI-Theoretical</title>'.
        h nextPutAll: '<style>
body{font-family:sans-serif;max-width:1000px;margin:40px auto;padding:20px}
.track-tabs{display:flex;gap:0;margin:20px 0}
.track-tab{padding:12px 20px;cursor:pointer;border:1px solid #ddd;border-bottom:none;background:#f5f5f5;font-size:14px}
.track-tab:hover{background:#e8e8e8}
.track-tab.active{background:#fff;border-bottom:1px solid #fff;margin-bottom:-1px;font-weight:bold}
.track-content{display:none;border:1px solid #ddd;padding:20px}
.track-content.active{display:block}
textarea{width:100%;height:350px;font-family:monospace;font-size:13px;padding:15px;box-sizing:border-box}
.btn{padding:10px 20px;margin:5px 5px 5px 0;cursor:pointer;border:none;border-radius:4px}
.btn-green{background:#4CAF50;color:white}
.btn-gray{background:#9e9e9e;color:white}
.info{background:#e3f2fd;padding:10px 15px;border-radius:4px;margin-bottom:15px;font-size:14px}
.version-input{padding:6px;width:80px;font-size:14px}
</style></head><body>'.
        h nextPutAll: '<h1>AI Editorial Prompts</h1>'.
        h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
        
        "Tab buttons"
        h nextPutAll: '<div class="track-tabs">'.
        prompts doWithIndex: [ :p :i |
            h nextPutAll: '<div class="track-tab'.
            i = 1 ifTrue: [ h nextPutAll: ' active' ].
            h nextPutAll: '" data-track="'; nextPutAll: p track asString; nextPutAll: '">'.
            h nextPutAll: (self trackLabel: p track).
            h nextPutAll: '</div>' ].
        h nextPutAll: '</div>'.
        
        "Tab contents"
        prompts doWithIndex: [ :p :i |
            h nextPutAll: '<div class="track-content'.
            i = 1 ifTrue: [ h nextPutAll: ' active' ].
            h nextPutAll: '" id="track-'; nextPutAll: p track asString; nextPutAll: '">'.
            h nextPutAll: '<div class="info">'.
            h nextPutAll: '<strong>Track:</strong> '; nextPutAll: (self trackLabel: p track); nextPutAll: ' | '.
            h nextPutAll: '<strong>Version:</strong> '; nextPutAll: p version asString; nextPutAll: ' | '.
            h nextPutAll: '<strong>Length:</strong> '; nextPutAll: p content size asString; nextPutAll: ' chars'.
            h nextPutAll: '</div>'.
            h nextPutAll: '<form method="post" onsubmit="return confirmSave(this)">'.
            h nextPutAll: '<input type="hidden" name="track" value="'; nextPutAll: p track asString; nextPutAll: '">'.
            h nextPutAll: '<input type="hidden" name="oldVersion" value="'; nextPutAll: p version asString; nextPutAll: '">'.
            h nextPutAll: '<label><strong>New Version:</strong></label> '.
            h nextPutAll: '<input type="text" name="version" class="version-input" value="'; nextPutAll: (self incrementVersion: p version asString); nextPutAll: '"><br><br>'.
            h nextPutAll: '<textarea name="prompt">'; nextPutAll: (self escapeHtml: p content); nextPutAll: '</textarea>'.
            h nextPutAll: '<br><br>'.
            h nextPutAll: '<button type="submit" class="btn btn-green">Save Prompt</button>'.
            h nextPutAll: '<a href="/" class="btn btn-gray" style="text-decoration:none">Cancel</a>'.
            h nextPutAll: '</form>'.
            h nextPutAll: '</div>' ].
        
        "JavaScript"
        h nextPutAll: '<script>
document.querySelectorAll(".track-tab").forEach(tab => {
    tab.addEventListener("click", () => {
        document.querySelectorAll(".track-tab").forEach(t => t.classList.remove("active"));
        document.querySelectorAll(".track-content").forEach(c => c.classList.remove("active"));
        tab.classList.add("active");
        document.getElementById("track-" + tab.dataset.track).classList.add("active");
    });
});

function confirmSave(form) {
    const track = form.querySelector("[name=track]").value;
    const oldVer = form.querySelector("[name=oldVersion]").value;
    const newVer = form.querySelector("[name=version]").value;
    return confirm("Save prompt for " + track + "?\\n\\nVersion: " + oldVer + " → " + newVer + "\\n\\nThis will update the prompt used for AI assessment.");
}
</script>'.
        h nextPutAll: '</body></html>' ]
]

{ #category : 'as yet unclassified' }
ATWebConsole >> renderRateLimitPage [
    | status config today |
    [ status := ATRepository current getRateLimitStatus ]
        on: Error
        do: [ :e | ^ self renderResultPage: 'Rate Limit' message: 'Error: ', e messageText backLink: '/' ].
    
    config := status at: 'config' ifAbsent: [ Dictionary new ].
    today := status at: 'today' ifAbsent: [ Dictionary new ].
    
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>Rate Limit - AI-Theoretical</title>'.
        h nextPutAll: '<style>body{font-family:sans-serif;max-width:900px;margin:40px auto;padding:20px}'.
        h nextPutAll: '.section{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
        h nextPutAll: '.stats{display:flex;gap:20px;flex-wrap:wrap}'.
        h nextPutAll: '.stat-box{background:white;padding:15px 25px;border-radius:8px;text-align:center;min-width:100px}'.
        h nextPutAll: '.stat-value{font-size:2em;font-weight:bold}'.
        h nextPutAll: '.stat-label{color:#666;font-size:0.9em}'.
        h nextPutAll: '.btn{padding:12px 24px;margin:5px;cursor:pointer;border:none;border-radius:4px;font-size:14px}'.
        h nextPutAll: '.btn-green{background:#4CAF50;color:white}.btn-blue{background:#2196F3;color:white}'.
        h nextPutAll: '.warning{background:#fff3cd;padding:15px;border-radius:8px;border-left:4px solid #ffc107;margin:15px 0}'.
        h nextPutAll: '.success{background:#d4edda;padding:15px;border-radius:8px;border-left:4px solid #28a745;margin:15px 0}'.
        h nextPutAll: 'input[type=number],input[type=email]{padding:10px;width:150px;border:1px solid #ccc;border-radius:4px}'.
        h nextPutAll: 'table{width:100%;border-collapse:collapse}th,td{padding:8px;text-align:left;border-bottom:1px solid #ddd}'.
        h nextPutAll: '</style></head><body>'.
        h nextPutAll: '<h1>⚡ Rate Limiting</h1>'.
        h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
        
        "Status oggi"
        h nextPutAll: '<div class="section">'.
        h nextPutAll: '<h2>Today''s Status</h2>'.
        h nextPutAll: '<div class="stats">'.
        h nextPutAll: '<div class="stat-box"><div class="stat-value">'; 
            nextPutAll: (today at: 'globalCount' ifAbsent: [0]) asString; 
            nextPutAll: '</div><div class="stat-label">Submissions Today</div></div>'.
        h nextPutAll: '<div class="stat-box"><div class="stat-value">'; 
            nextPutAll: (today at: 'remaining' ifAbsent: [0]) asString; 
            nextPutAll: '</div><div class="stat-label">Remaining</div></div>'.
        h nextPutAll: '<div class="stat-box"><div class="stat-value">'; 
            nextPutAll: (today at: 'percentUsed' ifAbsent: ['0']) asString; 
            nextPutAll: '%</div><div class="stat-label">Used</div></div>'.
        h nextPutAll: '<div class="stat-box"><div class="stat-value">'; 
            nextPutAll: (today at: 'uniqueIPs' ifAbsent: [0]) asString; 
            nextPutAll: '</div><div class="stat-label">Unique IPs</div></div>'.
        h nextPutAll: '</div>'.
        
        "Top IPs"
        (today at: 'topIPs' ifAbsent: [#()]) ifNotEmpty: [ :topIPs |
            h nextPutAll: '<h3>Top IPs</h3><table><tr><th>IP</th><th>Count</th></tr>'.
            topIPs do: [ :ipData |
                h nextPutAll: '<tr><td>'; nextPutAll: (ipData at: 'ip' ifAbsent: ['?']); 
                    nextPutAll: '</td><td>'; nextPutAll: (ipData at: 'count' ifAbsent: [0]) asString; 
                    nextPutAll: '</td></tr>' ].
            h nextPutAll: '</table>' ].
        h nextPutAll: '</div>'.
        
        "Configurazione"
        h nextPutAll: '<div class="section">'.
        h nextPutAll: '<h2>Configuration</h2>'.
        h nextPutAll: '<form method="post" action="/rate-limit/config">'.
        h nextPutAll: '<p><label><strong>Daily Limit (global):</strong></label><br>'.
        h nextPutAll: '<input type="number" name="dailyLimit" value="'; 
            nextPutAll: (config at: 'dailyLimit' ifAbsent: [50]) asString; 
            nextPutAll: '" min="1" max="1000"></p>'.
        h nextPutAll: '<p><label><strong>Per-IP Limit:</strong></label><br>'.
        h nextPutAll: '<input type="number" name="ipLimit" value="'; 
            nextPutAll: (config at: 'ipLimit' ifAbsent: [5]) asString; 
            nextPutAll: '" min="1" max="100"></p>'.
        h nextPutAll: '<p><label><strong>Alert Email:</strong></label><br>'.
        h nextPutAll: '<input type="email" name="alertEmail" placeholder="admin@example.com" style="width:300px">'.
        h nextPutAll: ' <small>(leave empty to keep current)</small></p>'.
        h nextPutAll: '<p><label><input type="checkbox" name="enabled" value="true"'.
        (config at: 'enabled' ifAbsent: [true]) ifTrue: [ h nextPutAll: ' checked' ].
        h nextPutAll: '> Rate limiting enabled</label></p>'.
        h nextPutAll: '<button type="submit" class="btn btn-green">Save Configuration</button>'.
        h nextPutAll: '</form>'.
        h nextPutAll: '</div>'.
        
        h nextPutAll: '</body></html>' ]
]

{ #category : 'rendering' }
ATWebConsole >> renderResultPage: title message: message backLink: link [
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>'; nextPutAll: title; nextPutAll: ' - AI-Theoretical</title>'.
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
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>Settings - AI-Theoretical</title>'.
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
    | auto pending papers approvals rateLimiter |
    auto := ATAutomation current.
    pending := ATRepository current pendingSubmissions size.
    papers := ATRepository current papers size.
    approvals := auto pendingApprovals size.
    rateLimiter := ATRateLimiter current.
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
        h nextPutAll: '<p>Rate limit today: <strong>'; 
            nextPutAll: rateLimiter dailyCount asString; 
            nextPutAll: '/'; 
            nextPutAll: rateLimiter dailyLimit asString;
            nextPutAll: '</strong> (';
            nextPutAll: rateLimiter remainingToday asString;
            nextPutAll: ' remaining)</p>'.
        h nextPutAll: '<p>Last check: '; nextPutAll: (auto lastCheck ifNil: [ 'never' ] ifNotNil: [ :d | d asString ]); nextPutAll: '</p>'.
        h nextPutAll: '</div>' ]
]

{ #category : 'as yet unclassified' }
ATWebConsole >> renderUsagePage [
    | tracker summary global resettable |
    tracker := ATUsageTracker current.
    summary := tracker summary.
    global := summary at: #global.
    resettable := summary at: #resettable.
    
    ^ String streamContents: [ :h |
        h nextPutAll: '<!DOCTYPE html><html><head>'.
        h nextPutAll: '<meta charset="UTF-8">'.
        h nextPutAll: '<link rel="icon" type="image/svg+xml" href="https://ai-theoretical.org/favicon.svg">'.
        h nextPutAll: '<title>Token Usage - AI-Theoretical</title>'.
        h nextPutAll: '<style>body{font-family:sans-serif;max-width:1000px;margin:40px auto;padding:20px}'.
        h nextPutAll: '.section{background:#f5f5f5;padding:20px;border-radius:8px;margin:20px 0}'.
        h nextPutAll: '.stats{display:flex;gap:15px;flex-wrap:wrap}'.
        h nextPutAll: '.stat-box{background:white;padding:15px 20px;border-radius:8px;text-align:center;min-width:120px}'.
        h nextPutAll: '.stat-value{font-size:1.8em;font-weight:bold}'.
        h nextPutAll: '.stat-label{color:#666;font-size:0.85em}'.
        h nextPutAll: '.provider-row{display:flex;gap:20px;margin:10px 0;padding:15px;background:white;border-radius:8px}'.
        h nextPutAll: '.provider-name{font-weight:bold;width:100px}'.
        h nextPutAll: '.provider-stat{text-align:right;min-width:100px}'.
        h nextPutAll: '.cost{color:#4CAF50;font-weight:bold}'.
        h nextPutAll: '.btn{padding:12px 24px;margin:5px;cursor:pointer;border:none;border-radius:4px;font-size:14px}'.
        h nextPutAll: '.btn-red{background:#f44336;color:white}'.
        h nextPutAll: '.btn-blue{background:#2196F3;color:white}'.
        h nextPutAll: 'table{width:100%;border-collapse:collapse}th,td{padding:10px;text-align:right;border-bottom:1px solid #ddd}'.
        h nextPutAll: 'th{background:#e0e0e0;text-align:left}td:first-child{text-align:left;font-weight:bold}'.
        h nextPutAll: '</style></head><body>'.
        h nextPutAll: '<h1>📊 Token Usage</h1>'.
        h nextPutAll: '<p><a href="/">← Back to Console</a></p>'.
        
        "Sezione Resettable (periodo corrente)"
        h nextPutAll: '<div class="section">'.
        h nextPutAll: '<h2>Current Period</h2>'.
        h nextPutAll: '<p><strong>Since:</strong> '; nextPutAll: tracker lastReset asString; nextPutAll: '</p>'.
        self renderUsageTable: resettable to: h.
        h nextPutAll: '<br><form method="post" style="display:inline" onsubmit="return confirm(''Reset period counters? Global totals will be preserved.'')">'.
        h nextPutAll: '<button class="btn btn-red" formaction="/usage/reset">Reset Period</button></form>'.
        h nextPutAll: '</div>'.
        
        "Sezione Global (totale storico)"
        h nextPutAll: '<div class="section">'.
        h nextPutAll: '<h2>All Time Totals</h2>'.
        self renderUsageTable: global to: h.
        h nextPutAll: '</div>'.
        
        h nextPutAll: '</body></html>' ]
]

{ #category : 'as yet unclassified' }
ATWebConsole >> renderUsageTable: usageSummary to: h [
    | totals providers |
    totals := usageSummary at: #totals ifAbsent: [ ^ self ].
    providers := usageSummary keys reject: [ :k | k = #totals ].
    
    h nextPutAll: '<table>'.
    h nextPutAll: '<tr><th>Provider</th><th>Calls</th><th>Input Tokens</th><th>Output Tokens</th><th>Est. Cost</th></tr>'.
    
    providers do: [ :prov |
        | data |
        data := usageSummary at: prov.
        h nextPutAll: '<tr>'.
        h nextPutAll: '<td>'; nextPutAll: prov asString; nextPutAll: '</td>'.
        h nextPutAll: '<td>'; nextPutAll: (data at: #calls) asString; nextPutAll: '</td>'.
        h nextPutAll: '<td>'; nextPutAll: (self formatNumber: (data at: #inputTokens)); nextPutAll: '</td>'.
        h nextPutAll: '<td>'; nextPutAll: (self formatNumber: (data at: #outputTokens)); nextPutAll: '</td>'.
        h nextPutAll: '<td class="cost">$'; nextPutAll: ((data at: #estimatedCost) printShowingDecimalPlaces: 4); nextPutAll: '</td>'.
        h nextPutAll: '</tr>' ].
    
    "Riga totali"
    h nextPutAll: '<tr style="font-weight:bold;background:#e8f5e9">'.
    h nextPutAll: '<td>TOTAL</td>'.
    h nextPutAll: '<td>'; nextPutAll: (totals at: #calls) asString; nextPutAll: '</td>'.
    h nextPutAll: '<td>'; nextPutAll: (self formatNumber: (totals at: #inputTokens)); nextPutAll: '</td>'.
    h nextPutAll: '<td>'; nextPutAll: (self formatNumber: (totals at: #outputTokens)); nextPutAll: '</td>'.
    h nextPutAll: '<td class="cost">$'; nextPutAll: ((totals at: #estimatedCost) printShowingDecimalPlaces: 4); nextPutAll: '</td>'.
    h nextPutAll: '</tr>'.
    
    h nextPutAll: '</table>'
]

{ #category : 'control' }
ATWebConsole >> restart [
	"Riavvia la console ricaricando le route"
	self stop.
	teapot := nil.
	self start
]

{ #category : 'initialization' }
ATWebConsole >> setupRoutes [
    teapot
        "Main pages"
        GET: '/' -> [ :req | self renderPage ];
        GET: '/settings' -> [ :req | self renderSettingsPage ];
        GET: '/prompt' -> [ :req | self renderPromptPage ];
        GET: '/ai' -> [ :req | self renderAIConfigPage ];
        GET: '/audit' -> [ :req | self renderAuditLogPage ];
        GET: '/rate-limit' -> [ :req | self renderRateLimitPage ];
        GET: '/usage' -> [ :req | self renderUsagePage ];
        
        "Automation controls"
        POST: '/start' -> [ :req | ATAutomation current start. self redirectToRoot ];
        POST: '/stop' -> [ :req | ATAutomation current stop. self redirectToRoot ];
        POST: '/sync' -> [ :req | ATRepository current syncSubmissions. self redirectToRoot ];
        POST: '/deploy' -> [ :req | ATRepository current deploy. self redirectToRoot ];
        POST: '/mode/full' -> [ :req | ATAutomation current fullAuto. self redirectToRoot ];
        POST: '/mode/semi' -> [ :req | ATAutomation current semiAuto. self redirectToRoot ];
        
        "Submission processing - con hidden field"
        POST: '/do-process' -> [ :req | self handleDoProcess: req ];
        POST: '/do-delete' -> [ :req | self handleDoDelete: req ];
        
        "Approval actions - con hidden field"
        POST: '/do-approve' -> [ :req | self handleDoApprove: req ];
        POST: '/do-reject' -> [ :req | self handleDoReject: req ];
        POST: '/do-regenerate' -> [ :req | self handleDoRegenerate: req ];
        POST: '/approve-all' -> [ :req | ATAutomation current approveAllPending. ATRepository current deploy. self redirectToRoot ];
        
        "Paper management - usa POST body"
        POST: '/paper/delete' -> [ :req | self handleDeletePaper: req ];
        
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
        
        "Rate Limit"
        POST: '/rate-limit/config' -> [ :req | self handleRateLimitConfig: req ];
        
        "Audit Log"
        POST: '/audit/clear' -> [ :req | self handleAuditClear ];
        
        "Usage Tracker"
        POST: '/usage/reset' -> [ :req | ATUsageTracker current resetCounters. self redirectTo: '/usage' ];
        
        "Update API (chiamate dal Worker)"
        POST: '/api/update-request' -> [ :req | self handleUpdateRequest: req ];
        POST: '/api/validate-update-token' -> [ :req | self handleValidateUpdateToken: req ];
        POST: '/api/withdraw-paper' -> [ :req | self handleWithdrawPaper: req ];
        POST: '/api/prepare-version-update' -> [ :req | self handlePrepareVersionUpdate: req ];
        POST: '/api/upload-new-version' -> [ :req | self handleUploadNewVersion: req ];
        
        "Notifiche dal Worker per author-access"
        POST: '/api/notify-withdraw' -> [ :req | self handleNotifyWithdraw: req ];
        POST: '/api/notify-new-version' -> [ :req | self handleNotifyNewVersion: req ];
        
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

{ #category : 'as yet unclassified' }
ATWebConsole >> trackLabel: aSymbol [
    aSymbol = #researchPreprint ifTrue: [ ^ 'Research Preprint' ].
    aSymbol = #workingPaper ifTrue: [ ^ 'Working Paper' ].
    aSymbol = #expositoryEssay ifTrue: [ ^ 'Expository Essay' ].
    aSymbol = #criticalReview ifTrue: [ ^ 'Critical Review' ].
    ^ aSymbol asString
]

{ #category : 'accessing' }
ATWebConsole >> tunnelProcess [
	^ tunnelProcess
]

{ #category : 'actions' }
ATWebConsole >> updatePrompt: aRequest [
    | formData track newPrompt version prompt |
    formData := aRequest entity.
    track := (formData at: 'track' ifAbsent: [ 'workingPaper' ]) asSymbol.
    newPrompt := (formData at: 'prompt' ifAbsent: [ '' ]).
    version := (formData at: 'version' ifAbsent: [ '1.0' ]).
    
    "Aggiorna il prompt nel registry"
    prompt := ATPromptRegistry current activePromptForTrack: track.
    prompt ifNotNil: [
        prompt content: newPrompt.
        prompt version: version ].
    
    "Rigenera ai-prompt.js per il sito pubblico"
    self regeneratePublicPromptJs.
    
    "Redirect back"
    ^ ZnResponse redirect: '/prompt'
]
