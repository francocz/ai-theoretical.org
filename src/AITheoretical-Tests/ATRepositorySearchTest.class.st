Class {
	#name : 'ATRepositorySearchTest',
	#superclass : 'TestCase',
	#instVars : [
		'repo'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'running' }
ATRepositorySearchTest >> setUp [
	| p1 p2 p3 |
	super setUp.
	repo := ATRepository new.
	repo gitRepoPath: '/tmp/test-repo'.
	
	p1 := ATPaper new.
	p1 title: 'Quantum Consciousness and AI'.
	p1 authors: 'John Smith'.
	p1 abstract: 'This paper explores the intersection of quantum mechanics and artificial intelligence.'.
	p1 date: '2025-01-15'.
	p1 aiModels: 'Claude 3.5'.
	p1 slug: 'quantum-consciousness'.
	repo papers add: p1.
	
	p2 := ATPaper new.
	p2 title: 'Ethics of Machine Learning'.
	p2 authors: 'Jane Doe'.
	p2 abstract: 'A comprehensive study on ethical considerations in ML systems.'.
	p2 date: '2024-06-20'.
	p2 aiModels: 'GPT-4'.
	p2 slug: 'ethics-ml'.
	repo papers add: p2.
	
	p3 := ATPaper new.
	p3 title: 'Philosophical Foundations of AI'.
	p3 authors: 'John Smith'.
	p3 abstract: 'Examining the philosophical roots of artificial intelligence research.'.
	p3 date: '2025-03-10'.
	p3 aiModels: 'Claude 3.5'.
	p3 slug: 'philosophical-foundations'.
	repo papers add: p3
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchByAbstract [
	| results |
	results := repo searchByAbstract: 'quantum mechanics'.
	self assert: results size equals: 1.
	
	results := repo searchByAbstract: 'artificial intelligence'.
	self assert: results size equals: 2
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchByAuthor [
	| results |
	results := repo searchByAuthor: 'John Smith'.
	self assert: results size equals: 2.
	
	results := repo searchByAuthor: 'Jane'.
	self assert: results size equals: 1.
	self assert: results first title equals: 'Ethics of Machine Learning'
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchByAuthorCaseInsensitive [
	| results |
	results := repo searchByAuthor: 'john smith'.
	self assert: results size equals: 2.
	
	results := repo searchByAuthor: 'JANE'.
	self assert: results size equals: 1
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchByTitle [
	| results |
	results := repo searchByTitle: 'Quantum'.
	self assert: results size equals: 1.
	self assert: results first authors equals: 'John Smith'.
	
	results := repo searchByTitle: 'AI'.
	self assert: results size equals: 2
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchByYear [
	| results |
	results := repo searchByYear: 2025.
	self assert: results size equals: 2.
	
	results := repo searchByYear: 2024.
	self assert: results size equals: 1.
	self assert: results first authors equals: 'Jane Doe'
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchEmptyQuery [
	| results |
	results := repo search: ''.
	self assert: results size equals: 3
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchFullText [
	| results |
	results := repo search: 'quantum'.
	self assert: results size equals: 1.
	
	results := repo search: 'John'.
	self assert: results size equals: 2.
	
	results := repo search: 'ethical'.
	self assert: results size equals: 1
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchNoResults [
	| results |
	results := repo searchByAuthor: 'Nobody'.
	self assert: results isEmpty.
	
	results := repo searchByTitle: 'Nonexistent'.
	self assert: results isEmpty
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchWithCriteria [
	| results criteria |
	criteria := Dictionary new.
	criteria at: 'author' put: 'John Smith'.
	results := repo searchWithCriteria: criteria.
	self assert: results size equals: 2.
	
	criteria at: 'year' put: '2025'.
	results := repo searchWithCriteria: criteria.
	self assert: results size equals: 2.
	
	criteria at: 'title' put: 'Quantum'.
	results := repo searchWithCriteria: criteria.
	self assert: results size equals: 1
]

{ #category : 'tests' }
ATRepositorySearchTest >> testSearchWithKeywords [
	| results criteria |
	criteria := Dictionary new.
	criteria at: 'keywords' put: 'quantum consciousness'.
	results := repo searchWithCriteria: criteria.
	self assert: results size equals: 1.
	
	criteria at: 'keywords' put: 'artificial intelligence'.
	results := repo searchWithCriteria: criteria.
	self assert: results size equals: 2
]
