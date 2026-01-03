Class {
	#name : 'ATRepositoryTest',
	#superclass : 'TestCase',
	#instVars : [
		'repo',
		'tempDir'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'running' }
ATRepositoryTest >> setUp [
	super setUp.
	tempDir := FileLocator temp / ('test-repo-', UUID new asString).
	tempDir ensureCreateDirectory.
	(tempDir / 'papers') ensureCreateDirectory.
	repo := ATRepository new.
	repo gitRepoPath: tempDir pathString
]

{ #category : 'running' }
ATRepositoryTest >> tearDown [
	tempDir ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
ATRepositoryTest >> testAddPaper [
	| paper |
	paper := ATPaper new.
	paper title: 'Test Paper'.
	repo addPaper: paper.
	self assert: repo papers size equals: 1.
	self assert: repo papers first title equals: 'Test Paper'
]

{ #category : 'tests' }
ATRepositoryTest >> testAsJavaScript [
	| paper js |
	paper := ATPaper new.
	paper title: 'Test'.
	paper authors: 'John'.
	repo addPaper: paper.
	js := repo asJavaScript.
	self assert: (js includesSubstring: 'const PAPERS_DATA').
	self assert: (js includesSubstring: 'Test').
	self assert: (js includesSubstring: 'John')
]

{ #category : 'tests' }
ATRepositoryTest >> testDeletePaper [
	| paper pdfFile seoFile |
	paper := ATPaper new title: 'To Delete'.
	repo addPaper: paper.
	"Creo i file simulati"
	pdfFile := (tempDir / 'papers' / (paper slug, '.pdf')).
	seoFile := (tempDir / 'papers' / (paper slug, '.html')).
	pdfFile writeStreamDo: [ :s | s nextPutAll: 'PDF content' ].
	seoFile writeStreamDo: [ :s | s nextPutAll: 'HTML content' ].
	self assert: pdfFile exists.
	self assert: seoFile exists.
	self assert: repo papers size equals: 1.
	"Cancella"
	repo deletePaper: paper.
	self assert: repo papers isEmpty.
	self deny: pdfFile exists.
	self deny: seoFile exists
]

{ #category : 'tests' }
ATRepositoryTest >> testHasSlug [
	| paper |
	self deny: (repo hasSlug: 'test-paper').
	paper := ATPaper new title: 'Test Paper'.
	repo addPaper: paper.
	self assert: (repo hasSlug: 'test-paper')
]

{ #category : 'tests' }
ATRepositoryTest >> testPaperWithSlug [
	| paper found |
	paper := ATPaper new title: 'My Paper'.
	repo addPaper: paper.
	found := repo paperWithSlug: 'my-paper'.
	self assert: found equals: paper.
	self assert: (repo paperWithSlug: 'nonexistent') isNil
]

{ #category : 'tests' }
ATRepositoryTest >> testPendingSubmissions [
	| sub1 sub2 |
	sub1 := ATSubmission new title: 'Pending'.
	sub2 := ATSubmission new title: 'Accepted'.
	sub2 accept.
	repo addSubmission: sub1.
	repo addSubmission: sub2.
	self assert: repo pendingSubmissions size equals: 1.
	self assert: repo pendingSubmissions first title equals: 'Pending'
]

{ #category : 'tests' }
ATRepositoryTest >> testUniqueSlug [
	| paper1 paper2 |
	paper1 := ATPaper new title: 'Test Paper'.
	paper2 := ATPaper new title: 'Test Paper'.
	repo addPaper: paper1.
	repo addPaper: paper2.
	self assert: paper1 slug equals: 'test-paper'.
	self assert: paper2 slug equals: 'test-paper-2'
]
