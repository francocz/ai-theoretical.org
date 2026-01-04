Class {
	#name : 'ATAuditLog',
	#superclass : 'Object',
	#instVars : [
		'entries',
		'logFile'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATAuditLog class >> current [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
ATAuditLog class >> reset [
	Current := nil
]

{ #category : 'private' }
ATAuditLog >> appendEntry: aDictionary toFile: aFilePath [
    | json |
    json := NeoJSONWriter toString: aDictionary.
    aFilePath asFileReference 
        ensureCreateFile;
        writeStreamDo: [ :s | 
            s setToEnd.
            s nextPutAll: json.
            s nextPut: Character lf ]
]

{ #category : 'querying' }
ATAuditLog >> assessments [
	^ self entriesOfType: 'assessment'
]

{ #category : 'actions' }
ATAuditLog >> clear [
	"Svuota il log"
	entries := OrderedCollection new.
	self saveToFile
]

{ #category : 'querying' }
ATAuditLog >> decisions [
	^ self entriesOfType: 'decision'
]

{ #category : 'accessing' }
ATAuditLog >> entries [
	^ entries
]

{ #category : 'querying' }
ATAuditLog >> entriesOfType: aTypeString [
	"Ritorna tutte le entries di un tipo"
	^ entries select: [ :e | (e at: 'type') = aTypeString ]
]

{ #category : 'querying' }
ATAuditLog >> errors [
	^ self entriesOfType: 'error'
]

{ #category : 'initialization' }
ATAuditLog >> initialize [
	super initialize.
	entries := OrderedCollection new.
	logFile := ATRepository current gitRepoPath, '/logs/audit.json'
]

{ #category : 'persistence' }
ATAuditLog >> loadFromFile [
	"Carica il log da file JSON"
	| file |
	file := logFile asFileReference.
	file exists ifFalse: [ ^ self ].
	entries := OrderedCollection withAll: (NeoJSONReader fromString: file contents)
]

{ #category : 'logging' }
ATAuditLog >> logAssessment: aSubmission verdict: aSymbol assessment: aString config: aDict [
	"Registra una valutazione AI"
	| entry |
	entry := Dictionary new.
	entry at: 'timestamp' put: DateAndTime now asString.
	entry at: 'type' put: 'assessment'.
	entry at: 'submissionId' put: (aSubmission id ifNil: ['unknown']).
	entry at: 'title' put: aSubmission title.
	entry at: 'author' put: aSubmission authorName.
	entry at: 'verdict' put: aSymbol asString.
	entry at: 'provider' put: (aDict at: 'provider' ifAbsent: ['unknown']).
	entry at: 'model' put: (aDict at: 'model' ifAbsent: ['unknown']).
	entry at: 'temperature' put: (aDict at: 'temperature' ifAbsent: [0]).
	entry at: 'promptVersion' put: (aDict at: 'promptVersion' ifAbsent: ['unknown']).
	entry at: 'promptHash' put: (aDict at: 'promptHash' ifAbsent: ['unknown']).
	entry at: 'assessmentLength' put: aString size.
	entry at: 'assessment' put: aString.
	entries add: entry.
	self saveToFile.
	^ entry
]

{ #category : 'logging' }
ATAuditLog >> logDecision: aSymbol forSubmission: aSubmission [
	"Registra una decisione (accept/reject)"
	| entry |
	entry := Dictionary new.
	entry at: 'timestamp' put: DateAndTime now asString.
	entry at: 'type' put: 'decision'.
	entry at: 'submissionId' put: (aSubmission id ifNil: ['unknown']).
	entry at: 'title' put: aSubmission title.
	entry at: 'decision' put: aSymbol asString.
	entries add: entry.
	self saveToFile.
	^ entry
]

{ #category : 'logging' }
ATAuditLog >> logError: aString forSubmission: aSubmission [
	"Registra un errore durante il processing"
	| entry |
	entry := Dictionary new.
	entry at: 'timestamp' put: DateAndTime now asString.
	entry at: 'type' put: 'error'.
	entry at: 'submissionId' put: (aSubmission ifNil: ['unknown'] ifNotNil: [aSubmission id ifNil: ['unknown']]).
	entry at: 'title' put: (aSubmission ifNil: ['unknown'] ifNotNil: [aSubmission title]).
	entry at: 'error' put: aString.
	entries add: entry.
	self saveToFile.
	^ entry
]

{ #category : 'accessing' }
ATAuditLog >> logFile [
	^ logFile
]

{ #category : 'accessing' }
ATAuditLog >> logFile: aPath [
	logFile := aPath
]

{ #category : 'logging' }
ATAuditLog >> logTestAssessment: aSubmission verdict: aVerdict assessment: anAssessment [
    "Log per test - file separato"
    | entry testLogPath |
    entry := Dictionary new
        at: 'timestamp' put: DateAndTime now asString;
        at: 'type' put: 'TEST_ASSESSMENT';
        at: 'submissionId' put: aSubmission id;
        at: 'title' put: aSubmission title;
        at: 'verdict' put: aVerdict;
        at: 'assessment' put: (anAssessment first: (200 min: anAssessment size));
        yourself.
    
    testLogPath := logFilePath asFileReference parent / 'audit_test.log'.
    self appendEntry: entry toFile: testLogPath fullName
]

{ #category : 'querying' }
ATAuditLog >> recentEntries: n [
	"Ritorna le ultime n entries"
	^ entries last: (n min: entries size)
]

{ #category : 'persistence' }
ATAuditLog >> saveToFile [
	"Salva il log su file JSON"
	| dir file |
	dir := logFile asFileReference parent.
	dir ensureCreateDirectory.
	file := logFile asFileReference.
	file writeStreamDo: [ :s |
		s nextPutAll: (NeoJSONWriter toStringPretty: entries asArray) ]
]

{ #category : 'querying' }
ATAuditLog >> statistics [
	"Ritorna statistiche aggregate"
	| assessments accepts rejects |
	assessments := self assessments.
	accepts := assessments count: [ :e | (e at: 'verdict') = 'accept' ].
	rejects := assessments count: [ :e | (e at: 'verdict') = 'reject' ].
	^ Dictionary new
		at: 'totalAssessments' put: assessments size;
		at: 'accepts' put: accepts;
		at: 'rejects' put: rejects;
		at: 'reviews' put: (assessments size - accepts - rejects);
		at: 'errors' put: self errors size;
		at: 'acceptRate' put: (assessments isEmpty ifTrue: [0] ifFalse: [(accepts / assessments size * 100) asFloat]);
		yourself
]
