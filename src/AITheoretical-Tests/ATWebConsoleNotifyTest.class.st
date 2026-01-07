Class {
	#name : 'ATWebConsoleNotifyTest',
	#superclass : 'ATTestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATWebConsoleNotifyTest >> testWebConsoleRespondsToNotifyNewVersion [
    "Verifica che ATWebConsole abbia handler per notify-new-version"
    self assert: (ATWebConsole canUnderstand: #handleNotifyNewVersion:)
]

{ #category : 'tests' }
ATWebConsoleNotifyTest >> testWebConsoleRespondsToNotifyWithdraw [
    "Verifica che ATWebConsole abbia handler per notify-withdraw"
    self assert: (ATWebConsole canUnderstand: #handleNotifyWithdraw:)
]
