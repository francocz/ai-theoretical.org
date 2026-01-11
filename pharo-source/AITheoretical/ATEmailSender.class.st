Class {
	#name : 'ATEmailSender',
	#superclass : 'Object',
	#instVars : [
		'apiUrl',
		'apiKey'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATEmailSender class >> sendTo: email subject: subject body: body [
    "Invia email con solo testo"
    self new sendTo: email subject: subject text: body html: nil
]

{ #category : 'instance creation' }
ATEmailSender class >> withApiKey: aString [
	^ self new apiKey: aString; yourself
]

{ #category : 'accessing' }
ATEmailSender >> apiKey [
	^ apiKey
]

{ #category : 'accessing' }
ATEmailSender >> apiKey: aString [
	apiKey := aString
]

{ #category : 'initialization' }
ATEmailSender >> initialize [
	super initialize.
	apiUrl := 'https://ai-theoretical.org/api/send-email'
]

{ #category : 'templates' }
ATEmailSender >> sendAcceptanceTo: aSubmission withAssessment: assessment [

	| subject text lf |
	lf := String lf.
	subject := 'Your paper has been accepted - AI-Theoretical'.
	text := 'Dear ' , aSubmission authorName , ',' , lf , lf
	        , 'Your paper "' , aSubmission title
	        , '" has been accepted for publication on AI-Theoretical.'
	        , lf , lf , '=== AI ASSESSMENT ===' , lf , assessment , lf
	        , lf
	        ,
	        'Your paper is now available at: https://ai-theoretical.org'
	        , lf , lf , 'Your paper token for future modifications: '
	        , aSubmission paperToken , lf
	        ,
	        'Keep this token safe - you will need it to request modifications or withdrawal.'
	        , lf , lf , 'Best regards,' , lf
	        , 'AI-Theoretical Editorial System'.
	^ self
		  sendTo: aSubmission authorEmail
		  subject: subject
		  text: text
		  html: nil
]

{ #category : 'templates' }
ATEmailSender >> sendRejectionTo: aSubmission withAssessment: assessment [
	| subject text lf |
	lf := String lf.
	subject := 'Regarding your submission - AI-Theoretical'.
	text := 'Dear ', aSubmission authorName, ',' , lf , lf ,
		'Thank you for your submission "' , aSubmission title , '" to AI-Theoretical.' , lf , lf ,
		'After careful review, we regret to inform you that your paper has not been accepted for publication at this time.' , lf , lf ,
		'=== AI ASSESSMENT ===' , lf , assessment , lf , lf ,
		'We encourage you to consider the feedback above and welcome future submissions.' , lf , lf ,
		'Best regards,' , lf ,
		'AI-Theoretical Editorial System'.
	^ self sendTo: aSubmission authorEmail subject: subject text: text html: nil
]

{ #category : 'as yet unclassified' }
ATEmailSender >> sendRevisionRequestTo: aSubmission withAssessment: assessment [
    | subject text lf |
    lf := String lf.
    subject := 'Revision requested - AI-Theoretical'.
    text := 'Dear ', aSubmission authorName, ',' , lf , lf ,
        'Thank you for your submission "' , aSubmission title , '" to AI-Theoretical.' , lf , lf ,
        'Our review indicates that your paper shows promise but requires revision before it can be considered for publication.' , lf , lf ,
        '=== AI ASSESSMENT ===' , lf , assessment , lf , lf ,
        'We invite you to revise your paper based on the feedback above and resubmit. Please note that resubmissions are treated as new submissions and will undergo a fresh review.' , lf , lf ,
        'Best regards,' , lf ,
        'AI-Theoretical Editorial System'.
    ^ self sendTo: aSubmission authorEmail subject: subject text: text html: nil
]

{ #category : 'sending' }
ATEmailSender >> sendTo: email subject: subject text: textBody html: htmlBody [
	| client payload response |
	client := ZnClient new.
	client url: apiUrl.
	client headerAt: 'Authorization' put: 'Bearer ', apiKey.
	client headerAt: 'Content-Type' put: 'application/json'.
	payload := Dictionary new.
	payload at: 'to' put: email.
	payload at: 'subject' put: subject.
	payload at: 'textBody' put: textBody.
	htmlBody ifNotNil: [ payload at: 'htmlBody' put: htmlBody ].
	client entity: (ZnEntity json: (NeoJSONWriter toString: payload)).
	client post.
	response := NeoJSONReader fromString: client contents.
	^ response at: 'success' ifAbsent: [ false ]
]
