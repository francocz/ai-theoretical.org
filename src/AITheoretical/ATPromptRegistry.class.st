Class {
	#name : 'ATPromptRegistry',
	#superclass : 'Object',
	#instVars : [
		'prompts',
		'storagePath'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATPromptRegistry class >> current [ ^ current ifNil: [ current := self new initialize ]
]

{ #category : 'accessing' }
ATPromptRegistry class >> reset [ current := nil
]

{ #category : 'querying' }
ATPromptRegistry >> activePromptForTrack: aSymbol [
    "Ritorna il prompt attivo per un track"
    ^ (self promptsForTrack: aSymbol) 
        detect: [ :p | p isActive ] 
        ifNone: [ nil ]
]

{ #category : 'adding' }
ATPromptRegistry >> addPrompt: anATPrompt [
    prompts add: anATPrompt.
    ^ anATPrompt
]

{ #category : 'accessing' }
ATPromptRegistry >> allTracks [
    ^ #(#researchPreprint #workingPaper #expositoryEssay #criticalReview)
]

{ #category : 'initialization' }
ATPromptRegistry >> initialize [
    super initialize.
    prompts := OrderedCollection new.
    self load.
    "Se vuoto dopo il load, inizializza con i default"
    prompts isEmpty ifTrue: [ self initializeFromFiles ]
]

{ #category : 'initialization' }
ATPromptRegistry >> initializeDefaultPrompts [
    "Inizializza i 4 prompt v1.0"
    self addPrompt: (ATPrompt 
        track: #researchPreprint 
        version: '1.0' 
        content: self researchPreprintPromptContent 
        changelog: 'Initial version. Includes originality bonus and focused bibliography criteria.').
    self addPrompt: (ATPrompt 
        track: #workingPaper 
        version: '1.0' 
        content: self workingPaperPromptContent 
        changelog: 'Initial version. More permissive, strongly weights originality.').
    self addPrompt: (ATPrompt 
        track: #expositoryEssay 
        version: '1.0' 
        content: self expositoryEssayPromptContent 
        changelog: 'Initial version. Focuses on pedagogical value and accuracy of representation.').
    self addPrompt: (ATPrompt 
        track: #criticalReview 
        version: '1.0' 
        content: self criticalReviewPromptContent 
        changelog: 'Initial version. Evaluates fairness, critical depth, and argumentative rigor.')
]

{ #category : 'initialization' }
ATPromptRegistry >> initializeFromFiles [
    "Carica i prompt dai file txt"
    | promptsDir |
    promptsDir := '/Users/Franco/Dropbox/ai-theoretical.org/prompts/v1.0' asFileReference.
    promptsDir exists ifFalse: [ ^ self ].
    
    (promptsDir / 'research_preprint.txt') exists ifTrue: [
        self addPrompt: (ATPrompt 
            track: #researchPreprint version: '1.0' 
            content: (promptsDir / 'research_preprint.txt') contents
            changelog: 'Initial version from file.') ].
    
    (promptsDir / 'working_paper.txt') exists ifTrue: [
        self addPrompt: (ATPrompt 
            track: #workingPaper version: '1.0' 
            content: (promptsDir / 'working_paper.txt') contents
            changelog: 'Initial version from file.') ].
    
    (promptsDir / 'expository_essay.txt') exists ifTrue: [
        self addPrompt: (ATPrompt 
            track: #expositoryEssay version: '1.0' 
            content: (promptsDir / 'expository_essay.txt') contents
            changelog: 'Initial version from file.') ].
    
    (promptsDir / 'critical_review.txt') exists ifTrue: [
        self addPrompt: (ATPrompt 
            track: #criticalReview version: '1.0' 
            content: (promptsDir / 'critical_review.txt') contents
            changelog: 'Initial version from file.') ].
    
    self save
]

{ #category : 'persistence' }
ATPromptRegistry >> load [
    "Carica i prompt da file STON"
    | file |
    file := self storagePath asFileReference.
    file exists ifFalse: [ ^ self ].
    prompts := file readStreamDo: [ :s | STON fromStream: s ]
]

{ #category : 'loading' }
ATPromptRegistry >> loadPromptFromFile: aFilePath track: aTrackSymbol version: aVersionString changelog: aChangelogString [
    | content prompt |
    content := aFilePath asFileReference contents.
    prompt := ATPrompt 
        track: aTrackSymbol 
        version: aVersionString 
        content: content 
        changelog: aChangelogString.
    self addPrompt: prompt.
    ^ prompt
]

{ #category : 'accessing' }
ATPromptRegistry >> prompts [ ^ prompts
]

{ #category : 'querying' }
ATPromptRegistry >> promptsForTrack: aSymbol [
    "Ritorna tutti i prompt per un track, ordinati per versione discendente"
    ^ (prompts select: [ :p | p track = aSymbol ])
        sorted: [ :a :b | a version > b version ]
]

{ #category : 'persistence' }
ATPromptRegistry >> save [
    "Salva tutti i prompt su file STON"
    | file |
    file := self storagePath asFileReference.
    file parent ensureCreateDirectory.
    file writeStreamDo: [ :s | 
        STON put: prompts onStream: s ]
]

{ #category : 'accessing' }
ATPromptRegistry >> storagePath [ 
    ^ storagePath ifNil: [ '/Users/Franco/Dropbox/ai-theoretical.org/data/prompts.ston' ]
]

{ #category : 'accessing' }
ATPromptRegistry >> storagePath: aString [ 
    storagePath := aString
]

{ #category : 'accessing' }
ATPromptRegistry >> trackDisplayName: aSymbol [
    aSymbol = #researchPreprint ifTrue: [ ^ 'Research Preprint' ].
    aSymbol = #workingPaper ifTrue: [ ^ 'Working Paper' ].
    aSymbol = #expositoryEssay ifTrue: [ ^ 'Expository/Theoretical Essay' ].
    aSymbol = #criticalReview ifTrue: [ ^ 'Critical Review' ].
    ^ aSymbol asString
]
