Class {
	#name : 'ATRejectedRepositoryTest',
	#superclass : 'TestCase',
	#instVars : [
		'tempDir',
		'originalFilePath'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'running' }
ATRejectedRepositoryTest >> setUp [
    super setUp.
    tempDir := FileLocator temp / ('attest-', UUID new asString).
    tempDir asFileReference ensureCreateDirectory.
    ATRejectedRepository reset
]

{ #category : 'running' }
ATRejectedRepositoryTest >> tearDown [
    tempDir ifNotNil: [ tempDir asFileReference ensureDeleteAll ].
    ATRejectedRepository reset.
    super tearDown
]

{ #category : 'tests' }
ATRejectedRepositoryTest >> testAddAndSave [
    | repo rejected testFile |
    testFile := tempDir asFileReference / 'rejected.ston'.
    
    repo := ATRejectedRepository current.
    repo filePath: testFile fullName.
    
    rejected := ATRejectedSubmission new
        id: 'test-1';
        title: 'Test Paper';
        authorName: 'Test Author';
        yourself.
    
    repo add: rejected.
    
    self assert: repo rejectedSubmissions size equals: 1.
    self assert: testFile exists
]

{ #category : 'tests' }
ATRejectedRepositoryTest >> testLoadNonExistentFile [
    | repo |
    repo := ATRejectedRepository current.
    repo filePath: (tempDir asFileReference / 'nonexistent.ston') fullName.
    
    repo load.
    
    self assert: repo rejectedSubmissions isEmpty
]

{ #category : 'tests' }
ATRejectedRepositoryTest >> testMultipleRejections [
    | repo testFile |
    testFile := tempDir asFileReference / 'rejected.ston'.
    
    repo := ATRejectedRepository current.
    repo filePath: testFile fullName.
    
    1 to: 3 do: [ :i |
        repo add: (ATRejectedSubmission new
            id: 'test-', i asString;
            title: 'Paper ', i asString;
            yourself) ].
    
    self assert: repo rejectedSubmissions size equals: 3.
    
    ATRejectedRepository reset.
    repo := ATRejectedRepository current.
    repo filePath: testFile fullName.
    repo load.
    
    self assert: repo rejectedSubmissions size equals: 3
]

{ #category : 'tests' }
ATRejectedRepositoryTest >> testSaveAndLoad [
    | repo rejected testFile loadedRepo |
    testFile := tempDir asFileReference / 'rejected.ston'.
    
    repo := ATRejectedRepository current.
    repo filePath: testFile fullName.
    
    rejected := ATRejectedSubmission new
        id: 'test-load';
        title: 'Persistence Test';
        authorName: 'Loader';
        yourself.
    
    repo add: rejected.
    
    ATRejectedRepository reset.
    loadedRepo := ATRejectedRepository current.
    loadedRepo filePath: testFile fullName.
    loadedRepo load.
    
    self assert: loadedRepo rejectedSubmissions size equals: 1.
    self assert: loadedRepo rejectedSubmissions first id equals: 'test-load'.
    self assert: loadedRepo rejectedSubmissions first title equals: 'Persistence Test'
]

{ #category : 'tests' }
ATRejectedRepositoryTest >> testSingleton [
    | repo1 repo2 |
    repo1 := ATRejectedRepository current.
    repo2 := ATRejectedRepository current.
    self assert: repo1 identicalTo: repo2
]
