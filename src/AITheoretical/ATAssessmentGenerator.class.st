Class {
	#name : 'ATAssessmentGenerator',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'apiKey',
		'model',
		'editorialPrompt',
		'promptVersion',
		'lastUsage',
		'lastCost'
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
    "Chiama l'API AI e ritorna l'assessment. Solleva errore se fallisce."
    | client payload response responseDict |
    client := ZnClient new.
    client url: self apiEndpoint.
    client timeout: 120.  "2 minuti invece del default"
    self configureClient: client.
    payload := self buildPayloadFor: paperText.
    client entity: (ZnEntity json: (NeoJSONWriter toString: payload)).
    
    [ client post ]
        on: Error
        do: [ :e | self error: 'API request failed: ', e messageText ].
    
    response := client contents.
    response ifNil: [ self error: 'Empty response from API' ].
    response isEmpty ifTrue: [ self error: 'Empty response from API' ].
    
    [ responseDict := NeoJSONReader fromString: response ]
        on: Error
        do: [ :e | self error: 'Invalid JSON response: ', e messageText ].
    
    "Controlla se c'è un errore nella risposta"
    (responseDict at: 'error' ifAbsent: [ nil ]) ifNotNil: [ :err |
        self error: 'API error: ', (err at: 'message' ifAbsent: [ err asString ]) ].
    
    ^ self extractTextFrom: responseDict
]

{ #category : 'api' }
ATAssessmentGenerator >> assessSubmission: anATSubmission [
    "Valuta una submission - con PDF se disponibile, altrimenti solo metadati"
    | pdfBytes paperText lf savedPrompt result |
    
    "Prova a scaricare il PDF"
    pdfBytes := self downloadPdfFor: anATSubmission.
    
    pdfBytes ifNotNil: [
        "Usa valutazione con PDF completo"
        ^ self assessSubmissionWithPdf: anATSubmission pdfBytes: pdfBytes ].
    
    "Fallback: solo metadati (title, author, abstract)"
    lf := String lf.
    paperText := 'Title: ' , anATSubmission title , lf ,
        'Author: ' , anATSubmission authorName , lf ,
        'Abstract: ' , anATSubmission abstract.
    
    savedPrompt := editorialPrompt.
    editorialPrompt := self promptForTrack: anATSubmission track.
    
    result := self assessPaper: paperText.
    
    editorialPrompt := savedPrompt.
    
    ^ result
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

{ #category : 'as yet unclassified' }
ATAssessmentGenerator >> assessSubmissionWithPdf: anATSubmission pdfBytes: pdfBytes [
    "Valuta una submission includendo il PDF completo, traccia usage"
    | metadataText lf savedPrompt pdfBase64 client payload response responseDict usage cost inputTokens outputTokens |
    
    lf := String lf.
    metadataText := 'Title: ' , anATSubmission title , lf ,
        'Author: ' , anATSubmission authorName , lf ,
        'Abstract: ' , anATSubmission abstract , lf , lf ,
        'The full PDF is attached. Please evaluate the complete paper including all sections, figures, and bibliography.'.
    
    "Salva prompt corrente, usa quello appropriato al track"
    savedPrompt := editorialPrompt.
    editorialPrompt := self promptForTrack: anATSubmission track.
    
    "Encode PDF in base64"
    pdfBase64 := ZnBase64Encoder new encode: pdfBytes.
    
    "Costruisci e invia richiesta"
    client := ZnClient new.
    client url: self apiEndpoint.
    client timeout: 180.  "3 minuti per PDF"
    self configureClient: client.
    payload := self buildPayloadWithPdf: pdfBase64 metadata: metadataText.
    client entity: (ZnEntity json: (NeoJSONWriter toString: payload)).
    
    [ client post ]
        on: Error
        do: [ :e | 
            editorialPrompt := savedPrompt.
            self error: 'API request failed: ', e messageText ].
    
    response := client contents.
    editorialPrompt := savedPrompt.
    
    response ifNil: [ self error: 'Empty response from API' ].
    response isEmpty ifTrue: [ self error: 'Empty response from API' ].
    
    [ responseDict := NeoJSONReader fromString: response ]
        on: Error
        do: [ :e | self error: 'Invalid JSON response: ', e messageText ].
    
    "Controlla errore"
    (responseDict at: 'error' ifAbsent: [ nil ]) ifNotNil: [ :err |
        self error: 'API error: ', (err at: 'message' ifAbsent: [ err asString ]) ].
    
    "Traccia usage"
    usage := self extractUsageFrom: responseDict.
    cost := self estimateCostFor: usage.
    lastUsage := usage.
    lastCost := cost.
    
    "Registra su ATUsageTracker - usa chiavi stringa con underscore come in usage dict"
    inputTokens := usage at: 'input_tokens' ifAbsent: [ 0 ].
    outputTokens := usage at: 'output_tokens' ifAbsent: [ 0 ].
    ATUsageTracker current recordUsageFor: provider inputTokens: inputTokens outputTokens: outputTokens.
    
    "Log usage"
    ATAuditLog current logTokenUsage: usage cost: cost provider: provider model: model forSubmission: anATSubmission.
    
    ^ self extractTextFrom: responseDict
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

{ #category : 'as yet unclassified' }
ATAssessmentGenerator >> buildPayloadWithPdf: pdfBase64 metadata: metadataText [
    "Costruisce payload con PDF embedded per i vari provider"
    | payload messages userContent |
    
    provider = #anthropic ifTrue: [
        "Anthropic: array di content blocks"
        userContent := OrderedCollection new.
        userContent add: (Dictionary new 
            at: 'type' put: 'document';
            at: 'source' put: (Dictionary new
                at: 'type' put: 'base64';
                at: 'media_type' put: 'application/pdf';
                at: 'data' put: pdfBase64;
                yourself);
            yourself).
        userContent add: (Dictionary new
            at: 'type' put: 'text';
            at: 'text' put: (self buildPromptFor: metadataText);
            yourself).
        messages := { Dictionary new 
            at: 'role' put: 'user'; 
            at: 'content' put: userContent asArray; 
            yourself }.
        payload := Dictionary new.
        payload at: 'model' put: model.
        payload at: 'max_tokens' put: 4096.
        payload at: 'temperature' put: 0.
        payload at: 'messages' put: messages.
        ^ payload ].
    
    provider = #google ifTrue: [
        "Google: inline_data per PDF"
        payload := Dictionary new.
        payload at: 'contents' put: { 
            Dictionary new 
                at: 'parts' put: {
                    Dictionary new 
                        at: 'inline_data' put: (Dictionary new
                            at: 'mime_type' put: 'application/pdf';
                            at: 'data' put: pdfBase64;
                            yourself);
                        yourself.
                    Dictionary new 
                        at: 'text' put: (self buildPromptFor: metadataText);
                        yourself
                }; 
                yourself 
        }.
        payload at: 'generationConfig' put: (Dictionary new at: 'temperature' put: 0; yourself).
        ^ payload ].
    
    provider = #openai ifTrue: [
        "OpenAI: fallback a solo testo - OpenAI richiede conversione PDF->immagini"
        ^ self buildPayloadFor: metadataText ].
    
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

{ #category : 'as yet unclassified' }
ATAssessmentGenerator >> downloadPdfFor: anATSubmission [
    "Scarica il PDF via API Worker"
    | client url |
    anATSubmission id ifNil: [ ^ nil ].
    
    "Costruisci URL per download PDF"
    url := 'https://ai-theoretical.org/api/submission/', anATSubmission id, '/pdf'.
    
    client := ZnClient new.
    client timeout: 60.
    client url: url.
    client headerAt: 'Authorization' put: 'Bearer ', ATRepository current apiToken.
    client get.
    client isSuccess ifFalse: [ ^ nil ].
    ^ client contents asByteArray
]

{ #category : 'accessing' }
ATAssessmentGenerator >> editorialPrompt [ ^ editorialPrompt
]

{ #category : 'accessing' }
ATAssessmentGenerator >> editorialPrompt: aString [ editorialPrompt := aString
]

{ #category : 'as yet unclassified' }
ATAssessmentGenerator >> estimateCostFor: usageDict [
    "Stima il costo in USD basato su provider/model"
    | inputTokens outputTokens inputCost outputCost |
    usageDict ifNil: [ ^ 0 ].
    inputTokens := usageDict at: 'input_tokens' ifAbsent: [ 0 ].
    outputTokens := usageDict at: 'output_tokens' ifAbsent: [ 0 ].
    
    "Prezzi per milione di token (approssimati, gennaio 2026)"
    provider = #anthropic ifTrue: [
        "Claude Sonnet 4: $3 input, $15 output per 1M"
        inputCost := inputTokens * 3 / 1000000.
        outputCost := outputTokens * 15 / 1000000.
        ^ inputCost + outputCost ].
    provider = #google ifTrue: [
        "Gemini: ~$0.5 input, $1.5 output per 1M"
        inputCost := inputTokens * 0.5 / 1000000.
        outputCost := outputTokens * 1.5 / 1000000.
        ^ inputCost + outputCost ].
    provider = #openai ifTrue: [
        "GPT-4: ~$10 input, $30 output per 1M"
        inputCost := inputTokens * 10 / 1000000.
        outputCost := outputTokens * 30 / 1000000.
        ^ inputCost + outputCost ].
    ^ 0
]

{ #category : 'private' }
ATAssessmentGenerator >> extractTextFrom: responseDict [
    "Estrae il testo dalla risposta API. Ritorna stringa vuota se formato non riconosciuto."
    | content |
    
    responseDict isDictionary ifFalse: [ ^ '' ].
    
    provider = #anthropic ifTrue: [
        content := responseDict at: 'content' ifAbsent: [ ^ '' ].
        content isCollection ifFalse: [ ^ '' ].
        content isEmpty ifTrue: [ ^ '' ].
        ^ (content first at: 'text' ifAbsent: [ '' ]) asString ].
    
    provider = #openai ifTrue: [
        content := responseDict at: 'choices' ifAbsent: [ ^ '' ].
        content isCollection ifFalse: [ ^ '' ].
        content isEmpty ifTrue: [ ^ '' ].
        ^ ((content first at: 'message' ifAbsent: [ Dictionary new ]) at: 'content' ifAbsent: [ '' ]) asString ].
    
    provider = #google ifTrue: [
        | candidates candidate parts |
        candidates := responseDict at: 'candidates' ifAbsent: [ ^ '' ].
        candidates isCollection ifFalse: [ ^ '' ].
        candidates isEmpty ifTrue: [ ^ '' ].
        candidate := candidates first.
        candidate isDictionary ifFalse: [ ^ '' ].
        content := candidate at: 'content' ifAbsent: [ ^ '' ].
        content isDictionary ifFalse: [ ^ '' ].
        parts := content at: 'parts' ifAbsent: [ ^ '' ].
        parts isCollection ifFalse: [ ^ '' ].
        parts isEmpty ifTrue: [ ^ '' ].
        ^ (parts first at: 'text' ifAbsent: [ '' ]) asString ].
    
    ^ ''
]

{ #category : 'as yet unclassified' }
ATAssessmentGenerator >> extractUsageFrom: responseDict [
    "Estrae input/output tokens dalla risposta API"
    | usage |
    provider = #anthropic ifTrue: [
        usage := responseDict at: 'usage' ifAbsent: [ ^ nil ].
        ^ Dictionary new
            at: 'input_tokens' put: (usage at: 'input_tokens' ifAbsent: [ 0 ]);
            at: 'output_tokens' put: (usage at: 'output_tokens' ifAbsent: [ 0 ]);
            yourself ].
    provider = #google ifTrue: [
        usage := responseDict at: 'usageMetadata' ifAbsent: [ ^ nil ].
        ^ Dictionary new
            at: 'input_tokens' put: (usage at: 'promptTokenCount' ifAbsent: [ 0 ]);
            at: 'output_tokens' put: (usage at: 'candidatesTokenCount' ifAbsent: [ 0 ]);
            yourself ].
    provider = #openai ifTrue: [
        usage := responseDict at: 'usage' ifAbsent: [ ^ nil ].
        ^ Dictionary new
            at: 'input_tokens' put: (usage at: 'prompt_tokens' ifAbsent: [ 0 ]);
            at: 'output_tokens' put: (usage at: 'completion_tokens' ifAbsent: [ 0 ]);
            yourself ].
    ^ nil
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

{ #category : 'prompts' }
ATAssessmentGenerator >> promptForTrack: aSymbol [
    | prompt |
    "Prima prova dal registry"
    prompt := ATPromptRegistry current activePromptForTrack: aSymbol.
    prompt ifNotNil: [ ^ prompt content ].
    
    "Fallback ai metodi locali per retrocompatibilità"
    aSymbol = #researchPreprint ifTrue: [ ^ self researchPreprintPrompt ].
    aSymbol = #workingPaper ifTrue: [ ^ self workingPaperPrompt ].
    
    "Default"
    ^ self workingPaperPrompt
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

{ #category : 'prompts' }
ATAssessmentGenerator >> researchPreprintPrompt [
    ^ 'You are acting as an editorial assessment agent for the platform AI-assisted theoretical writing. This platform hosts high-level theoretical preprints and working papers, not a peer-reviewed journal. Your task is not to simulate peer review. Your task is to produce (A) a structured decision-driving summary and (B) an extended explanatory assessment, following mandatory rules. Output format is strictly constrained.

This submission is for the RESEARCH PREPRINT track. Research preprints are expected to meet higher standards of completeness, argumentation, and scholarly apparatus while still being pre-publication works.

(A) STRUCTURED SUMMARY — produce exactly the 16 labeled lines below, in the same order, with no extra lines before, between, or after. Do not repeat labels. Each label must start a new line and be numbered in strict order. Format each line as "N) Label: Value" with a line break after each line. Do not insert blank lines between entries.

1) Category: Choose one: Research preprint; Expository/theoretical essay; Critical review; Not a fit.
2) Aims: One sentence stating the text''s explicit aims and claimed level (exploratory/synthetic/critical/technical).
3) Correctness: Choose one: No errors identified; Minor local issues; Systematic errors; Undermining errors.
4) Coherence: Choose one: Adequate; Minor issues; Major issues.
5) Consistency: Choose one: Consistent; Minor drift; Major drift.
6) Semantic opacity: Choose one: Low (Transparent); Moderate (Justified complexity); High (Obfuscatory).
7) Novelty: Choose one: Original; Reformulative; Consolidative.
8) Bibliography: Choose one: Adequate; Incomplete; Weak; Absent. Evaluate against the paper''s scope and claims. The bibliography should cover the key works directly relevant to the argument, not exhaustive coverage of adjacent fields.
9) Effectiveness: Choose one: Achieves aims; Partially achieves aims; Fails to achieve aims.
10) Cross-framework traction: Choose one: High; Medium; Low. If Low, explicitly mark as cognitively closed.
11) Claims: Choose one: Supported; Partially supported; Unsupported assertions.
12) Contribution: Choose one: Substantive; Marginal; Absent.
13) Structure: Choose one: Adequate; Minor issues; Inadequate.
14) Integrity: Choose one: No issues; Suspected plagiarism; Potentially harmful content.
15) Code (if provided): Choose one: Coherent with paper; Incoherent with paper; Suspicious patterns; Not provided.
16) Editorial outcome: Choose one: Suitable for inclusion as a research preprint; Potentially suitable with revision; Not suitable for this platform.

Decision rules (mandatory):
If Category is Not a fit → Not suitable.
If Correctness is Systematic or Undermining → Not suitable.
If Coherence is Major issues → Not suitable.
If Semantic opacity is High → Not suitable.
If Effectiveness is Fails to achieve aims → Not suitable.
If Cross-framework traction is Low (cognitively closed) → Not suitable.
If Claims is Unsupported assertions → Not suitable.
If Contribution is Absent → Not suitable.
If Structure is Inadequate → Not suitable.
If Integrity is Suspected plagiarism or Potentially harmful content → Not suitable.
If Code is Suspicious patterns → Not suitable.
If Code is Incoherent with paper → Potentially suitable with revision.

If Novelty is Original AND Contribution is Substantive AND at most one of Bibliography, Effectiveness, Claims, Structure has minor issues → Suitable for inclusion as a research preprint.
Otherwise, if at least two of Bibliography, Coherence, Effectiveness, Claims, Structure are not at their best value → Potentially suitable with revision.
Otherwise → Suitable for inclusion as a research preprint.

(B) EXTENDED ASSESSMENT — after completing section (A), write a concise explanatory assessment (120–200 words) that justifies the judgments above. You may rephrase the editorial outcome labels to fit the natural flow of the sentence, provided the logical decision remains identical to section (A). The extended assessment must not introduce new criteria, must not contradict the structured summary, and must not revise the editorial outcome. Use neutral, analytic english language, following a clear, direct, and academically sound style. Avoid jargon and semantical opacity. Format the output properly and break lines as necessary to maintain the clarity of the output.

Global constraints: Do not praise originality, brilliance, or importance. Do not adopt the tone of a referee report. Do not soften negative judgments. Avoid speculative or diplomatic language. Do not add questions, suggestions, summaries, or meta-commentary. End the response with the editorial outcome line already given in section (A); do not repeat it.'
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

{ #category : 'prompts' }
ATAssessmentGenerator >> workingPaperPrompt [
    ^ 'You are acting as an editorial assessment agent for the platform AI-assisted theoretical writing. This platform hosts high-level theoretical preprints and working papers, not a peer-reviewed journal. Your task is not to simulate peer review. Your task is to produce (A) a structured decision-driving summary and (B) an extended explanatory assessment, following mandatory rules. Output format is strictly constrained.

This submission is for the WORKING PAPER track. Working papers are expected to present original ideas that may still be developing. Originality and intellectual contribution are weighted more heavily than completeness of bibliography or polish of presentation.

(A) STRUCTURED SUMMARY — produce exactly the 16 labeled lines below, in the same order, with no extra lines before, between, or after. Do not repeat labels. Each label must start a new line and be numbered in strict order. Format each line as "N) Label: Value" with a line break after each line. Do not insert blank lines between entries.

1) Category: Choose one: Research preprint; Expository/theoretical essay; Critical review; Not a fit.
2) Aims: One sentence stating the text''s explicit aims and claimed level (exploratory/synthetic/critical/technical).
3) Correctness: Choose one: No errors identified; Minor local issues; Systematic errors; Undermining errors.
4) Coherence: Choose one: Adequate; Minor issues; Major issues.
5) Consistency: Choose one: Consistent; Minor drift; Major drift.
6) Semantic opacity: Choose one: Low (Transparent); Moderate (Justified complexity); High (Obfuscatory).
7) Novelty: Choose one: Original; Reformulative; Consolidative.
8) Bibliography: Choose one: Adequate; Incomplete; Weak; Absent. Evaluate only against the paper''s specific scope and direct claims, not encyclopedic coverage. A focused bibliography covering the immediate theoretical dependencies is sufficient.
9) Effectiveness: Choose one: Achieves aims; Partially achieves aims; Fails to achieve aims.
10) Cross-framework traction: Choose one: High; Medium; Low. If Low, explicitly mark as cognitively closed.
11) Claims: Choose one: Supported; Partially supported; Unsupported assertions.
12) Contribution: Choose one: Substantive; Marginal; Absent.
13) Structure: Choose one: Adequate; Minor issues; Inadequate.
14) Integrity: Choose one: No issues; Suspected plagiarism; Potentially harmful content.
15) Code (if provided): Choose one: Coherent with paper; Incoherent with paper; Suspicious patterns; Not provided.
16) Editorial outcome: Choose one: Suitable for inclusion as a working paper; Potentially suitable with revision; Not suitable for this platform.

Decision rules (mandatory):
If Category is Not a fit → Not suitable.
If Correctness is Systematic or Undermining → Not suitable.
If Coherence is Major issues → Not suitable.
If Semantic opacity is High → Not suitable.
If Cross-framework traction is Low (cognitively closed) → Not suitable.
If Contribution is Absent → Not suitable.
If Integrity is Suspected plagiarism or Potentially harmful content → Not suitable.
If Code is Suspicious patterns → Not suitable.

ORIGINALITY BONUS: If Novelty is Original AND Contribution is Substantive → accept unless there are critical failures above. Minor issues in Bibliography, Structure, or Effectiveness should not block acceptance of genuinely original work.

If Novelty is Original AND Contribution is Substantive AND no critical failures above → Suitable for inclusion as a working paper.
If Code is Incoherent with paper → Potentially suitable with revision.
If Claims is Unsupported assertions AND Novelty is not Original → Not suitable.
If Effectiveness is Fails to achieve aims AND Novelty is not Original → Not suitable.
Otherwise, if at least three of Bibliography, Coherence, Effectiveness, Claims, Structure are not at their best value → Potentially suitable with revision.
Otherwise → Suitable for inclusion as a working paper.

(B) EXTENDED ASSESSMENT — after completing section (A), write a concise explanatory assessment (120–200 words) that justifies the judgments above. You may rephrase the editorial outcome labels to fit the natural flow of the sentence, provided the logical decision remains identical to section (A). The extended assessment must not introduce new criteria, must not contradict the structured summary, and must not revise the editorial outcome. Use neutral, analytic english language, following a clear, direct, and academically sound style. Avoid jargon and semantical opacity. Format the output properly and break lines as necessary to maintain the clarity of the output.

Global constraints: Do not praise originality, brilliance, or importance. Do not adopt the tone of a referee report. Do not soften negative judgments. Avoid speculative or diplomatic language. Do not add questions, suggestions, summaries, or meta-commentary. End the response with the editorial outcome line already given in section (A); do not repeat it.'
]
