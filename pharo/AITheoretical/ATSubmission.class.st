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
		'hasCode'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATSubmission class >> fromDictionary: aDict [
	| submission statusStr |
	submission := self new
		id: (aDict at: 'id' ifAbsent: [ nil ]);
		paperToken: (aDict at: 'paperToken' ifAbsent: [ nil ]);
		authorName: (aDict at: 'authorName' ifAbsent: [ '' ]);
		authorEmail: (aDict at: 'authorEmail' ifAbsent: [ '' ]);
		authorAffiliation: (aDict at: 'authorAffiliation' ifAbsent: [ nil ]);
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
| paper |
paper := (Smalltalk globals at: #ATPaper) new
    title: title;
    authors: authorName;
    aiModels: aiModels;
    abstract: abstract;
    generateSlug;
    yourself.
authorAffiliation ifNotNil: [ :aff |
    paper authors: (authorName, ' (', aff, ')') ].
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

{ #category : 'accessing' }
ATSubmission >> codeZipKey [
	^ codeZipKey
]

{ #category : 'accessing' }
ATSubmission >> codeZipKey: aKey [
	codeZipKey := aKey.
	hasCode := aKey notNil and: [ aKey notEmpty ]
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
