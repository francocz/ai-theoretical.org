Class {
	#name : 'ATPaperTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATPaperTest >> testAsDictionary [
	| paper dict |
	paper := ATPaper new.
	paper title: 'Test'.
	paper authors: 'John Doe'.
	paper abstract: 'An abstract'.
	paper slug: 'test'.
	dict := paper asDictionary.
	self assert: (dict at: 'title') equals: 'Test'.
	self assert: (dict at: 'author') equals: 'John Doe'.
	self assert: (dict at: 'abstract') equals: 'An abstract'
]

{ #category : 'tests' }
ATPaperTest >> testAssessmentPromptVersion [
	| paper dict |
	paper := ATPaper new.
	paper title: 'Test'.
	paper assessmentPromptVersion: '2.0'.
	self assert: paper assessmentPromptVersion equals: '2.0'.
	dict := paper asDictionary.
	self assert: (dict at: 'assessment_prompt_version') equals: '2.0'
]

{ #category : 'tests' }
ATPaperTest >> testFromDictionary [
	| dict paper |
	dict := Dictionary new.
	dict at: 'title' put: 'Test Paper'.
	dict at: 'author' put: 'Jane Doe'.
	dict at: 'version' put: 2.
	dict at: 'status' put: 'active'.
	dict at: 'slug' put: 'test-paper'.
	paper := ATPaper fromDictionary: dict.
	self assert: paper title equals: 'Test Paper'.
	self assert: paper authors equals: 'Jane Doe'.
	self assert: paper version equals: 2
]

{ #category : 'tests' }
ATPaperTest >> testNewPaperHasDefaults [
	| paper |
	paper := ATPaper new.
	self assert: paper version equals: 1.
	self assert: paper status equals: #active.
	self assert: paper isActive.
	self deny: paper isWithdrawn
]

{ #category : 'tests' }
ATPaperTest >> testSlugGeneration [
	| paper |
	paper := ATPaper new.
	paper title: 'The Future of AI-Human Collaboration'.
	paper generateSlug.
	"5 words: The Future of AI-Human Collaboration = the-future-of-ai-human-collaboration"
	self assert: paper slug equals: 'the-future-of-ai-human-collaboration'
]

{ #category : 'tests' }
ATPaperTest >> testVersionIncrement [
	| paper |
	paper := ATPaper new.
	self assert: paper version equals: 1.
	paper incrementVersion.
	self assert: paper version equals: 2.
	paper incrementVersion.
	self assert: paper version equals: 3
]

{ #category : 'tests' }
ATPaperTest >> testWithdraw [
	| paper |
	paper := ATPaper new.
	paper title: 'Test Paper'.
	paper withdraw: 'Author requested withdrawal'.
	self assert: paper isWithdrawn.
	self deny: paper isActive.
	self assert: paper status equals: #withdrawn.
	self assert: paper withdrawalReason equals: 'Author requested withdrawal'
]
