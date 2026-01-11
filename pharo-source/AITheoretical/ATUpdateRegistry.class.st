Class {
	#name : 'ATUpdateRegistry',
	#superclass : 'Object',
	#instVars : [
		'requests',
		'maxPerEmail',
		'maxGlobal'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATUpdateRegistry class >> current [
    ^ (Smalltalk at: #ATUpdateRegistryCurrent) ifNil: [ 
        Smalltalk at: #ATUpdateRegistryCurrent put: self new ]
]

{ #category : 'accessing' }
ATUpdateRegistry class >> reset [
    Smalltalk at: #ATUpdateRegistryCurrent put: nil
]

{ #category : 'rate limiting' }
ATUpdateRegistry >> canRequestForEmail: emailString [
    "Ritorna true se la richiesta è permessa, false altrimenti"
    (self requestsTodayForEmail: emailString) >= maxPerEmail ifTrue: [ ^ false ].
    self requestsTodayGlobal >= maxGlobal ifTrue: [ ^ false ].
    ^ true
]

{ #category : 'maintenance' }
ATUpdateRegistry >> cleanupExpired [
    "Rimuove richieste scadute da più di 48h"
    | cutoff |
    cutoff := DateAndTime now - 48 hours.
    requests removeAllSuchThat: [ :r | r expiresAt < cutoff ]
]

{ #category : 'operations' }
ATUpdateRegistry >> createRequestForEmail: emailString [
    | request |
    (self canRequestForEmail: emailString) ifFalse: [ ^ nil ].
    request := ATUpdateRequest forEmail: emailString.
    requests add: request.
    ^ request
]

{ #category : 'operations' }
ATUpdateRegistry >> findByToken: tokenString [
    ^ requests detect: [ :r | r token = tokenString ] ifNone: [ nil ]
]

{ #category : 'operations' }
ATUpdateRegistry >> findValidByToken: tokenString [
    | request |
    request := self findByToken: tokenString.
    request ifNil: [ ^ nil ].
    request isValid ifFalse: [ ^ nil ].
    ^ request
]

{ #category : 'initialization' }
ATUpdateRegistry >> initialize [
    super initialize.
    requests := OrderedCollection new.
    maxPerEmail := 3.
    maxGlobal := 10
]

{ #category : 'accessing' }
ATUpdateRegistry >> maxGlobal [ ^ maxGlobal
]

{ #category : 'accessing' }
ATUpdateRegistry >> maxPerEmail [ ^ maxPerEmail
]

{ #category : 'rate limiting' }
ATUpdateRegistry >> rateLimitReasonForEmail: emailString [
    "Ritorna nil se ok, altrimenti la ragione del blocco"
    (self requestsTodayForEmail: emailString) >= maxPerEmail 
        ifTrue: [ ^ 'Too many requests for this email today (max ', maxPerEmail asString, ')' ].
    self requestsTodayGlobal >= maxGlobal 
        ifTrue: [ ^ 'Too many global requests today. Please try again tomorrow.' ].
    ^ nil
]

{ #category : 'accessing' }
ATUpdateRegistry >> requests [ ^ requests
]

{ #category : 'rate limiting' }
ATUpdateRegistry >> requestsTodayForEmail: emailString [
    | cutoff |
    cutoff := DateAndTime now - 24 hours.
    ^ requests count: [ :r | 
        r email asLowercase = emailString asLowercase and: [ r createdAt > cutoff ] ]
]

{ #category : 'rate limiting' }
ATUpdateRegistry >> requestsTodayGlobal [
    | cutoff |
    cutoff := DateAndTime now - 24 hours.
    ^ requests count: [ :r | r createdAt > cutoff ]
]
