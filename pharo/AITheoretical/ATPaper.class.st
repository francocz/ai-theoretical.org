Class {
	#name : 'ATPaper',
	#superclass : 'Object',
	#instVars : [
		'title',
		'authors',
		'aiModels',
		'date',
		'pages',
		'pdfFile',
		'abstract',
		'aiAssessment',
		'aiCollaboration',
		'slug',
		'notes',
		'version',
		'status',
		'withdrawalReason',
		'submissionId',
		'assessmentPromptVersion'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATPaper class >> fromDictionary: aDict [
	"Crea un ATPaper da un dizionario"
	| paper statusStr |
	paper := self new
		title: (aDict at: 'title' ifAbsent: [ '' ]);
		authors: (aDict at: 'author' ifAbsent: [ '' ]);
		aiModels: (aDict at: 'ai_model' ifAbsent: [ '' ]);
		date: (aDict at: 'date' ifAbsent: [ '' ]);
		pages: (aDict at: 'pages' ifAbsent: [ '' ]);
		pdfFile: (aDict at: 'pdf_file' ifAbsent: [ '' ]);
		abstract: (aDict at: 'abstract' ifAbsent: [ '' ]);
		aiAssessment: (aDict at: 'ai_assessment' ifAbsent: [ '' ]);
		aiCollaboration: (aDict at: 'ai_collaboration' ifAbsent: [ '' ]);
		notes: (aDict at: 'notes' ifAbsent: [ '' ]);
		version: (aDict at: 'version' ifAbsent: [ 1 ]);
		withdrawalReason: (aDict at: 'withdrawal_reason' ifAbsent: [ nil ]);
		submissionId: (aDict at: 'submission_id' ifAbsent: [ nil ]);
		assessmentPromptVersion: (aDict at: 'assessment_prompt_version' ifAbsent: [ nil ]);
		yourself.
	"Parse status"
	statusStr := aDict at: 'status' ifAbsent: [ 'active' ].
	paper status: statusStr asSymbol.
	"Usa slug salvato se presente, altrimenti genera"
	(aDict at: 'slug' ifAbsent: [ nil ])
		ifNotNil: [ :s2 | paper slug: s2 ]
		ifNil: [ paper generateSlug ].
	^ paper
]

{ #category : 'accessing' }
ATPaper >> abstract [
^ abstract
]

{ #category : 'accessing' }
ATPaper >> abstract: anObject [
abstract := anObject
]

{ #category : 'accessing' }
ATPaper >> aiAssessment [
^ aiAssessment
]

{ #category : 'accessing' }
ATPaper >> aiAssessment: anObject [
aiAssessment := anObject
]

{ #category : 'accessing' }
ATPaper >> aiCollaboration [
^ aiCollaboration
]

{ #category : 'accessing' }
ATPaper >> aiCollaboration: anObject [
aiCollaboration := anObject
]

{ #category : 'accessing' }
ATPaper >> aiModels [
^ aiModels
]

{ #category : 'accessing' }
ATPaper >> aiModels: anObject [
aiModels := anObject
]

{ #category : 'converting' }
ATPaper >> asDictionary [
	^ Dictionary new
		at: 'title' put: title;
		at: 'author' put: authors;
		at: 'ai_model' put: aiModels;
		at: 'date' put: date;
		at: 'pages' put: pages;
		at: 'pdf_file' put: pdfFile;
		at: 'abstract' put: (abstract ifNil: [ '' ]);
		at: 'ai_assessment' put: (aiAssessment ifNil: [ '' ]);
		at: 'ai_collaboration' put: (aiCollaboration ifNil: [ '' ]);
		at: 'notes' put: (notes ifNil: [ '' ]);
		at: 'slug' put: slug;
		at: 'version' put: self version;
		at: 'status' put: self status asString;
		at: 'withdrawal_reason' put: (withdrawalReason ifNil: [ '' ]);
		at: 'submission_id' put: (submissionId ifNil: [ '' ]);
		at: 'assessment_prompt_version' put: (assessmentPromptVersion ifNil: [ '' ]);
		yourself
]

{ #category : 'converting' }
ATPaper >> asJSON [
^ NeoJSONWriter toString: self asDictionary
]

{ #category : 'accessing' }
ATPaper >> assessmentPromptVersion [
	^ assessmentPromptVersion
]

{ #category : 'accessing' }
ATPaper >> assessmentPromptVersion: aString [
	assessmentPromptVersion := aString
]

{ #category : 'accessing' }
ATPaper >> authors [
^ authors
]

{ #category : 'accessing' }
ATPaper >> authors: anObject [
authors := anObject
]

{ #category : 'accessing' }
ATPaper >> date [
^ date
]

{ #category : 'accessing' }
ATPaper >> date: anObject [
date := anObject
]

{ #category : 'initialization' }
ATPaper >> generateSlug [
"Genera uno slug URL-friendly dalle prime 5 parole del titolo"
| words truncated |
words := title substrings.
truncated := (words copyFrom: 1 to: (5 min: words size)) joinUsing: ' '.
slug := (truncated asLowercase copyReplaceAll: ' ' with: '-')
    select: [ :c | c isAlphaNumeric or: [ c = $- ] ]
]

{ #category : 'actions' }
ATPaper >> incrementVersion [
	version := self version + 1
]

{ #category : 'testing' }
ATPaper >> isActive [
	^ self status = #active
]

{ #category : 'testing' }
ATPaper >> isWithdrawn [
	^ self status = #withdrawn
]

{ #category : 'accessing' }
ATPaper >> notes [
^ notes
]

{ #category : 'accessing' }
ATPaper >> notes: anObject [
notes := anObject
]

{ #category : 'accessing' }
ATPaper >> pages [
^ pages
]

{ #category : 'accessing' }
ATPaper >> pages: anObject [
pages := anObject
]

{ #category : 'accessing' }
ATPaper >> pdfFile [
^ pdfFile
]

{ #category : 'accessing' }
ATPaper >> pdfFile: anObject [
pdfFile := anObject
]

{ #category : 'accessing' }
ATPaper >> slug [
^ slug
]

{ #category : 'accessing' }
ATPaper >> slug: anObject [
slug := anObject
]

{ #category : 'accessing' }
ATPaper >> status [
	^ status ifNil: [ #active ]
]

{ #category : 'accessing' }
ATPaper >> status: aSymbol [
	status := aSymbol
]

{ #category : 'accessing' }
ATPaper >> submissionId [
	^ submissionId
]

{ #category : 'accessing' }
ATPaper >> submissionId: aString [
	submissionId := aString
]

{ #category : 'accessing' }
ATPaper >> title [
^ title
]

{ #category : 'accessing' }
ATPaper >> title: anObject [
title := anObject
]

{ #category : 'accessing' }
ATPaper >> version [
	^ version ifNil: [ 1 ]
]

{ #category : 'accessing' }
ATPaper >> version: anInteger [
	version := anInteger
]

{ #category : 'actions' }
ATPaper >> withdraw: aReason [
	status := #withdrawn.
	withdrawalReason := aReason
]

{ #category : 'accessing' }
ATPaper >> withdrawalReason [
	^ withdrawalReason
]

{ #category : 'accessing' }
ATPaper >> withdrawalReason: aString [
	withdrawalReason := aString
]
