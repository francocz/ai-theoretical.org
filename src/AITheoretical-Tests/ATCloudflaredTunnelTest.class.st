Class {
	#name : 'ATCloudflaredTunnelTest',
	#superclass : 'TestCase',
	#instVars : [
		'tunnel'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> setUp [
    super setUp.
    tunnel := ATCloudflaredTunnel new
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> testDefaultValues [
    self assert: tunnel tunnelName equals: 'ai-theoretical-console'.
    self assert: tunnel checkInterval equals: 30
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> testInitiallyNotRunning [
    self deny: tunnel isRunning
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> testSetCheckInterval [
    tunnel checkInterval: 60.
    self assert: tunnel checkInterval equals: 60
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> testSetTunnelName [
    tunnel tunnelName: 'my-tunnel'.
    self assert: tunnel tunnelName equals: 'my-tunnel'
]

{ #category : 'as yet unclassified' }
ATCloudflaredTunnelTest >> testStatusFormat [
    | status |
    status := tunnel status.
    self assert: (status includesSubstring: 'Tunnel:').
    self assert: (status includesSubstring: 'Watchdog:')
]
