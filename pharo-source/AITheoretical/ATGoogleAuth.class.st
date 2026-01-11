Class {
	#name : 'ATGoogleAuth',
	#superclass : 'Object',
	#instVars : [
		'clientId',
		'clientSecret',
		'redirectUri',
		'accessToken',
		'refreshToken',
		'expiresAt',
		'scopes'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATGoogleAuth class >> clientId: aClientId secret: aSecret [
	^ self new
		clientId: aClientId;
		clientSecret: aSecret;
		yourself
]

{ #category : 'accessing' }
ATGoogleAuth class >> current [
	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
ATGoogleAuth class >> reset [
	Current := nil
]

{ #category : 'accessing' }
ATGoogleAuth >> accessToken [
	^ accessToken
]

{ #category : 'accessing' }
ATGoogleAuth >> addScope: aScope [
	scopes := scopes copyWith: aScope
]

{ #category : 'oauth' }
ATGoogleAuth >> authorizationUrl [
	"Genera URL per autorizzazione Google"
	| url |
	url := ZnUrl new.
	url scheme: 'https'.
	url host: 'accounts.google.com'.
	url addPathSegment: 'o'.
	url addPathSegment: 'oauth2'.
	url addPathSegment: 'v2'.
	url addPathSegment: 'auth'.
	url queryAt: 'client_id' put: clientId.
	url queryAt: 'redirect_uri' put: redirectUri.
	url queryAt: 'response_type' put: 'code'.
	url queryAt: 'scope' put: (' ' join: scopes).
	url queryAt: 'access_type' put: 'offline'.
	url queryAt: 'prompt' put: 'consent'.
	^ url asString
]

{ #category : 'accessing' }
ATGoogleAuth >> clientId [
	^ clientId
]

{ #category : 'accessing' }
ATGoogleAuth >> clientId: aString [
	clientId := aString
]

{ #category : 'accessing' }
ATGoogleAuth >> clientSecret [
	^ clientSecret
]

{ #category : 'accessing' }
ATGoogleAuth >> clientSecret: aString [
	clientSecret := aString
]

{ #category : 'persistence' }
ATGoogleAuth >> defaultTokenFile [
	^ ATRepository current gitRepoPath, '/secrets/google-oauth.json'
]

{ #category : 'oauth' }
ATGoogleAuth >> ensureValidToken [
	"Assicura che ci sia un token valido, rinnovando se necessario"
	self isTokenValid ifTrue: [ ^ accessToken ].
	refreshToken ifNotNil: [ ^ self refreshAccessToken ].
	self error: 'No valid token and no refresh token. Please re-authenticate.'
]

{ #category : 'oauth' }
ATGoogleAuth >> exchangeCodeForToken: authCode [
	"Scambia authorization code per access token"
	| client response data |
	client := ZnClient new.
	client url: 'https://oauth2.googleapis.com/token'.
	client formAt: 'client_id' put: clientId.
	client formAt: 'client_secret' put: clientSecret.
	client formAt: 'code' put: authCode.
	client formAt: 'redirect_uri' put: redirectUri.
	client formAt: 'grant_type' put: 'authorization_code'.
	client post.
	response := client response.
	response isSuccess ifFalse: [ 
		self error: 'Token exchange failed: ', client contents ].
	data := NeoJSONReader fromString: client contents.
	accessToken := data at: 'access_token'.
	refreshToken := data at: 'refresh_token' ifAbsent: [ nil ].
	expiresAt := DateAndTime now + (data at: 'expires_in') seconds.
	^ accessToken
]

{ #category : 'api' }
ATGoogleAuth >> geminiHeaders [
	"Ritorna headers per chiamate Gemini API con OAuth"
	^ { 
		'Authorization' -> ('Bearer ', self ensureValidToken).
		'Content-Type' -> 'application/json' 
	}
]

{ #category : 'initialization' }
ATGoogleAuth >> initialize [
	super initialize.
	redirectUri := 'http://localhost:8085/oauth/callback'.
	scopes := #('https://www.googleapis.com/auth/generative-language')
]

{ #category : 'testing' }
ATGoogleAuth >> isAuthenticated [
	^ accessToken notNil
]

{ #category : 'oauth' }
ATGoogleAuth >> isTokenValid [
	"Verifica se il token è ancora valido"
	accessToken ifNil: [ ^ false ].
	expiresAt ifNil: [ ^ true ]. "Assume valid if no expiry"
	^ DateAndTime now < (expiresAt - 60 seconds) "60s margin"
]

{ #category : 'persistence' }
ATGoogleAuth >> load [
	self loadFromFile: self defaultTokenFile
]

{ #category : 'persistence' }
ATGoogleAuth >> loadFromFile: aPath [
	"Carica tokens da file"
	| file data |
	file := aPath asFileReference.
	file exists ifFalse: [ ^ self ].
	data := NeoJSONReader fromString: file contents.
	clientId := data at: 'clientId' ifAbsent: [ nil ].
	clientSecret := data at: 'clientSecret' ifAbsent: [ nil ].
	accessToken := data at: 'accessToken' ifAbsent: [ nil ].
	refreshToken := data at: 'refreshToken' ifAbsent: [ nil ].
	(data at: 'expiresAt' ifAbsent: [ nil ]) ifNotNil: [ :s |
		expiresAt := DateAndTime fromString: s ].
	scopes := data at: 'scopes' ifAbsent: [ #() ]
]

{ #category : 'accessing' }
ATGoogleAuth >> redirectUri [
	^ redirectUri
]

{ #category : 'accessing' }
ATGoogleAuth >> redirectUri: aString [
	redirectUri := aString
]

{ #category : 'oauth' }
ATGoogleAuth >> refreshAccessToken [
	"Rinnova access token usando refresh token"
	| client response data |
	refreshToken ifNil: [ self error: 'No refresh token available' ].
	client := ZnClient new.
	client url: 'https://oauth2.googleapis.com/token'.
	client formAt: 'client_id' put: clientId.
	client formAt: 'client_secret' put: clientSecret.
	client formAt: 'refresh_token' put: refreshToken.
	client formAt: 'grant_type' put: 'refresh_token'.
	client post.
	response := client response.
	response isSuccess ifFalse: [ 
		self error: 'Token refresh failed: ', client contents ].
	data := NeoJSONReader fromString: client contents.
	accessToken := data at: 'access_token'.
	expiresAt := DateAndTime now + (data at: 'expires_in') seconds.
	^ accessToken
]

{ #category : 'accessing' }
ATGoogleAuth >> refreshToken [
	^ refreshToken
]

{ #category : 'persistence' }
ATGoogleAuth >> save [
	self saveToFile: self defaultTokenFile
]

{ #category : 'persistence' }
ATGoogleAuth >> saveToFile: aPath [
	"Salva tokens su file per riutilizzo"
	| data file |
	data := Dictionary new.
	data at: 'clientId' put: clientId.
	data at: 'clientSecret' put: clientSecret.
	data at: 'accessToken' put: accessToken.
	data at: 'refreshToken' put: refreshToken.
	data at: 'expiresAt' put: (expiresAt ifNotNil: [ expiresAt asString ]).
	data at: 'scopes' put: scopes.
	file := aPath asFileReference.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :s |
		s nextPutAll: (NeoJSONWriter toStringPretty: data) ]
]

{ #category : 'accessing' }
ATGoogleAuth >> scopes [
	^ scopes
]

{ #category : 'accessing' }
ATGoogleAuth >> scopes: anArray [
	scopes := anArray
]

{ #category : 'oauth' }
ATGoogleAuth >> startAuthFlow [
	"Avvia il flow OAuth: apre browser e avvia server per callback"
	| authUrl |
	clientId ifNil: [ self error: 'Client ID not configured' ].
	clientSecret ifNil: [ self error: 'Client Secret not configured' ].
	authUrl := self authorizationUrl.
	self startCallbackServer.
	WebBrowser openOn: authUrl.
	^ 'Browser opened. Please authorize the application.'
]

{ #category : 'oauth' }
ATGoogleAuth >> startCallbackServer [
	"Avvia un server temporaneo per ricevere il callback OAuth"
	| teapot port |
	port := (ZnUrl fromString: redirectUri) port ifNil: [ 8085 ].
	teapot := Teapot configure: { #port -> port }.
	teapot
		GET: '/oauth/callback' -> [ :req | 
			| code |
			code := req at: 'code' ifAbsent: [ nil ].
			code ifNotNil: [
				[ self exchangeCodeForToken: code ]
					on: Error 
					do: [ :e | ^ '<html><body><h1>Error</h1><p>', e messageText, '</p></body></html>' ].
				teapot stop.
				'<html><body><h1>Success!</h1><p>You can close this window.</p></body></html>' ]
			ifNil: [
				'<html><body><h1>Error</h1><p>No authorization code received</p></body></html>' ] ].
	teapot start.
	^ teapot
]

{ #category : 'api' }
ATGoogleAuth >> testConnection [
	"Testa la connessione a Gemini API"
	| client url |
	self ensureValidToken.
	url := 'https://generativelanguage.googleapis.com/v1beta/models'.
	client := ZnClient new.
	client url: url.
	client headerAt: 'Authorization' put: 'Bearer ', accessToken.
	client get.
	^ client isSuccess 
		ifTrue: [ 'Connected! Models: ', (NeoJSONReader fromString: client contents) keys asString ]
		ifFalse: [ 'Error: ', client contents ]
]
