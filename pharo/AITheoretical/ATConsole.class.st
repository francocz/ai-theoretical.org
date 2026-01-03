Class {
	#name : 'ATConsole',
	#superclass : 'SpPresenter',
	#instVars : [
		'submissionList',
		'detailText',
		'assessmentText',
		'collaborationText',
		'notesText',
		'syncButton',
		'acceptButton',
		'rejectButton',
		'deployButton',
		'selectedSubmission'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATConsole class >> open [
	^ self new open
]

{ #category : 'actions' }
ATConsole >> clearFields [
	detailText text: ''.
	assessmentText text: ''.
	collaborationText text: ''.
	notesText text: ''.
	selectedSubmission := nil
]

{ #category : 'layout' }
ATConsole >> defaultLayout [
	^ SpBoxLayout newVertical
		add: (SpBoxLayout newHorizontal
			add: syncButton width: 80;
			add: deployButton width: 80;
			yourself) height: 30;
		add: (SpPanedLayout newHorizontal
			add: submissionList;
			add: (SpBoxLayout newVertical
				add: 'Details' expand: false;
				add: detailText;
				add: 'Assessment' expand: false;
				add: assessmentText;
				add: 'Collaboration' expand: false;
				add: collaborationText height: 60;
				add: 'Notes' expand: false;
				add: notesText height: 60;
				add: (SpBoxLayout newHorizontal
					add: acceptButton;
					add: rejectButton;
					yourself) height: 30;
				yourself);
			yourself);
		yourself
]

{ #category : 'actions' }
ATConsole >> doAccept [
	selectedSubmission ifNil: [ ^ self ].
	ATRepository current
		acceptRemoteSubmission: selectedSubmission
		withAssessment: assessmentText text asString
		withCollaboration: collaborationText text asString
		withNotes: notesText text asString.
	self clearFields.
	self refreshList
]

{ #category : 'actions' }
ATConsole >> doDeploy [
	ATRepository current deploy
]

{ #category : 'actions' }
ATConsole >> doReject [
	selectedSubmission ifNil: [ ^ self ].
	ATRepository current rejectRemoteSubmission: selectedSubmission.
	self clearFields.
	self refreshList
]

{ #category : 'actions' }
ATConsole >> doSync [
	ATRepository current syncSubmissions.
	self refreshList
]

{ #category : 'initialization' }
ATConsole >> initializePresenters [
	submissionList := self newList.
	submissionList display: [ :sub | sub title, ' - ', sub authorName ].
	submissionList whenSelectionChangedDo: [ :sel | self onSubmissionSelected: sel selectedItem ].
	detailText := self newText.
	detailText beNotEditable.
	assessmentText := self newText.
	assessmentText placeholder: 'AI Assessment...'.
	collaborationText := self newText.
	collaborationText placeholder: 'AI Collaboration description...'.
	notesText := self newText.
	notesText placeholder: 'Notes...'.
	syncButton := self newButton label: 'Sync'; yourself.
	syncButton action: [ self doSync ].
	acceptButton := self newButton label: 'Accept'; yourself.
	acceptButton action: [ self doAccept ].
	rejectButton := self newButton label: 'Reject'; yourself.
	rejectButton action: [ self doReject ].
	deployButton := self newButton label: 'Deploy'; yourself.
	deployButton action: [ self doDeploy ]
]

{ #category : 'initialization' }
ATConsole >> initializeWindow: aWindowPresenter [
	aWindowPresenter
		title: 'AI-Theoretical Console';
		initialExtent: 900@600
]

{ #category : 'actions' }
ATConsole >> onSubmissionSelected: aSubmission [
	selectedSubmission := aSubmission.
	aSubmission ifNil: [
		detailText text: ''.
		^ self ].
	detailText text: (String streamContents: [ :s2 |
		s2 nextPutAll: 'Title: '; nextPutAll: aSubmission title; cr.
		s2 nextPutAll: 'Author: '; nextPutAll: aSubmission authorName; cr.
		s2 nextPutAll: 'Email: '; nextPutAll: aSubmission authorEmail; cr.
		s2 nextPutAll: 'Submitted: '; nextPutAll: aSubmission submittedAt asString; cr; cr.
		s2 nextPutAll: 'Abstract:'; cr.
		s2 nextPutAll: aSubmission abstract ])
]

{ #category : 'actions' }
ATConsole >> refreshList [
	submissionList items: ATRepository current pendingSubmissions
]
