Class {
	#name : 'ATAssessmentGenerator',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'apiKey',
		'model',
		'editorialPrompt',
		'promptVersion'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATAssessmentGenerator class >> anthropic: apiKey [
	^ self new useAnthropic: apiKey; yourself
]

{ #category : 'instance creation' }
ATAssessmentGenerator class >> google: apiKey [
	^ self new useGoogle: apiKey; yourself
]

{ #category : 'instance creation' }
ATAssessmentGenerator class >> googleWithOAuth [
	"Crea generator per Google Gemini usando OAuth2"
	| auth |
	auth := ATGoogleAuth current.
	auth isAuthenticated ifFalse: [
		auth load.
		auth isAuthenticated ifFalse: [
			self error: 'Google OAuth not configured. Run ATGoogleAuth current startAuthFlow first.' ] ].
	^ self new
		provider: #google;
		model: 'gemini-1.5-pro';
		apiKey: auth ensureValidToken;
		yourself
]

{ #category : 'instance creation' }
ATAssessmentGenerator class >> openai: apiKey [
	^ self new useOpenAI: apiKey; yourself
]

{ #category : 'private' }
ATAssessmentGenerator >> apiEndpoint [
	provider = #anthropic ifTrue: [ ^ 'https://api.anthropic.com/v1/messages' ].
	provider = #openai ifTrue: [ ^ 'https://api.openai.com/v1/chat/completions' ].
	provider = #google ifTrue: [ ^ 'https://generativelanguage.googleapis.com/v1beta/models/', model, ':generateContent' ].
	self error: 'Unknown provider'
]

{ #category : 'accessing' }
ATAssessmentGenerator >> apiKey [ ^ apiKey
]

{ #category : 'accessing' }
ATAssessmentGenerator >> apiKey: aString [ apiKey := aString
]

{ #category : 'api' }
ATAssessmentGenerator >> assessPaper: paperText [
	| client payload response responseDict |
	client := ZnClient new.
	client url: self apiEndpoint.
	self configureClient: client.
	payload := self buildPayloadFor: paperText.
	client entity: (ZnEntity json: (NeoJSONWriter toString: payload)).
	client post.
	response := client contents.
	responseDict := NeoJSONReader fromString: response.
	^ self extractTextFrom: responseDict
]

{ #category : 'api' }
ATAssessmentGenerator >> assessSubmission: anATSubmission [
	| paperText lf |
	lf := String lf.
	paperText := 'Title: ' , anATSubmission title , lf ,
		'Author: ' , anATSubmission authorName , lf ,
		'Abstract: ' , anATSubmission abstract.
	^ self assessPaper: paperText
]

{ #category : 'api' }
ATAssessmentGenerator >> assessSubmissionWithCode: anATSubmission codeContent: aStringOrNil [
	"Valuta submission includendo analisi codice se presente"
	| paperText lf |
	lf := String lf.
	paperText := 'Title: ' , anATSubmission title , lf ,
		'Author: ' , anATSubmission authorName , lf ,
		'Abstract: ' , anATSubmission abstract.
	aStringOrNil ifNotNil: [ :code |
		paperText := paperText , lf , lf ,
			'=== CODE ATTACHED ==' , lf ,
			'The following code was submitted with the paper. Analyze it for:', lf,
			'- Coherence with paper claims', lf,
			'- Suspicious patterns (malware, obfuscation, dangerous operations)', lf,
			'- Quality and documentation', lf, lf,
			code ].
	^ self assessPaper: paperText
]

{ #category : 'api' }
ATAssessmentGenerator >> assessSubmissionWithMetadata: anATSubmission [
	"Valuta submission e ritorna assessment con metadata completi per riproducibilità"
	| assessment |
	assessment := self assessSubmission: anATSubmission.
	^ Dictionary new
		at: 'assessment' put: assessment;
		at: 'promptVersion' put: self promptVersion;
		at: 'assessedAt' put: DateAndTime now asString;
		at: 'provider' put: provider asString;
		at: 'model' put: model;
		at: 'temperature' put: 0;
		at: 'seed' put: (provider = #openai ifTrue: [ 42 ] ifFalse: [ nil ]);
		at: 'promptHash' put: self currentPrompt hash asString;
		yourself
]

{ #category : 'private' }
ATAssessmentGenerator >> buildPayloadFor: paperText [
	| payload messages |
	messages := { Dictionary new at: 'role' put: 'user'; at: 'content' put: (self buildPromptFor: paperText); yourself }.
	provider = #anthropic ifTrue: [
		payload := Dictionary new.
		payload at: 'model' put: model.
		payload at: 'max_tokens' put: 4096.
		payload at: 'temperature' put: 0.
		payload at: 'messages' put: messages.
		^ payload ].
	provider = #openai ifTrue: [
		payload := Dictionary new.
		payload at: 'model' put: model.
		payload at: 'temperature' put: 0.
		payload at: 'seed' put: 42.  "OpenAI supporta seed per riproducibilità"
		payload at: 'messages' put: messages.
		^ payload ].
	provider = #google ifTrue: [
		payload := Dictionary new.
		payload at: 'contents' put: { Dictionary new at: 'parts' put: { Dictionary new at: 'text' put: (self buildPromptFor: paperText); yourself }; yourself }.
		payload at: 'generationConfig' put: (Dictionary new at: 'temperature' put: 0; yourself).
		^ payload ].
	self error: 'Unknown provider'
]

{ #category : 'private' }
ATAssessmentGenerator >> buildPromptFor: paperText [
	| lf prompt |
	lf := String lf.
	prompt := editorialPrompt ifNil: [ self defaultEditorialPrompt ].
	^ prompt, lf, lf, '=== PAPER TEXT ===', lf, paperText
]

{ #category : 'accessing' }
ATAssessmentGenerator >> configurationDictionary [
	"Ritorna la configurazione completa per riproducibilità"
	^ Dictionary new
		at: 'provider' put: (provider ifNil: ['not configured'] ifNotNil: [provider asString]);
		at: 'model' put: (model ifNil: ['not configured']);
		at: 'temperature' put: 0;
		at: 'seed' put: (provider = #openai ifTrue: [ 42 ] ifFalse: [ 'n/a' ]);
		at: 'maxTokens' put: 4096;
		at: 'promptVersion' put: self promptVersion;
		at: 'promptLength' put: self currentPrompt size;
		at: 'promptHash' put: self currentPrompt hash asString;
		yourself
]

{ #category : 'private' }
ATAssessmentGenerator >> configureClient: client [
	provider = #anthropic ifTrue: [
		client headerAt: 'x-api-key' put: apiKey.
		client headerAt: 'anthropic-version' put: '2023-06-01'.
		client headerAt: 'Content-Type' put: 'application/json'.
		^ self ].
	provider = #openai ifTrue: [
		client headerAt: 'Authorization' put: 'Bearer ', apiKey.
		client headerAt: 'Content-Type' put: 'application/json'.
		^ self ].
	provider = #google ifTrue: [
		client queryAt: 'key' put: apiKey.
		client headerAt: 'Content-Type' put: 'application/json'.
		^ self ].
	self error: 'Unknown provider'
]

{ #category : 'accessing' }
ATAssessmentGenerator >> currentPrompt [
	"Ritorna il prompt corrente (custom o default)"
	^ editorialPrompt ifNil: [ self defaultEditorialPrompt ]
]

{ #category : 'defaults' }
ATAssessmentGenerator >> defaultEditorialPrompt [
	| lf |
	lf := String lf.
	^ 'You are an AI editorial reviewer for ai-theoretical.org.' , lf ,
	'Evaluate the following paper and produce a structured assessment.' , lf , lf ,
	'Your response MUST follow this EXACT format:' , lf , lf ,
	'(A) STRUCTURED SUMMARY' , lf ,
	'Category: [Research preprint / Expository essay / Technical note / etc.]' , lf ,
	'Aims: [Brief description of what the paper aims to achieve]' , lf ,
	'Correctness: [No errors identified / Minor issues / Major errors]' , lf ,
	'Coherence: [Adequate / Limited / Problematic]' , lf ,
	'Consistency: [Consistent / Some inconsistencies / Inconsistent]' , lf ,
	'Semantic opacity: [Low (Transparent) / Moderate / High]' , lf ,
	'Novelty: [Original / Consolidative / Derivative]' , lf ,
	'Bibliography: [Adequate / Limited / Inadequate]' , lf ,
	'Effectiveness: [Achieves aims / Partially achieves / Does not achieve]' , lf ,
	'Cross-framework traction: [High / Moderate / Low]' , lf ,
	'Editorial outcome: [Suitable for inclusion as a preprint / Needs revision / Not suitable]' , lf , lf ,
	'(B) EXTENDED ASSESSMENT' , lf ,
	'[Write 2-3 paragraphs providing detailed analysis of the paper]'
]

{ #category : 'accessing' }
ATAssessmentGenerator >> editorialPrompt [ ^ editorialPrompt
]

{ #category : 'accessing' }
ATAssessmentGenerator >> editorialPrompt: aString [ editorialPrompt := aString
]

{ #category : 'private' }
ATAssessmentGenerator >> extractTextFrom: responseDict [
	| content |
	provider = #anthropic ifTrue: [
		content := responseDict at: 'content' ifAbsent: [ ^ '' ].
		^ (content first at: 'text' ifAbsent: [ '' ]) ].
	provider = #openai ifTrue: [
		content := responseDict at: 'choices' ifAbsent: [ ^ '' ].
		^ ((content first at: 'message' ifAbsent: [ Dictionary new ]) at: 'content' ifAbsent: [ '' ]) ].
	provider = #google ifTrue: [
		content := responseDict at: 'candidates' ifAbsent: [ ^ '' ].
		^ ((((content first at: 'content' ifAbsent: [ Dictionary new ]) at: 'parts' ifAbsent: [ { Dictionary new } ]) first) at: 'text' ifAbsent: [ '' ]) ].
	^ ''
]

{ #category : 'configuration' }
ATAssessmentGenerator >> loadPromptFromFile: aFilePath [
	"Carica il prompt editoriale da un file di testo"
	editorialPrompt := aFilePath asFileReference contents
]

{ #category : 'configuration' }
ATAssessmentGenerator >> loadPromptFromFile: aFilePath version: aVersionString [
	"Carica il prompt editoriale da un file di testo e setta la versione"
	editorialPrompt := aFilePath asFileReference contents.
	promptVersion := aVersionString
]

{ #category : 'accessing' }
ATAssessmentGenerator >> model [ ^ model
]

{ #category : 'accessing' }
ATAssessmentGenerator >> model: aString [ model := aString
]

{ #category : 'accessing' }
ATAssessmentGenerator >> promptInfo [
	"Ritorna info su prompt corrente"
	^ Dictionary new
		at: 'version' put: self promptVersion;
		at: 'date' put: Date today yyyymmdd;
		yourself
]

{ #category : 'accessing' }
ATAssessmentGenerator >> promptVersion [
	^ promptVersion ifNil: [ '2.0' ]
]

{ #category : 'accessing' }
ATAssessmentGenerator >> promptVersion: aString [
	promptVersion := aString
]

{ #category : 'accessing' }
ATAssessmentGenerator >> provider [ ^ provider
]

{ #category : 'accessing' }
ATAssessmentGenerator >> provider: aSymbol [ provider := aSymbol
]

{ #category : 'configuration' }
ATAssessmentGenerator >> savePromptToFile: aFilePath [
	"Salva il prompt corrente in un file per editing"
	aFilePath asFileReference writeStreamDo: [ :stream |
		stream nextPutAll: self currentPrompt ]
]

{ #category : 'configuration' }
ATAssessmentGenerator >> useAnthropic: anApiKey [
	provider := #anthropic.
	apiKey := anApiKey.
	model := 'claude-sonnet-4-5-20250514'
]

{ #category : 'configuration' }
ATAssessmentGenerator >> useDefaultPrompt [
	"Resetta al prompt di default"
	editorialPrompt := nil
]

{ #category : 'configuration' }
ATAssessmentGenerator >> useGoogle: anApiKey [
	provider := #google.
	apiKey := anApiKey.
	model := 'gemini-2.0-flash'
]

{ #category : 'configuration' }
ATAssessmentGenerator >> useOpenAI: anApiKey [
	provider := #openai.
	apiKey := anApiKey.
	model := 'gpt-4o'
]
