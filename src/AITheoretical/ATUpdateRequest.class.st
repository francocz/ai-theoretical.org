Class {
	#name : 'ATUpdateRequest',
	#superclass : 'Object',
	#instVars : [
		'email',
		'token',
		'createdAt',
		'expiresAt',
		'status'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATUpdateRequest class >> forEmail: emailString [
    ^ self new
        email: emailString;
        yourself
]

{ #category : 'instance creation' }
ATUpdateRequest class >> fromDictionary: aDict [
    | request statusStr |
    request := self new.
    request instVarNamed: 'email' put: (aDict at: 'email' ifAbsent: [ '' ]).
    request instVarNamed: 'token' put: (aDict at: 'token' ifAbsent: [ '' ]).
    (aDict at: 'createdAt' ifAbsent: [ nil ]) ifNotNil: [ :s |
        request instVarNamed: 'createdAt' put: (DateAndTime fromString: s) ].
    (aDict at: 'expiresAt' ifAbsent: [ nil ]) ifNotNil: [ :s |
        request instVarNamed: 'expiresAt' put: (DateAndTime fromString: s) ].
    statusStr := aDict at: 'status' ifAbsent: [ 'pending' ].
    request instVarNamed: 'status' put: statusStr asSymbol.
    ^ request
]

{ #category : 'converting' }
ATUpdateRequest >> asDictionary [
    ^ Dictionary new
        at: 'email' put: email;
        at: 'token' put: token;
        at: 'createdAt' put: createdAt asString;
        at: 'expiresAt' put: expiresAt asString;
        at: 'status' put: status asString;
        yourself
]

{ #category : 'accessing' }
ATUpdateRequest >> createdAt [ ^ createdAt
]

{ #category : 'accessing' }
ATUpdateRequest >> email [ ^ email
]

{ #category : 'accessing' }
ATUpdateRequest >> email: aString [ email := aString
]

{ #category : 'accessing' }
ATUpdateRequest >> expiresAt [ ^ expiresAt
]

{ #category : 'initialization' }
ATUpdateRequest >> initialize [
    super initialize.
    createdAt := DateAndTime now.
    expiresAt := createdAt + 24 hours.
    status := #pending.
    token := UUID new asString36
]

{ #category : 'testing' }
ATUpdateRequest >> isExpired [
    ^ DateAndTime now > expiresAt
]

{ #category : 'testing' }
ATUpdateRequest >> isValid [
    ^ self isExpired not and: [ status = #pending ]
]

{ #category : 'actions' }
ATUpdateRequest >> markUsed [
    status := #used
]

{ #category : 'accessing' }
ATUpdateRequest >> status [ ^ status
]

{ #category : 'accessing' }
ATUpdateRequest >> status: aSymbol [ status := aSymbol
]

{ #category : 'accessing' }
ATUpdateRequest >> token [ ^ token
]
