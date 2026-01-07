Class {
	#name : 'ATAutomationTest',
	#superclass : 'TestCase',
	#instVars : [
		'automation'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'as yet unclassified' }
ATAutomationTest >> setUp [
    super setUp.
    automation := ATAutomation new.
    automation semiAuto
]

{ #category : 'as yet unclassified' }
ATAutomationTest >> testExecuteDecisionInvalidVerdict [
    | submission |
    submission := ATSubmission new.
    submission id: 'test-exec-1'.
    submission title: 'Test Paper'.
    
    self should: [
        automation executeDecision: #invalid forSubmission: submission withAssessment: 'Test'
    ] raise: Error
]

{ #category : 'as yet unclassified' }
ATAutomationTest >> testParseVerdictAccept [
    self assert: (automation parseVerdict: 'Editorial outcome: Suitable for inclusion') equals: #accept.
    self assert: (automation parseVerdict: 'Blah blah
Editorial outcome: Suitable for inclusion
More text') equals: #accept
]

{ #category : 'as yet unclassified' }
ATAutomationTest >> testParseVerdictAiFailure [
    "Empty assessment"
    self assert: (automation parseVerdict: '') equals: #aiFailure.
    
    "Nil assessment"
    self assert: (automation parseVerdict: nil) equals: #aiFailure.
    
    "No Editorial outcome line"
    self assert: (automation parseVerdict: 'This is some text without verdict') equals: #aiFailure.
    
    "Editorial outcome with unrecognized value"
    self assert: (automation parseVerdict: 'Editorial outcome: Something else entirely') equals: #aiFailure
]

{ #category : 'as yet unclassified' }
ATAutomationTest >> testParseVerdictReject [
    self assert: (automation parseVerdict: 'Editorial outcome: Not suitable for this venue') equals: #reject
]

{ #category : 'as yet unclassified' }
ATAutomationTest >> testParseVerdictReview [
    self assert: (automation parseVerdict: 'Editorial outcome: Needs revision before publication') equals: #review
]
