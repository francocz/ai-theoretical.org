Class {
	#name : 'ATAuditLogTest',
	#superclass : 'TestCase',
	#instVars : [
		'auditLog',
		'tempFile'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'running' }
ATAuditLogTest >> setUp [
	super setUp.
	auditLog := ATAuditLog new.
	tempFile := '/tmp/test-audit-' , UUID new asString, '.json'.
	auditLog logFile: tempFile
]

{ #category : 'running' }
ATAuditLogTest >> tearDown [
	tempFile asFileReference ensureDelete.
	super tearDown
]

{ #category : 'tests' }
ATAuditLogTest >> testClear [
	| submission config |
	submission := ATSubmission new.
	submission id: 'c'. submission title: 'C'. submission authorName: 'A'.
	config := Dictionary new.
	
	auditLog logAssessment: submission verdict: #accept assessment: 'x' config: config.
	self assert: auditLog entries size equals: 1.
	
	auditLog clear.
	self assert: auditLog entries isEmpty
]

{ #category : 'tests' }
ATAuditLogTest >> testEntriesOfType [
	| submission config |
	submission := ATSubmission new.
	submission id: 't'. submission title: 'T'. submission authorName: 'A'.
	config := Dictionary new.
	
	auditLog logAssessment: submission verdict: #accept assessment: 'ok' config: config.
	auditLog logDecision: #accept forSubmission: submission.
	auditLog logError: 'err' forSubmission: submission.
	
	self assert: auditLog assessments size equals: 1.
	self assert: auditLog decisions size equals: 1.
	self assert: auditLog errors size equals: 1
]

{ #category : 'tests' }
ATAuditLogTest >> testInitialize [
	self assert: auditLog entries isEmpty.
	self assert: auditLog logFile equals: tempFile
]

{ #category : 'tests' }
ATAuditLogTest >> testLogAssessment [
	| submission config entry |
	submission := ATSubmission new.
	submission id: 'test-123'.
	submission title: 'Test Paper'.
	submission authorName: 'John Doe'.
	config := Dictionary new.
	config at: 'provider' put: 'anthropic'.
	config at: 'model' put: 'claude-sonnet'.
	config at: 'temperature' put: 0.
	config at: 'promptVersion' put: '2.0'.
	config at: 'promptHash' put: 'abc123'.
	
	entry := auditLog logAssessment: submission verdict: #accept assessment: 'Good paper' config: config.
	
	self assert: auditLog entries size equals: 1.
	self assert: (entry at: 'type') equals: 'assessment'.
	self assert: (entry at: 'submissionId') equals: 'test-123'.
	self assert: (entry at: 'verdict') equals: 'accept'.
	self assert: (entry at: 'provider') equals: 'anthropic'
]

{ #category : 'tests' }
ATAuditLogTest >> testLogDecision [
	| submission entry |
	submission := ATSubmission new.
	submission id: 'test-456'.
	submission title: 'Another Paper'.
	
	entry := auditLog logDecision: #reject forSubmission: submission.
	
	self assert: auditLog entries size equals: 1.
	self assert: (entry at: 'type') equals: 'decision'.
	self assert: (entry at: 'decision') equals: 'reject'
]

{ #category : 'tests' }
ATAuditLogTest >> testLogError [
	| submission entry |
	submission := ATSubmission new.
	submission id: 'test-789'.
	submission title: 'Error Paper'.
	
	entry := auditLog logError: 'Connection timeout' forSubmission: submission.
	
	self assert: auditLog entries size equals: 1.
	self assert: (entry at: 'type') equals: 'error'.
	self assert: (entry at: 'error') equals: 'Connection timeout'
]

{ #category : 'tests' }
ATAuditLogTest >> testPersistence [
	| submission config loaded |
	submission := ATSubmission new.
	submission id: 'persist-test'. submission title: 'Persist'. submission authorName: 'X'.
	config := Dictionary new at: 'provider' put: 'test'; yourself.
	
	auditLog logAssessment: submission verdict: #accept assessment: 'test' config: config.
	
	"Crea nuovo audit log e carica da file"
	loaded := ATAuditLog new.
	loaded logFile: tempFile.
	loaded loadFromFile.
	
	self assert: loaded entries size equals: 1.
	self assert: ((loaded entries first) at: 'submissionId') equals: 'persist-test'
]

{ #category : 'tests' }
ATAuditLogTest >> testRecentEntries [
	| submission config |
	submission := ATSubmission new.
	submission id: 'r'. submission title: 'R'. submission authorName: 'A'.
	config := Dictionary new.
	
	1 to: 10 do: [ :i |
		submission id: 'r', i asString.
		auditLog logAssessment: submission verdict: #accept assessment: 'x' config: config ].
	
	self assert: (auditLog recentEntries: 3) size equals: 3.
	self assert: (auditLog recentEntries: 20) size equals: 10
]

{ #category : 'tests' }
ATAuditLogTest >> testStatistics [
	| submission config stats |
	submission := ATSubmission new.
	submission id: 's1'. submission title: 'P1'. submission authorName: 'A'.
	config := Dictionary new.
	config at: 'provider' put: 'test'.
	
	auditLog logAssessment: submission verdict: #accept assessment: 'ok' config: config.
	auditLog logAssessment: submission verdict: #accept assessment: 'ok' config: config.
	auditLog logAssessment: submission verdict: #reject assessment: 'no' config: config.
	
	stats := auditLog statistics.
	
	self assert: (stats at: 'totalAssessments') equals: 3.
	self assert: (stats at: 'accepts') equals: 2.
	self assert: (stats at: 'rejects') equals: 1.
	self assert: ((stats at: 'acceptRate') between: 66.6 and: 66.7)
]
