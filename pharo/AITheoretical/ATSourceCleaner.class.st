Class {
	#name : 'ATSourceCleaner',
	#superclass : 'Object',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'checking' }
ATSourceCleaner class >> checkPackage: aPackageName [
	"Ritorna lista di metodi che contengono LF"
	| package problematic |
	problematic := OrderedCollection new.
	package := aPackageName asPackage.
	package definedClasses do: [ :cls |
		cls methods do: [ :m |
			(m sourceCode includes: Character lf) ifTrue: [
				problematic add: cls name, '>>', m selector ] ].
		cls class methods do: [ :m |
			(m sourceCode includes: Character lf) ifTrue: [
				problematic add: cls name, ' class>>', m selector ] ] ].
	^ problematic
]

{ #category : 'cleaning' }
ATSourceCleaner class >> cleanClass: aClass [
	"Pulisce tutti i metodi di una classe"
	| cleaned |
	cleaned := 0.
	aClass methods do: [ :method |
		(self cleanMethod: method) ifTrue: [ cleaned := cleaned + 1 ] ].
	^ cleaned
]

{ #category : 'cleaning' }
ATSourceCleaner class >> cleanMethod: aMethod [
	"Pulisce un singolo metodo se contiene LF. Ritorna true se modificato."
	| source cleanedSource protocol |
	source := aMethod sourceCode.
	(source includes: Character lf) ifFalse: [ ^ false ].
	cleanedSource := source copyReplaceAll: String lf with: String cr.
	protocol := aMethod protocolName.
	aMethod methodClass compile: cleanedSource classified: protocol.
	^ true
]

{ #category : 'cleaning' }
ATSourceCleaner class >> cleanPackage: aPackageName [
	"Pulisce tutti i metodi di un package, sostituendo LF con CR"
	| package cleaned |
	cleaned := 0.
	package := aPackageName asPackage.
	package definedClasses do: [ :cls |
		cleaned := cleaned + (self cleanClass: cls).
		cleaned := cleaned + (self cleanClass: cls class) ].
	^ cleaned
]
