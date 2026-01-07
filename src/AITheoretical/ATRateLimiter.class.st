Class {
	#name : 'ATRateLimiter',
	#superclass : 'Object',
	#instVars : [
		'dailyLimit',
		'dailyCount',
		'lastResetDate',
		'alertEmail',
		'alertSent',
		'configPath'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATRateLimiter class >> current [
    ^ Current ifNil: [ Current := self new initialize ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter class >> reset [
    Current := nil
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> alertEmail [ ^ alertEmail
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> alertEmail: anEmail [ alertEmail := anEmail
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> canAcceptSubmission [
    "Controlla se possiamo accettare una nuova submission"
    self resetIfNewDay.
    ^ dailyCount < dailyLimit
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> checkAndAlert [
    "Invia alert se siamo al 80% o al 100% del limite"
    | threshold |
    alertEmail ifNil: [ ^ self ].
    
    "Alert al 80%"
    threshold := (dailyLimit * 0.8) ceiling.
    (dailyCount = threshold and: [ alertSent not ]) ifTrue: [
        self sendAlert: 'Warning: 80% of daily submission limit reached (', dailyCount asString, '/', dailyLimit asString, ')'.
        alertSent := true ].
    
    "Alert al 100%"
    dailyCount = dailyLimit ifTrue: [
        self sendAlert: 'CRITICAL: Daily submission limit reached (', dailyLimit asString, '). New submissions will be rejected.' ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> dailyCount [ ^ dailyCount
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> dailyLimit [ ^ dailyLimit
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> dailyLimit: aNumber [ dailyLimit := aNumber
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> initialize [
    dailyLimit := 50. "massimo 50 submissions al giorno"
    dailyCount := 0.
    lastResetDate := Date today.
    alertEmail := nil.
    alertSent := false.
    configPath := '/Users/Franco/Dropbox/ai-theoretical.org/private-data/rate-limit.ston'
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> load [
    "Carica stato salvato"
    | file data |
    file := configPath asFileReference.
    file exists ifFalse: [ ^ self ].
    data := file readStreamDo: [ :s | STON fromStream: s ].
    dailyLimit := data at: 'dailyLimit' ifAbsent: [ 50 ].
    dailyCount := data at: 'dailyCount' ifAbsent: [ 0 ].
    lastResetDate := [ Date fromString: (data at: 'lastResetDate') ] on: Error do: [ Date today ].
    alertEmail := data at: 'alertEmail' ifAbsent: [ nil ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> registerSubmission [
    "Registra una nuova submission"
    self resetIfNewDay.
    dailyCount := dailyCount + 1.
    self save.
    self checkAndAlert.
    ^ dailyCount <= dailyLimit
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> remainingToday [
    "Quante submissions restano oggi"
    self resetIfNewDay.
    ^ (dailyLimit - dailyCount) max: 0
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> resetIfNewDay [
    "Resetta il contatore se è un nuovo giorno"
    Date today > lastResetDate ifTrue: [
        dailyCount := 0.
        lastResetDate := Date today.
        alertSent := false.
        self save ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> save [
    "Salva stato corrente"
    | file data |
    file := configPath asFileReference.
    file parent ensureCreateDirectory.
    data := Dictionary new
        at: 'dailyLimit' put: dailyLimit;
        at: 'dailyCount' put: dailyCount;
        at: 'lastResetDate' put: lastResetDate asString;
        at: 'alertEmail' put: alertEmail;
        yourself.
    file writeStreamDo: [ :s | STON put: data onStream: s ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> sendAlert: aMessage [
    "Invia email di alert"
    [ ATEmailSender new
        to: alertEmail;
        subject: '[ai-theoretical.org] Rate Limit Alert';
        body: aMessage, String cr, String cr, 'Date: ', Date today asString;
        send ]
        on: Error
        do: [ :e | "ignora errori di invio email" ]
]

{ #category : 'as yet unclassified' }
ATRateLimiter >> statusReport [
    "Ritorna un report dello stato"
    self resetIfNewDay.
    ^ Dictionary new
        at: 'date' put: Date today asString;
        at: 'dailyLimit' put: dailyLimit;
        at: 'dailyCount' put: dailyCount;
        at: 'remaining' put: self remainingToday;
        at: 'percentUsed' put: ((dailyCount / dailyLimit * 100) asFloat printShowingDecimalPlaces: 1);
        at: 'alertEmail' put: (alertEmail ifNil: [ 'not set' ]);
        yourself
]
