Class {
	#name : 'ATSubmission',
	#superclass : 'Object',
	#instVars : [
		'authorName',
		'authorEmail',
		'authorAffiliation',
		'title',
		'abstract',
		'aiModels',
		'pdfUrl',
		'submittedAt',
		'status',
		'id',
		'pdfKey',
		'hasPdf',
		'notes',
		'paperToken',
		'codeZipKey',
		'hasCode',
		'track',
		'isTest',
		'promptVersion',
		'coAuthors'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATSubmission class >> fromDictionary: aDict [
    | submission statusStr trackStr submittedStr |
    submission := self new
        id: (aDict at: 'id' ifAbsent: [ nil ]);
        paperToken: (aDict at: 'paperToken' ifAbsent: [ nil ]);
        authorName: (aDict at: 'authorName' ifAbsent: [ '' ]);
        authorEmail: (aDict at: 'authorEmail' ifAbsent: [ '' ]);
        authorAffiliation: (aDict at: 'authorAffiliation' ifAbsent: [ nil ]);
        coAuthors: (aDict at: 'coAuthors' ifAbsent: [ '' ]);
        title: (aDict at: 'title' ifAbsent: [ '' ]);
        abstract: (aDict at: 'abstract' ifAbsent: [ '' ]);
        aiModels: (aDict at: 'aiModels' ifAbsent: [ '' ]);
        notes: (aDict at: 'notes' ifAbsent: [ '' ]);
        pdfKey: (aDict at: 'pdfKey' ifAbsent: [ nil ]);
        hasPdf: (aDict at: 'hasPdf' ifAbsent: [ false ]);
        codeZipKey: (aDict at: 'codeZipKey' ifAbsent: [ nil ]);
        hasCode: (aDict at: 'hasCode' ifAbsent: [ false ]);
        yourself.
    statusStr := aDict at: 'status' ifAbsent: [ 'pending' ].
    submission status: statusStr asSymbol.
    trackStr := aDict at: 'track' ifAbsent: [ 'workingPaper' ].
    submission track: trackStr asSymbol.
    "Parse submittedAt se presente"
    submittedStr := aDict at: 'submittedAt' ifAbsent: [ nil ].
    submittedStr ifNotNil: [
        [ submission submittedAt: (DateAndTime fromString: submittedStr) ]
            on: Error do: [ :e | "Ignora errori di parsing" ] ].
    ^ submission
]

{ #category : 'accessing' }
ATSubmission >> abstract [
^ abstract
]

{ #category : 'accessing' }
ATSubmission >> abstract: anObject [
abstract := anObject
]

{ #category : 'actions' }
ATSubmission >> accept [
status := #accepted
]

{ #category : 'accessing' }
ATSubmission >> aiModels [
^ aiModels
]

{ #category : 'accessing' }
ATSubmission >> aiModels: anObject [
aiModels := anObject
]

{ #category : 'converting' }
ATSubmission >> asDictionary [
    ^ Dictionary new
        at: 'authorName' put: authorName;
        at: 'authorEmail' put: authorEmail;
        at: 'authorAffiliation' put: (authorAffiliation ifNil: [ '' ]);
        at: 'coAuthors' put: self coAuthors;
        at: 'title' put: title;
        at: 'abstract' put: abstract;
        at: 'aiModels' put: aiModels;
        at: 'pdfUrl' put: pdfUrl;
        at: 'submittedAt' put: submittedAt asString;
        at: 'status' put: status asString;
        at: 'codeZipKey' put: codeZipKey;
        at: 'hasCode' put: self hasCode;
        yourself
]

{ #category : 'converting' }
ATSubmission >> asPaper [
    "Crea un ATPaper da questa submission. Usare solo dopo accettazione."
    | paper authorDisplay pubDate |
    
    "Costruisco la stringa authors completa"
    authorDisplay := authorName.
    authorAffiliation ifNotNil: [ :aff | 
        aff isEmpty ifFalse: [ authorDisplay := authorDisplay, ' (', aff, ')' ] ].
    (coAuthors notNil and: [ coAuthors notEmpty ]) ifTrue: [
        authorDisplay := authorDisplay, ', ', coAuthors ].
    
    "Data di pubblicazione: usa submittedAt o today come fallback"
    pubDate := submittedAt 
        ifNil: [ Date today ] 
        ifNotNil: [ :dt | dt asDate ].
    
    paper := ATPaper new
        title: title;
        authors: authorDisplay;
        aiModels: aiModels;
        abstract: abstract;
        track: self track;
        date: pubDate;
        generateSlug;
        yourself.
    ^ paper
]

{ #category : 'accessing' }
ATSubmission >> authorAffiliation [
^ authorAffiliation
]

{ #category : 'accessing' }
ATSubmission >> authorAffiliation: anObject [
authorAffiliation := anObject
]

{ #category : 'accessing' }
ATSubmission >> authorEmail [
^ authorEmail
]

{ #category : 'accessing' }
ATSubmission >> authorEmail: anObject [
authorEmail := anObject
]

{ #category : 'accessing' }
ATSubmission >> authorName [
^ authorName
]

{ #category : 'accessing' }
ATSubmission >> authorName: anObject [
authorName := anObject
]

{ #category : 'as yet unclassified' }
ATSubmission >> coAuthors [
    ^ coAuthors ifNil: [ '' ]
]

{ #category : 'as yet unclassified' }
ATSubmission >> coAuthors: aString [
    coAuthors := aString
]

{ #category : 'accessing' }
ATSubmission >> codeZipKey [
	^ codeZipKey
]

{ #category : 'accessing' }
ATSubmission >> codeZipKey: aKey [
	codeZipKey := aKey.
	hasCode := aKey notNil and: [ aKey notEmpty ]
]

{ #category : 'actions' }
ATSubmission >> delete [
	"Elimina questa submission via API e dalla cache locale"
	| response |
	
	"Elimina via API"
	response := ZnClient new
		url: 'https://ai-theoretical.org/api/submission/', id;
		headerAt: 'Authorization' put: 'Bearer ', ATRepository current apiToken;
		delete;
		response.
	
	response isSuccess ifFalse: [
		self error: 'Failed to delete submission: ', response statusLine asString ].
	
	"Rimuovi dalla cache locale"
	ATRepository current submissions remove: self ifAbsent: [].
	
	"Rimuovi da pendingApprovals se presente"
	ATAutomation current pendingApprovals removeAllSuchThat: [ :a | a submission id = id ].
	
	^ self
]

{ #category : 'accessing' }
ATSubmission >> hasCode [
	^ hasCode ifNil: [ false ]
]

{ #category : 'accessing' }
ATSubmission >> hasCode: aBoolean [
	hasCode := aBoolean
]

{ #category : 'accessing' }
ATSubmission >> hasPdf [
^ hasPdf ifNil: [ false ]
]

{ #category : 'accessing' }
ATSubmission >> hasPdf: aBoolean [
hasPdf := aBoolean
]

{ #category : 'accessing' }
ATSubmission >> id [
^ id
]

{ #category : 'accessing' }
ATSubmission >> id: anId [
id := anId
]

{ #category : 'initialization' }
ATSubmission >> initialize [

	super initialize.
	submittedAt := DateAndTime now.
	status := #pending
]

{ #category : 'testing' }
ATSubmission >> isAccepted [
^ status = #accepted
]

{ #category : 'testing' }
ATSubmission >> isPending [
^ status = #pending
]

{ #category : 'testing' }
ATSubmission >> isRejected [
^ status = #rejected
]

{ #category : 'testing' }
ATSubmission >> isTest [ ^ isTest ifNil: [ false ]
]

{ #category : 'testing' }
ATSubmission >> isTest: aBoolean [ isTest := aBoolean
]

{ #category : 'testing' }
ATSubmission >> markAsTest [ isTest := true
]

{ #category : 'accessing' }
ATSubmission >> notes [
    ^ notes
]

{ #category : 'accessing' }
ATSubmission >> notes: aString [
    notes := aString
]

{ #category : 'accessing' }
ATSubmission >> paperToken [
	^ paperToken
]

{ #category : 'accessing' }
ATSubmission >> paperToken: aString [
	paperToken := aString
]

{ #category : 'accessing' }
ATSubmission >> pdfKey [
^ pdfKey
]

{ #category : 'accessing' }
ATSubmission >> pdfKey: aKey [
pdfKey := aKey
]

{ #category : 'accessing' }
ATSubmission >> pdfUrl [
^ pdfUrl
]

{ #category : 'accessing' }
ATSubmission >> pdfUrl: anObject [
pdfUrl := anObject
]

{ #category : 'accessing' }
ATSubmission >> promptVersion [ ^ promptVersion
]

{ #category : 'accessing' }
ATSubmission >> promptVersion: aString [ promptVersion := aString
]

{ #category : 'actions' }
ATSubmission >> reject [
status := #rejected
]

{ #category : 'accessing' }
ATSubmission >> status [
^ status
]

{ #category : 'accessing' }
ATSubmission >> status: anObject [
status := anObject
]

{ #category : 'accessing' }
ATSubmission >> submittedAt [
^ submittedAt
]

{ #category : 'accessing' }
ATSubmission >> submittedAt: anObject [
submittedAt := anObject
]

{ #category : 'accessing' }
ATSubmission >> title [
^ title
]

{ #category : 'accessing' }
ATSubmission >> title: anObject [
title := anObject
]

{ #category : 'accessing' }
ATSubmission >> track [ ^ track ifNil: [ #workingPaper ]
]

{ #category : 'accessing' }
ATSubmission >> track: aSymbol [ track := aSymbol
]
