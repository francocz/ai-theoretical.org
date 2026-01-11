Class {
	#name : 'ATCloudflaredTunnel',
	#superclass : 'Object',
	#instVars : [
		'process',
		'tunnelName',
		'checkInterval',
		'lastCheck'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel class >> current [
    ^ Current ifNil: [ Current := self new ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel class >> initialize [
    SessionManager default registerUserClassNamed: self name
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel class >> reset [
    Current ifNotNil: [ Current stop ].
    Current := nil
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel class >> shutDown: quitting [
    quitting ifTrue: [
        Current ifNotNil: [ Current stop ] ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel class >> startUp: resuming [
    "Non auto-avvia al riavvio immagine - chiamare manualmente start se necessario"
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> checkInterval [
    ^ checkInterval
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> checkInterval: seconds [
    checkInterval := seconds
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> initialize [
    super initialize.
    tunnelName := 'ai-theoretical-console'.
    checkInterval := 30  "secondi"
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> isRunning [
    "Watchdog attivo?"
    ^ process notNil and: [ process isTerminated not ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> isTunnelRunning [
    "Verifica se cloudflared è in esecuzione con pgrep"
    | result |
    result := LibC resultOfCommand: 'pgrep -f "cloudflared.*tunnel.*run"'.
    ^ result isNotEmpty
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> start [
    "Avvia il tunnel e il watchdog"
    self stop.
    self startTunnel.
    process := [ self watchdogLoop ] fork.
    process name: 'ATCloudflaredTunnel watchdog'.
    Transcript show: 'Tunnel watchdog started (checking every ', checkInterval asString, 's)'; cr
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> startTunnel [
    "Avvia cloudflared tunnel in background"
    | cmd |
    self isTunnelRunning ifTrue: [ 
        Transcript show: 'Tunnel already running'; cr.
        ^ self ].
    
    cmd := 'cloudflared tunnel run ', tunnelName, ' > /dev/null 2>&1 &'.
    LibC system: cmd.
    (Delay forSeconds: 2) wait.
    
    self isTunnelRunning
        ifTrue: [ Transcript show: 'Tunnel started successfully'; cr ]
        ifFalse: [ Transcript show: 'WARNING: Tunnel failed to start'; cr ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> status [
    "Ritorna descrizione stato"
    ^ String streamContents: [ :s |
        s nextPutAll: 'Tunnel: '.
        s nextPutAll: (self isTunnelRunning ifTrue: [ 'RUNNING' ] ifFalse: [ 'DOWN' ]).
        s nextPutAll: ' | Watchdog: '.
        s nextPutAll: (self isRunning ifTrue: [ 'ACTIVE' ] ifFalse: [ 'INACTIVE' ]).
        lastCheck ifNotNil: [
            s nextPutAll: ' | Last check: '.
            s nextPutAll: lastCheck asTime print24 ] ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> stop [
    "Ferma il watchdog (non il tunnel)"
    process ifNotNil: [
        process terminate.
        process := nil.
        Transcript show: 'Tunnel watchdog stopped'; cr ]
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> stopAll [
    "Ferma watchdog E tunnel"
    self stop.
    self stopTunnel
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> stopTunnel [
    "Ferma cloudflared"
    LibC system: 'pkill -f "cloudflared.*tunnel.*run"'.
    Transcript show: 'Tunnel stopped'; cr
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> tunnelName [
    ^ tunnelName
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> tunnelName: aString [
    tunnelName := aString
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnel >> watchdogLoop [
    "Loop che controlla e riavvia il tunnel se necessario"
    [ true ] whileTrue: [
        self isTunnelRunning ifFalse: [
            Transcript show: DateAndTime now asString, ' - Tunnel down, restarting...'; cr.
            self startTunnel ].
        lastCheck := DateAndTime now.
        (Delay forSeconds: checkInterval) wait ]
]
