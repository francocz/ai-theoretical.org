Class {
	#name : 'ATWebConsoleTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'as yet unclassified' }
ATWebConsoleTest >> testNotifyNewVersionPaperNotFound [
    | console req response responseBody |
    console := ATWebConsole new.
    
    req := ZnRequest post: 'http://localhost/api/notify-new-version'.
    req entity: (ZnEntity json: '{"paperId":"nonexistent-123"}').
    
    response := console handleNotifyNewVersion: req.
    responseBody := NeoJSONReader fromString: response entity string.
    
    self assert: (responseBody at: 'success').
    self assert: ((responseBody at: 'message') includesSubstring: 'not in local')
]

{ #category : 'tests - notify endpoints' }
ATWebConsoleTest >> testNotifyNewVersionRequiresPaperId [
    | console req response responseBody |
    console := ATWebConsole new.
    
    req := ZnRequest post: 'http://localhost/api/notify-new-version'.
    req entity: (ZnEntity json: '{}').
    
    response := console handleNotifyNewVersion: req.
    responseBody := NeoJSONReader fromString: response entity string.
    
    self deny: (responseBody at: 'success').
    self assert: (responseBody at: 'error') equals: 'paperId required'
]

{ #category : 'as yet unclassified' }
ATWebConsoleTest >> testNotifyWithdrawPaperNotFound [
    | console req response responseBody |
    console := ATWebConsole new.
    
    req := ZnRequest post: 'http://localhost/api/notify-withdraw'.
    req entity: (ZnEntity json: '{"paperId":"nonexistent-123"}').
    
    response := console handleNotifyWithdraw: req.
    responseBody := NeoJSONReader fromString: response entity string.
    
    self assert: (responseBody at: 'success').
    self assert: ((responseBody at: 'message') includesSubstring: 'not in local')
]

{ #category : 'tests - notify endpoints' }
ATWebConsoleTest >> testNotifyWithdrawRequiresPaperId [
    | console req response responseBody |
    console := ATWebConsole new.
    
    "Simula request con body vuoto"
    req := ZnRequest post: 'http://localhost/api/notify-withdraw'.
    req entity: (ZnEntity json: '{}').
    
    response := console handleNotifyWithdraw: req.
    responseBody := NeoJSONReader fromString: response entity string.
    
    self deny: (responseBody at: 'success').
    self assert: (responseBody at: 'error') equals: 'paperId required'
]
