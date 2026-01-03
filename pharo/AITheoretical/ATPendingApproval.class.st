Class {
	#name : 'ATPendingApproval',
	#superclass : 'Object',
	#instVars : [
		'submission',
		'assessment',
		'verdict',
		'createdAt'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATPendingApproval class >> submission: aSub assessment: anAssessment verdict: aVerdict [
	^ self new
		submission: aSub;
		assessment: anAssessment;
		verdict: aVerdict;
		yourself
]

{ #category : 'accessing' }
ATPendingApproval >> assessment [
	^ assessment
]

{ #category : 'accessing' }
ATPendingApproval >> assessment: aString [
	assessment := aString
]

{ #category : 'accessing' }
ATPendingApproval >> createdAt [
	^ createdAt
]

{ #category : 'initialization' }
ATPendingApproval >> initialize [
	super initialize.
	createdAt := DateAndTime now
]

{ #category : 'accessing' }
ATPendingApproval >> submission [
	^ submission
]

{ #category : 'accessing' }
ATPendingApproval >> submission: anATSubmission [
	submission := anATSubmission
]

{ #category : 'accessing' }
ATPendingApproval >> verdict [
	^ verdict
]

{ #category : 'accessing' }
ATPendingApproval >> verdict: aSymbol [
	verdict := aSymbol
]
