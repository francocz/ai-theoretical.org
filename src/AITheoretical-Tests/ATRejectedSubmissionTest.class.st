Class {
	#name : 'ATRejectedSubmissionTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATRejectedSubmissionTest >> testAccessors [
    | rejected |
    rejected := ATRejectedSubmission new.
    
    rejected id: 'abc'.
    self assert: rejected id equals: 'abc'.
    
    rejected title: 'My Title'.
    self assert: rejected title equals: 'My Title'.
    
    rejected localPdfPath: '/tmp/test.pdf'.
    self assert: rejected localPdfPath equals: '/tmp/test.pdf'
]

{ #category : 'tests' }
ATRejectedSubmissionTest >> testFromPendingApproval [
    | submission pendingApproval rejected |
    submission := ATSubmission new
        id: 'test-123';
        title: 'Test Paper';
        authorName: 'John Doe';
        authorEmail: 'john@test.com';
        abstract: 'Test abstract';
        yourself.
    
    pendingApproval := ATPendingApproval 
        submission: submission 
        assessment: 'Test assessment' 
        verdict: #reject.
    
    rejected := ATRejectedSubmission fromPendingApproval: pendingApproval.
    
    self assert: rejected id equals: 'test-123'.
    self assert: rejected title equals: 'Test Paper'.
    self assert: rejected authorName equals: 'John Doe'.
    self assert: rejected authorEmail equals: 'john@test.com'.
    self assert: rejected abstract equals: 'Test abstract'.
    self assert: rejected assessment equals: 'Test assessment'.
    self assert: rejected verdict equals: #reject.
    self assert: rejected rejectedAt notNil
]
