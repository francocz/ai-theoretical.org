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
		'pendingApprovals'
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

{ #category : 'manual' }
ATAutomation >> approvePending: aPendingApproval [
	"Approva manualmente una pending approval"
	| result |
	result := self executeDecision: #accept
		forSubmission: aPendingApproval submission
		withAssessment: aPendingApproval assessment.
	self pendingApprovals remove: aPendingApproval ifAbsent: [].
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
	pollingInterval := 60.
	lastCheck := DateAndTime now.
	mode := #fullAuto.
	pendingApprovals := OrderedCollection new
]

{ #category : 'testing' }
ATAutomation >> isRunning [
	^ pollingProcess notNil and: [ pollingProcess isTerminated not ]
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
	| assessment verdict config |
	assessmentGenerator ifNil: [ ^ self error: 'No assessment generator configured' ].
	
	"Genera assessment"
	[ assessment := assessmentGenerator assessSubmission: aSubmission ]
		on: Error
		do: [ :e | 
			ATAuditLog current logError: e messageText forSubmission: aSubmission.
			^ #error ].
	
	verdict := self parseVerdict: assessment.
	config := assessmentGenerator configurationDictionary.
	
	"Log dell'assessment"
	ATAuditLog current 
		logAssessment: aSubmission 
		verdict: verdict 
		assessment: assessment 
		config: config.
	
	"In semiAuto, aggiungi a pending e aspetta approvazione"
	mode = #semiAuto ifTrue: [
		self pendingApprovals add: (ATPendingApproval
			submission: aSubmission
			assessment: assessment
			verdict: verdict).
		^ #pendingApproval ].
	
	"In fullAuto, processa immediatamente"
	^ self executeDecision: verdict forSubmission: aSubmission withAssessment: assessment
]

{ #category : 'manual' }
ATAutomation >> rejectPending: aPendingApproval [
	"Rifiuta manualmente una pending approval"
	| result |
	result := self executeDecision: #reject
		forSubmission: aPendingApproval submission
		withAssessment: aPendingApproval assessment.
	self pendingApprovals remove: aPendingApproval ifAbsent: [].
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
