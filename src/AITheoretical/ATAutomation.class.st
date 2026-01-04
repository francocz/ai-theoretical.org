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

{ #category : 'class initialization' }
ATAutomation class >> initialize [
	"Al caricamento della classe, registra startup action"
	SessionManager default
		registerUserClassNamed: self name
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
	"Esegue accept/reject per una submission"
	| collaboration notes result |
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
	
	verdict = #reject ifTrue: [
		ATRepository current rejectRemoteSubmission: aSubmission.
		emailSender ifNotNil: [
			emailSender sendRejectionTo: aSubmission withAssessment: assessment ].
		ATAuditLog current logDecision: #reject forSubmission: aSubmission.
		^ #rejected ].
	
	ATAuditLog current logDecision: #review forSubmission: aSubmission.
	^ #review
]

{ #category : 'configuration' }
ATAutomation >> fullAuto [
	mode := #fullAuto
]

{ #category : 'initialization' }
ATAutomation >> initialize [
	super initialize.
	mode := #semiAuto.
	pendingApprovals := OrderedCollection new.
	processedIds := Set new.
	isRunning := false
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
	"Carica configurazione salvata o default"
	| path data provider model |
	path := ATRepository current gitRepoPath, '/secrets/ai-config.json'.
	path asFileReference exists ifTrue: [
		data := NeoJSONReader fromString: path asFileReference contents.
		provider := data at: 'provider' ifAbsent: [ #google ].
		model := data at: 'model' ifAbsent: [ 'gemini-3-flash-preview' ].
		(data at: 'useOAuth' ifAbsent: [ true ]) ifTrue: [
			| auth |
			auth := ATGoogleAuth current.
			auth load.
			auth isAuthenticated ifTrue: [
				assessmentGenerator := ATAssessmentGenerator googleWithOAuth.
				assessmentGenerator model: model.
				^ self ] ] ].
	"Fallback: prova OAuth Google"
	ATGoogleAuth current load.
	ATGoogleAuth current isAuthenticated ifTrue: [
		assessmentGenerator := ATAssessmentGenerator googleWithOAuth.
		assessmentGenerator model: 'gemini-3-flash-preview' ]
]

{ #category : 'accessing' }
ATAutomation >> mode [
	^ mode ifNil: [ #fullAuto ]
]

{ #category : 'accessing' }
ATAutomation >> mode: aSymbol [
	"#fullAuto o #semiAuto"
	mode := aSymbol
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

{ #category : 'parsing' }
ATAutomation >> parseVerdict: assessmentText [
	"Estrae il verdict dall'assessment. Ritorna #accept, #reject o #review"
	| lines outcomeLine |
	lines := assessmentText lines.
	outcomeLine := lines detect: [ :l | l includesSubstring: 'Editorial outcome:' ] ifNone: [ ^ #review ].
	(outcomeLine includesSubstring: 'Suitable for inclusion') ifTrue: [ ^ #accept ].
	(outcomeLine includesSubstring: 'Not suitable') ifTrue: [ ^ #reject ].
	(outcomeLine includesSubstring: 'Needs revision') ifTrue: [ ^ #reject ].
	^ #review
]

{ #category : 'accessing' }
ATAutomation >> pendingApprovals [
	^ pendingApprovals ifNil: [ pendingApprovals := OrderedCollection new ]
]

{ #category : 'accessing' }
ATAutomation >> pollingInterval: seconds [
	pollingInterval := seconds
]

{ #category : 'processing' }
ATAutomation >> processSubmission: aSubmission [
    "Processa una submission: genera assessment, decide in base alla modalità"
    | assessment verdict config prompt |
    
    "Già processata?"
    (processedIds includes: aSubmission id) ifTrue: [ ^ #alreadyProcessed ].
    
    "In test mode, marca la submission"
    self isTestMode ifTrue: [ aSubmission markAsTest ].
    
    "Genera assessment - simulato o reale"
    self isSimulatedMode ifTrue: [
        "Usa assessment simulato"
        assessment := self simulatedAssessmentForVerdict: #review.
        aSubmission promptVersion: 'simulated'.
    ] ifFalse: [
        "Usa AI reale"
        assessmentGenerator ifNil: [ ^ self error: 'No assessment generator configured' ].
        
        "Ottieni prompt dal registry"
        prompt := ATPromptRegistry current activePromptForTrack: aSubmission track.
        prompt ifNotNil: [
            assessmentGenerator editorialPrompt: prompt content.
            aSubmission promptVersion: aSubmission track asString, ' v', prompt version ].
        
        [ assessment := assessmentGenerator assessSubmission: aSubmission ]
            on: Error
            do: [ :e | 
                ATAuditLog current logError: e messageText forSubmission: aSubmission.
                ^ #error ].
        
        "Se assessment vuoto, non procedere"
        (assessment isNil or: [ assessment isEmpty ]) ifTrue: [
            ATAuditLog current logError: 'Empty assessment received' forSubmission: aSubmission.
            ^ #emptyAssessment ] ].
    
    verdict := self parseVerdict: assessment.
    config := assessmentGenerator 
        ifNotNil: [ assessmentGenerator configurationDictionary ]
        ifNil: [ Dictionary new at: 'mode' put: 'simulated'; yourself ].
    
    "Log - usa log separato per test"
    self isTestMode 
        ifTrue: [ ATAuditLog current logTestAssessment: aSubmission verdict: verdict assessment: assessment ]
        ifFalse: [ ATAuditLog current logAssessment: aSubmission verdict: verdict assessment: assessment config: config ].
    
    "Marca come processata"
    processedIds add: aSubmission id.
    
    "In semiAuto, aggiungi a pending e aspetta approvazione"
    mode = #semiAuto ifTrue: [
        pendingApprovals add: (ATPendingApproval
            submission: aSubmission
            assessment: assessment
            verdict: verdict).
        ^ #pendingApproval ].
    
    "In fullAuto, processa immediatamente"
    ^ self executeDecision: verdict forSubmission: aSubmission withAssessment: assessment
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
	"Salva configurazione corrente su file"
	| data path |
	assessmentGenerator ifNil: [ ^ self ].
	data := Dictionary new.
	data at: 'provider' put: assessmentGenerator provider.
	data at: 'model' put: assessmentGenerator model.
	data at: 'useOAuth' put: (assessmentGenerator provider = #google).
	path := ATRepository current gitRepoPath, '/secrets/ai-config.json'.
	path asFileReference parent ensureCreateDirectory.
	path asFileReference writeStreamDo: [ :s |
		s nextPutAll: (NeoJSONWriter toStringPretty: data) ]
]

{ #category : 'configuration' }
ATAutomation >> semiAuto [
	mode := #semiAuto
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
