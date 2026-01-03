Class {
	#name : 'ATSubmissionTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATSubmissionTest >> testAccept [
	| sub |
	sub := ATSubmission new.
	sub accept.
	self assert: sub isAccepted.
	self deny: sub isPending.
	self assert: sub status equals: #accepted
]

{ #category : 'tests' }
ATSubmissionTest >> testAsPaper [
	| sub paper |
	sub := ATSubmission new.
	sub title: 'Test Title'.
	sub authorName: 'John Doe'.
	sub abstract: 'Test abstract'.
	sub aiModels: 'Claude'.
	paper := sub asPaper.
	self assert: paper title equals: 'Test Title'.
	self assert: paper authors equals: 'John Doe'.
	self assert: paper abstract equals: 'Test abstract'.
	self assert: paper aiModels equals: 'Claude'
]

{ #category : 'tests' }
ATSubmissionTest >> testFromDictionary [
	| dict sub |
	dict := Dictionary new.
	dict at: 'id' put: 'abc123'.
	dict at: 'title' put: 'Test'.
	dict at: 'authorName' put: 'Jane'.
	dict at: 'status' put: 'pending'.
	dict at: 'hasCode' put: true.
	sub := ATSubmission fromDictionary: dict.
	self assert: sub id equals: 'abc123'.
	self assert: sub title equals: 'Test'.
	self assert: sub authorName equals: 'Jane'.
	self assert: sub hasCode
]

{ #category : 'tests' }
ATSubmissionTest >> testHasCode [
	| sub |
	sub := ATSubmission new.
	self deny: sub hasCode.
	sub codeZipKey: 'submissions/abc123-code.zip'.
	self assert: sub hasCode
]

{ #category : 'tests' }
ATSubmissionTest >> testNewSubmissionIsPending [
	| sub |
	sub := ATSubmission new.
	self assert: sub isPending.
	self deny: sub isAccepted.
	self deny: sub isRejected
]

{ #category : 'tests' }
ATSubmissionTest >> testReject [
	| sub |
	sub := ATSubmission new.
	sub reject.
	self assert: sub isRejected.
	self deny: sub isPending.
	self assert: sub status equals: #rejected
]
