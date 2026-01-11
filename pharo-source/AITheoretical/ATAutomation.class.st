Class {
	#name : 'ATAutomation',
	#superclass : 'Object',
	#instVars : [
		'assessmentGenerator',
		'pollingProcess',
		'pollingInterval',
		'lastCheck',
		'emailSender',
		'mode',
		'pendingApprovals',
		'processedIds',
		'operatingMode'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATAutomation class >> current [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'orchestration' }
ATAutomation class >> delegateTo: aProvider withApiKey: aKey prompt: aPrompt [
    "Delega un task a un LLM esterno via OpenAI-Pharo/ChatPharo e ritorna il risultato"
    | sdk session response |
    
    aProvider = #openai ifTrue: [
        sdk := OpenAISDK createWithAPIKey: aKey.
        session := OpenAIChatSession startWithSDK: sdk model: 'gpt-4o' temperature: 0.
        session submitUserPrompt: aPrompt.
        ^ session lastChat content ].
    
    "Per altri provider, usa ATAssessmentGenerator"
    ^ (ATAssessmentGenerator perform: aProvider asSymbol with: aKey)
        assessPaper: aPrompt
]

{ #category : 'orchestration' }
ATAutomation class >> generateMethod: methodDescription forClass: aClassName usingProvider: aProvider apiKey: aKey [
    "Genera un metodo Smalltalk completo e ritorna il source code"
    | prompt classSource lf |
    lf := String lf.
    
    "Ottieni contesto della classe"
    classSource := (Smalltalk at: aClassName asSymbol ifAbsent: [nil])
        ifNotNil: [:cls | cls definitionString]
        ifNil: ['Class not found'].
    
    prompt := 'You are a Pharo Smalltalk expert. Generate a single method for class ', aClassName, '.' , lf ,
        'Class definition: ' , classSource , lf , lf ,
        'Method description: ' , methodDescription , lf , lf ,
        'Output ONLY the method source code (selector and body), nothing else.
IMPORTANT: Never use literal linefeeds in strings - use String lf or Character lf instead.
Use proper Smalltalk conventions.'.
    
    ^ self delegateTo: aProvider withApiKey: aKey prompt: prompt
]

{ #category : 'orchestration' }
ATAutomation class >> generateSmalltalkCode: taskDescription usingProvider: aProvider apiKey: aKey [
    "Genera codice Smalltalk delegando a un LLM esterno.
     Ritorna solo il codice, senza spiegazioni."
    | prompt |
    prompt := 'You are a Pharo Smalltalk expert. Generate ONLY valid Pharo Smalltalk code for the following task.
Do not include explanations, just the code.
IMPORTANT: Never use literal linefeeds in strings - use String lf or Character lf instead.

Task: ', taskDescription.
    ^ self delegateTo: aProvider withApiKey: aKey prompt: prompt
]

{ #category : 'class initialization' }
ATAutomation class >> initialize [
	"Al caricamento della classe, registra startup action"
	SessionManager default
		registerUserClassNamed: self name
]

{ #category : 'configuration' }
ATAutomation class >> loadApiKeyFromConfig [
    "Carica la API key Anthropic dal file di configurazione Dropbox"
    | configPaths key |
    configPaths := #(
        '/Users/Franco/Dropbox/ai-theoretical.org/config/anthropic_api_key.txt'
    ).
    
    configPaths do: [ :path |
        path asFileReference exists ifTrue: [
            key := path asFileReference contents trim.
            key ifNotEmpty: [ 
                ATAutomation current assessmentGenerator: (ATAssessmentGenerator anthropic: key).
                ^ key size asString , ' chars loaded from ' , path ]]].
    
    ^ 'No API key file found'
]

{ #category : 'orchestration' }
ATAutomation class >> orchestrateTask: taskDescription [
    "Metodo principale per orchestrazione - usa la config esistente se disponibile"
    | gen prompt |
    
    "Prova prima il generator configurato"
    gen := ATAutomation current assessmentGenerator.
    gen ifNil: [ 
        self error: 'No AI provider configured. Use ATAutomation current assessmentGenerator: (ATAssessmentGenerator anthropic: yourKey)' ].
    
    prompt := 'You are a Pharo Smalltalk expert. Generate ONLY valid Pharo code.
Do not include explanations, just the code.
IMPORTANT: Never use literal linefeeds in strings - use String lf instead.

Task: ', taskDescription.
    
    ^ gen assessPaper: prompt
]

{ #category : 'accessing' }
ATAutomation class >> reset [
	Current ifNotNil: [ Current stop ].
	Current := nil
]

{ #category : 'system startup' }
ATAutomation class >> shutDown: quitting [
	"Chiamato alla chiusura"
	quitting ifTrue: [
		self current stop ]
]

{ #category : 'system startup' }
ATAutomation class >> startUp: resuming [
	"Chiamato al riavvio dell'immagine"
	resuming ifTrue: [
		self current loadDefaultConfiguration ]
]

{ #category : 'manual' }
ATAutomation >> approveAllPending [
	"Approva tutte le pending approval con verdict #accept"
	| toApprove |
	toApprove := self pendingApprovals select: [ :p | p verdict = #accept ].
	toApprove do: [ :p | self approvePending: p ]
]

{ #category : 'actions' }
ATAutomation >> approvePending: aPendingApproval [
	"Approva manualmente una pending approval"
	| result |
	result := self executeDecision: #accept
		forSubmission: aPendingApproval submission
		withAssessment: aPendingApproval assessment.
	pendingApprovals remove: aPendingApproval ifAbsent: [].
	processedIds remove: aPendingApproval submission id ifAbsent: [].
	^ result
]

{ #category : 'accessing' }
ATAutomation >> assessmentGenerator [
	^ assessmentGenerator
]

{ #category : 'accessing' }
ATAutomation >> assessmentGenerator: anATAssessmentGenerator [
	assessmentGenerator := anATAssessmentGenerator
]

{ #category : 'processing' }
ATAutomation >> checkAndProcess [
	"Sync, processa tutte le pending, deploy se necessario"
	| pending accepted |
	ATRepository current syncSubmissions.
	pending := ATRepository current pendingSubmissions.
	pending ifEmpty: [ ^ self ].
	accepted := false.
	pending do: [ :sub |
		(self processSubmission: sub) = #accepted ifTrue: [ accepted := true ] ].
	accepted ifTrue: [ ATRepository current deploy ].
	lastCheck := DateAndTime now
]

{ #category : 'test cleanup' }
ATAutomation >> deleteAllTestData [
    "Elimina tutte le submission e paper di test"
    | testSubmissions testPapers testLogPath |
    
    "Rimuovi submission di test"
    testSubmissions := ATRepository current submissions select: [ :s | s isTest ].
    testSubmissions do: [ :s | ATRepository current submissions remove: s ifAbsent: [] ].
    
    "Rimuovi paper di test"
    testPapers := ATRepository current papers select: [ :p | p isTest ].
    testPapers do: [ :p | ATRepository current papers remove: p ifAbsent: [] ].
    
    "Rimuovi pending approvals di test"
    pendingApprovals removeAllSuchThat: [ :pa | pa submission isTest ].
    
    "Rimuovi rejected di test"
    ATRejectedRepository current rejectedSubmissions 
        removeAllSuchThat: [ :r | r id beginsWith: 'test-' ].
    
    "Svuota log di test"
    testLogPath := ATAuditLog current logFilePath asFileReference parent / 'audit_test.log'.
    testLogPath exists ifTrue: [ testLogPath delete ].
    
    ^ 'Deleted: ', testSubmissions size asString, ' submissions, ', 
      testPapers size asString, ' papers, test log cleared'
]

{ #category : 'accessing' }
ATAutomation >> emailSender [
	^ emailSender
]

{ #category : 'accessing' }
ATAutomation >> emailSender: anATEmailSender [
	emailSender := anATEmailSender
]

{ #category : 'processing' }
ATAutomation >> executeDecision: verdict forSubmission: aSubmission withAssessment: assessment [
    "Esegue accept/reject/review per una submission"
    | collaboration notes |
    collaboration := aSubmission aiModels ifNil: [ '' ].
    notes := aSubmission notes ifNil: [ '' ].
    
    verdict = #accept ifTrue: [
        ATRepository current
            acceptRemoteSubmission: aSubmission
            withAssessment: assessment
            withCollaboration: collaboration
            withNotes: notes.
        emailSender ifNotNil: [
            emailSender sendAcceptanceTo: aSubmission withAssessment: assessment ].
        ATAuditLog current logDecision: #accept forSubmission: aSubmission.
        ^ #accepted ].
    
    "reject e review sono entrambi rifiuti, ma con email diverse"
    (verdict = #reject or: [ verdict = #review ]) ifTrue: [
        ATRepository current rejectRemoteSubmission: aSubmission.
        emailSender ifNotNil: [
            verdict = #review 
                ifTrue: [ emailSender sendRevisionRequestTo: aSubmission withAssessment: assessment ]
                ifFalse: [ emailSender sendRejectionTo: aSubmission withAssessment: assessment ] ].
        ATAuditLog current logDecision: verdict forSubmission: aSubmission.
        ^ #rejected ].
    
    "Non dovrebbe mai arrivare qui"
    self error: 'executeDecision called with invalid verdict: ', verdict asString
]

{ #category : 'configuration' }
ATAutomation >> fullAuto [
	self mode: #fullAuto
]

{ #category : 'initialization' }
ATAutomation >> initialize [
    super initialize.
    mode := #semiAuto.
    pollingInterval := 300. "5 minuti default"
    pendingApprovals := OrderedCollection new.
    processedIds := Set new
]

{ #category : 'testing' }
ATAutomation >> isProduction [ ^ self operatingMode = #production
]

{ #category : 'testing' }
ATAutomation >> isRunning [
	^ pollingProcess notNil and: [ pollingProcess isTerminated not ]
]

{ #category : 'testing' }
ATAutomation >> isSimulatedMode [ ^ self operatingMode = #testSimulatedAI
]

{ #category : 'testing' }
ATAutomation >> isTestMode [ ^ self operatingMode ~= #production
]

{ #category : 'accessing' }
ATAutomation >> lastCheck [
	^ lastCheck
]

{ #category : 'configuration' }
ATAutomation >> loadDefaultConfiguration [
	"Carica configurazione completa"
	| path data provider model configPaths |
	
	"Cerca il file config in posizioni note"
	configPaths := #(
		'/Users/Franco/Dropbox/ai-theoretical.org/secrets/ai-config.json'
	).
	
	path := configPaths detect: [:p | p asFileReference exists] ifNone: [nil].
	path ifNil: [ ^ self ].
	
	data := NeoJSONReader fromString: path asFileReference contents.
	
	"Carica gitRepoPath prima di tutto"
	(data at: 'gitRepoPath' ifAbsent: [nil]) ifNotNil: [:p | 
		ATRepository current gitRepoPath: p ].
	
	"Carica mode"
	(data at: 'mode' ifAbsent: [nil]) ifNotNil: [:m | 
		mode := m asSymbol ].
	
	"Carica apiToken"
	(data at: 'apiToken' ifAbsent: [nil]) ifNotNil: [:t | 
		ATRepository current apiToken: t ].
	
	"Carica emailSender (usa apiToken)"
	(data at: 'emailEnabled' ifAbsent: [false]) ifTrue: [
		ATRepository current apiToken ifNotNil: [:t |
			emailSender := ATEmailSender withApiKey: t ]].
	
	"Carica pollingInterval"
	(data at: 'pollingInterval' ifAbsent: [nil]) ifNotNil: [:pi |
		pollingInterval := pi ].
	
	"Carica processedIds"
	(data at: 'processedIds' ifAbsent: [nil]) ifNotNil: [:ids |
		processedIds := ids asSet ].
	
	"Carica pendingApprovals"
	(data at: 'pendingApprovals' ifAbsent: [nil]) ifNotNil: [:approvals |
		self loadPendingApprovals: approvals ].
	
	"Carica config AI"
	provider := data at: 'provider' ifAbsent: [ #google ].
	model := data at: 'model' ifAbsent: [ 'gemini-3-flash-preview' ].
	(data at: 'useOAuth' ifAbsent: [ true ]) ifTrue: [
		| auth |
		auth := ATGoogleAuth current.
		auth load.
		auth isAuthenticated ifTrue: [
			assessmentGenerator := ATAssessmentGenerator googleWithOAuth.
			assessmentGenerator model: model.
			^ self ] ].
	
	"Fallback: prova OAuth Google"
	ATGoogleAuth current load.
	ATGoogleAuth current isAuthenticated ifTrue: [
		assessmentGenerator := ATAssessmentGenerator googleWithOAuth.
		assessmentGenerator model: 'gemini-3-flash-preview' ]
]

{ #category : 'configuration' }
ATAutomation >> loadPendingApprovals: approvalsData [
	"Ricostruisce pending approvals dai dati salvati"
	pendingApprovals := OrderedCollection new.
	approvalsData do: [:paData |
		| submission pa |
		"Cerca la submission nel repository"
		submission := ATRepository current submissions 
			detect: [:s | s id = (paData at: 'submissionId')] 
			ifNone: [nil].
		submission ifNotNil: [
			pa := ATPendingApproval new.
			pa submission: submission.
			pa assessment: (paData at: 'assessment').
			pa verdict: (paData at: 'verdict') asSymbol.
			pendingApprovals add: pa ]]
]

{ #category : 'accessing' }
ATAutomation >> mode [
	^ mode ifNil: [ #fullAuto ]
]

{ #category : 'accessing' }
ATAutomation >> mode: aSymbol [
	"#fullAuto o #semiAuto - salva automaticamente"
	| oldMode |
	oldMode := mode.
	mode := aSymbol.
	
	"Log il cambio di mode"
	(oldMode notNil and: [oldMode ~= aSymbol]) ifTrue: [
		ATAuditLog current logEntry: (Dictionary new
			at: 'type' put: 'mode_change';
			at: 'timestamp' put: DateAndTime now asString;
			at: 'oldMode' put: oldMode asString;
			at: 'newMode' put: aSymbol asString;
			yourself).
		"Salva configurazione"
		self saveConfiguration ]
]

{ #category : 'accessing' }
ATAutomation >> operatingMode [ 
    ^ operatingMode ifNil: [ #production ]
]

{ #category : 'accessing' }
ATAutomation >> operatingMode: aSymbol [ 
    "Modes: #production, #testLiveAI, #testSimulatedAI"
    operatingMode := aSymbol
]

{ #category : 'as yet unclassified' }
ATAutomation >> parseAuthors: assessmentText [
    "Estrae la lista degli autori dal criterio 17 dell'assessment.
     Ritorna un array di stringhe con i nomi, o array vuoto se non trovato."
    | lines authorsLine jsonStart jsonEnd jsonString |
    
    (assessmentText isNil or: [ assessmentText isEmpty ]) ifTrue: [ ^ #() ].
    
    lines := assessmentText lines.
    authorsLine := lines 
        detect: [ :l | l includesSubstring: 'Authors list:' ] 
        ifNone: [ ^ #() ].
    
    "Cerco il JSON array nella riga"
    jsonStart := authorsLine indexOf: $[.
    jsonEnd := authorsLine lastIndexOf: $].
    
    (jsonStart = 0 or: [ jsonEnd = 0 or: [ jsonEnd < jsonStart ] ]) ifTrue: [ ^ #() ].
    
    jsonString := authorsLine copyFrom: jsonStart to: jsonEnd.
    
    "Parse JSON"
    [ ^ NeoJSONReader fromString: jsonString ]
        on: Error
        do: [ :e | ^ #() ]
]

{ #category : 'private' }
ATAutomation >> parseVerdict: assessmentText [
    "Estrae il verdict dall'assessment. 
     Ritorna #accept, #reject, #review (decisioni valide) oppure #aiFailure se non riconosciuto"
    | lines outcomeLine |
    
    "Assessment vuoto o nil = failure"
    (assessmentText isNil or: [ assessmentText isEmpty ]) ifTrue: [ ^ #aiFailure ].
    
    lines := assessmentText lines.
    outcomeLine := lines 
        detect: [ :l | l includesSubstring: 'Editorial outcome:' ] 
        ifNone: [ ^ #aiFailure ].  "Nessuna riga outcome = failure"
    
    (outcomeLine includesSubstring: 'Suitable for inclusion') ifTrue: [ ^ #accept ].
    (outcomeLine includesSubstring: 'Not suitable') ifTrue: [ ^ #reject ].
    (outcomeLine includesSubstring: 'Potentially suitable') ifTrue: [ ^ #review ].
    (outcomeLine includesSubstring: 'with revision') ifTrue: [ ^ #review ].
    (outcomeLine includesSubstring: 'Needs revision') ifTrue: [ ^ #review ].
    
    "Outcome presente ma non riconosciuto = failure"
    ^ #aiFailure
]

{ #category : 'accessing' }
ATAutomation >> pendingApprovals [
	^ pendingApprovals ifNil: [ pendingApprovals := OrderedCollection new ]
]

{ #category : 'accessing' }
ATAutomation >> pollingInterval [
    ^ pollingInterval ifNil: [ pollingInterval := 300 ]
]

{ #category : 'accessing' }
ATAutomation >> pollingInterval: seconds [
	pollingInterval := seconds
]

{ #category : 'processing' }
ATAutomation >> processSubmission: aSubmission [
    "Processa una submission: genera assessment, decide in base alla modalità"
    | assessment verdict config prompt |
    
    "Già processata? Esci subito"
    (processedIds includes: aSubmission id) ifTrue: [ ^ #alreadyProcessed ].
    
    "Rate limit check"
    ATRateLimiter current canAcceptSubmission ifFalse: [
        ATAuditLog current logError: 'Daily rate limit exceeded' forSubmission: aSubmission.
        ^ #rateLimitExceeded ].
    
    "Riserva subito per evitare doppi processing"
    processedIds add: aSubmission id.
    ATRateLimiter current registerSubmission.
    
    "In test mode, marca la submission"
    self isTestMode ifTrue: [ aSubmission markAsTest ].
    
    "Genera assessment - simulato o reale"
    [ 
        self isSimulatedMode ifTrue: [
            assessment := self simulatedAssessmentForVerdict: #review.
            aSubmission promptVersion: 'simulated'.
        ] ifFalse: [
            "Usa AI reale"
            assessmentGenerator ifNil: [ self error: 'No assessment generator configured' ].
            
            "Ottieni prompt dal registry"
            prompt := ATPromptRegistry current activePromptForTrack: aSubmission track.
            prompt ifNotNil: [
                assessmentGenerator editorialPrompt: prompt content.
                aSubmission promptVersion: aSubmission track asString, ' v', prompt version ].
            
            assessment := assessmentGenerator assessSubmission: aSubmission ].
    ] on: Error do: [ :e |
        "Errore -> rimuovi da processedIds per permettere retry"
        processedIds remove: aSubmission id ifAbsent: [].
        ATAuditLog current logError: e messageText forSubmission: aSubmission.
        self error: e messageText ].
    
    "Parse verdict"
    verdict := self parseVerdict: assessment.
    
    config := assessmentGenerator 
        ifNotNil: [ assessmentGenerator configurationDictionary ]
        ifNil: [ Dictionary new at: 'mode' put: 'simulated'; yourself ].
    
    "Log"
    self isTestMode 
        ifTrue: [ ATAuditLog current logTestAssessment: aSubmission verdict: verdict assessment: assessment ]
        ifFalse: [ ATAuditLog current logAssessment: aSubmission verdict: verdict assessment: assessment config: config ].
    
    "SEMI-AUTO: tutto va in pending per decisione manuale"
    mode = #semiAuto ifTrue: [
        pendingApprovals add: (ATPendingApproval
            submission: aSubmission
            assessment: assessment
            verdict: verdict).
        ^ #pendingApproval ].
    
    "FULL-AUTO: aiFailure va in pending, tutto il resto viene eseguito"
    verdict = #aiFailure ifTrue: [
        ATAuditLog current logError: 'AI failure, requires manual review' forSubmission: aSubmission.
        pendingApprovals add: (ATPendingApproval
            submission: aSubmission
            assessment: assessment
            verdict: verdict).
        ^ #pendingApproval ].
    
    "accept/reject/review -> esegui"
    ^ self executeDecision: verdict forSubmission: aSubmission withAssessment: assessment
]

{ #category : 'as yet unclassified' }
ATAutomation >> regenerateAssessmentAtIndex: anIndex [
    "Rigenera l'assessment per un item pending"
    | pending newAssessment newVerdict |
    (anIndex < 1 or: [ anIndex > pendingApprovals size ]) ifTrue: [ ^ nil ].
    
    pending := pendingApprovals at: anIndex.
    
    assessmentGenerator ifNil: [ ^ self error: 'No assessment generator configured' ].
    
    [ newAssessment := assessmentGenerator assessSubmission: pending submission ]
        on: Error
        do: [ :e | 
            newAssessment := 'AI ERROR: ', e messageText.
            ATAuditLog current logError: 'Regenerate failed: ', e messageText forSubmission: pending submission ].
    
    newVerdict := self parseVerdict: newAssessment.
    
    "Aggiorna il pending"
    pending assessment: newAssessment.
    pending verdict: newVerdict.
    
    ATAuditLog current logAssessment: pending submission 
        verdict: newVerdict 
        assessment: newAssessment 
        config: (assessmentGenerator configurationDictionary 
            at: 'note' put: 'regenerated'; yourself).
    
    ^ newVerdict
]

{ #category : 'manual actions' }
ATAutomation >> rejectPending: aPendingApproval [
    "Rifiuta manualmente una pending approval, archivia con PDF"
    | result rejected pdfPath |
    
    "Scarica PDF prima di tutto"
    pdfPath := ATRejectedRepository current 
        downloadPdf: aPendingApproval submission id.
    
    "Archivia"
    rejected := ATRejectedSubmission fromPendingApproval: aPendingApproval.
    rejected localPdfPath: pdfPath.
    ATRejectedRepository current add: rejected.
    
    "Esegui rejection"
    result := self executeDecision: #reject
        forSubmission: aPendingApproval submission
        withAssessment: aPendingApproval assessment.
    pendingApprovals remove: aPendingApproval ifAbsent: [].
    processedIds remove: aPendingApproval submission id ifAbsent: [].
    ^ result
]

{ #category : 'configuration' }
ATAutomation >> saveConfiguration [
	"Salva configurazione completa su file"
	| data path repoPath |
	repoPath := ATRepository current gitRepoPath.
	(repoPath isNil or: [repoPath = '/path/to/repo']) ifTrue: [ ^ self ].
	
	data := Dictionary new.
	
	"Core config"
	data at: 'mode' put: mode asString.
	data at: 'gitRepoPath' put: repoPath.
	ATRepository current apiToken ifNotNil: [:t | data at: 'apiToken' put: t ].
	
	"AI config"
	assessmentGenerator ifNotNil: [
		data at: 'provider' put: assessmentGenerator provider.
		data at: 'model' put: assessmentGenerator model.
		data at: 'useOAuth' put: (assessmentGenerator provider = #google) ].
	
	"Email sender config"
	emailSender ifNotNil: [
		data at: 'emailEnabled' put: true ].
	
	"Polling interval"
	pollingInterval ifNotNil: [
		data at: 'pollingInterval' put: pollingInterval ].
	
	"Processed IDs (per evitare doppio processing)"
	processedIds ifNotNil: [
		data at: 'processedIds' put: processedIds asArray ].
	
	"Pending approvals"
	(pendingApprovals notNil and: [pendingApprovals notEmpty]) ifTrue: [
		data at: 'pendingApprovals' put: (pendingApprovals collect: [:pa |
			Dictionary new
				at: 'submissionId' put: pa submission id;
				at: 'assessment' put: pa assessment;
				at: 'verdict' put: pa verdict asString;
				yourself ]) asArray ].
	
	path := repoPath, '/secrets/ai-config.json'.
	path asFileReference parent ensureCreateDirectory.
	path asFileReference writeStreamDo: [ :s |
		s nextPutAll: (NeoJSONWriter toStringPretty: data) ]
]

{ #category : 'configuration' }
ATAutomation >> semiAuto [
	self mode: #semiAuto
]

{ #category : 'simulation' }
ATAutomation >> simulatedAssessmentForVerdict: aVerdict [
    "Ritorna un assessment simulato per testing"
    | lf |
    lf := String lf.
    aVerdict = #accept ifTrue: [
        ^ '1) Category: Research preprint', lf,
          '2) Aims: Test submission aims', lf,
          '3) Correctness: No errors identified', lf,
          '4) Coherence: Adequate', lf,
          '5) Consistency: Consistent', lf,
          '6) Semantic opacity: Low (Transparent)', lf,
          '7) Novelty: Original', lf,
          '8) Bibliography: Adequate', lf,
          '9) Effectiveness: Achieves aims', lf,
          '10) Cross-framework traction: High', lf,
          '11) Claims: Supported', lf,
          '12) Contribution: Substantive', lf,
          '13) Structure: Adequate', lf,
          '14) Integrity: No issues', lf,
          '15) Code: Not provided', lf,
          '16) Editorial outcome: Suitable for inclusion', lf, lf,
          '[SIMULATED] This is a test assessment for acceptance flow testing.' ].
    
    aVerdict = #reject ifTrue: [
        ^ '1) Category: Not a fit', lf,
          '2) Aims: Unclear aims', lf,
          '3) Correctness: Undermining errors', lf,
          '4) Coherence: Major issues', lf,
          '5) Consistency: Major drift', lf,
          '6) Semantic opacity: High (Obfuscatory)', lf,
          '7) Novelty: Consolidative', lf,
          '8) Bibliography: Absent', lf,
          '9) Effectiveness: Fails to achieve aims', lf,
          '10) Cross-framework traction: Low', lf,
          '11) Claims: Unsupported assertions', lf,
          '12) Contribution: Absent', lf,
          '13) Structure: Inadequate', lf,
          '14) Integrity: No issues', lf,
          '15) Code: Not provided', lf,
          '16) Editorial outcome: Not suitable for this platform', lf, lf,
          '[SIMULATED] This is a test assessment for rejection flow testing.' ].
    
    "Default: review"
    ^ '1) Category: Research preprint', lf,
      '2) Aims: Test aims', lf,
      '3) Correctness: Minor local issues', lf,
      '4) Coherence: Minor issues', lf,
      '5) Consistency: Consistent', lf,
      '6) Semantic opacity: Moderate', lf,
      '7) Novelty: Reformulative', lf,
      '8) Bibliography: Incomplete', lf,
      '9) Effectiveness: Partially achieves aims', lf,
      '10) Cross-framework traction: Medium', lf,
      '11) Claims: Partially supported', lf,
      '12) Contribution: Marginal', lf,
      '13) Structure: Minor issues', lf,
      '14) Integrity: No issues', lf,
      '15) Code: Not provided', lf,
      '16) Editorial outcome: Potentially suitable with revision', lf, lf,
      '[SIMULATED] This is a test assessment for revision flow testing.'
]

{ #category : 'control' }
ATAutomation >> start [
	"Avvia il polling loop"
	self stop.
	pollingProcess := [
		[ true ] whileTrue: [
			[ self checkAndProcess ]
				on: Error
				do: [ :e | Transcript show: 'ATAutomation error: ', e messageText; cr ].
			(Delay forSeconds: pollingInterval) wait ]
	] fork.
	pollingProcess name: 'ATAutomation polling'
]

{ #category : 'control' }
ATAutomation >> stop [
	"Ferma il polling loop"
	pollingProcess ifNotNil: [
		pollingProcess terminate.
		pollingProcess := nil ]
]
