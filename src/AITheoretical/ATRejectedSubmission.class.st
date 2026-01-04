Class {
	#name : 'ATRejectedSubmission',
	#superclass : 'Object',
	#instVars : [
		'id',
		'title',
		'authorName',
		'authorEmail',
		'abstract',
		'assessment',
		'verdict',
		'rejectedAt',
		'originalSubmittedAt',
		'localPdfPath'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATRejectedSubmission class >> fromPendingApproval: aPendingApproval [
    ^ self new
        id: aPendingApproval submission id;
        title: aPendingApproval submission title;
        authorName: aPendingApproval submission authorName;
        authorEmail: aPendingApproval submission authorEmail;
        abstract: aPendingApproval submission abstract;
        assessment: aPendingApproval assessment;
        verdict: aPendingApproval verdict;
        rejectedAt: DateAndTime now;
        originalSubmittedAt: aPendingApproval submission submittedAt;
        yourself
]

{ #category : 'accessing' }
ATRejectedSubmission >> abstract [ ^ abstract
]

{ #category : 'accessing' }
ATRejectedSubmission >> abstract: anObject [ abstract := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> assessment [ ^ assessment
]

{ #category : 'accessing' }
ATRejectedSubmission >> assessment: anObject [ assessment := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> authorEmail [ ^ authorEmail
]

{ #category : 'accessing' }
ATRejectedSubmission >> authorEmail: anObject [ authorEmail := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> authorName [ ^ authorName
]

{ #category : 'accessing' }
ATRejectedSubmission >> authorName: anObject [ authorName := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> id [ ^ id
]

{ #category : 'accessing' }
ATRejectedSubmission >> id: anObject [ id := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> localPdfPath [ ^ localPdfPath
]

{ #category : 'accessing' }
ATRejectedSubmission >> localPdfPath: aString [ localPdfPath := aString
]

{ #category : 'accessing' }
ATRejectedSubmission >> originalSubmittedAt [ ^ originalSubmittedAt
]

{ #category : 'accessing' }
ATRejectedSubmission >> originalSubmittedAt: anObject [ originalSubmittedAt := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> rejectedAt [ ^ rejectedAt
]

{ #category : 'accessing' }
ATRejectedSubmission >> rejectedAt: anObject [ rejectedAt := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> title [ ^ title
]

{ #category : 'accessing' }
ATRejectedSubmission >> title: anObject [ title := anObject
]

{ #category : 'accessing' }
ATRejectedSubmission >> verdict [ ^ verdict
]

{ #category : 'accessing' }
ATRejectedSubmission >> verdict: anObject [ verdict := anObject
]
