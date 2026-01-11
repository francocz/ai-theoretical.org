Class {
	#name : 'ATPrompt',
	#superclass : 'Object',
	#instVars : [
		'track',
		'version',
		'content',
		'createdAt',
		'changelog',
		'isActive'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATPrompt class >> track: aSymbol version: aString content: aContentString changelog: aChangelogString [
    ^ self new
        track: aSymbol;
        version: aString;
        content: aContentString;
        changelog: aChangelogString;
        yourself
]

{ #category : 'accessing' }
ATPrompt >> changelog [ ^ changelog
]

{ #category : 'accessing' }
ATPrompt >> changelog: anObject [ changelog := anObject
]

{ #category : 'accessing' }
ATPrompt >> content [ ^ content
]

{ #category : 'accessing' }
ATPrompt >> content: anObject [ content := anObject
]

{ #category : 'accessing' }
ATPrompt >> createdAt [ ^ createdAt
]

{ #category : 'accessing' }
ATPrompt >> createdAt: anObject [ createdAt := anObject
]

{ #category : 'actions' }
ATPrompt >> deactivate [
    isActive := false
]

{ #category : 'initialization' }
ATPrompt >> initialize [
    super initialize.
    createdAt := DateAndTime now.
    isActive := true
]

{ #category : 'accessing' }
ATPrompt >> isActive [ ^ isActive
]

{ #category : 'accessing' }
ATPrompt >> isActive: anObject [ isActive := anObject
]

{ #category : 'accessing' }
ATPrompt >> track [ ^ track
]

{ #category : 'accessing' }
ATPrompt >> track: anObject [ track := anObject
]

{ #category : 'accessing' }
ATPrompt >> trackAndVersion [
    ^ track asString, ' v', self versionString
]

{ #category : 'accessing' }
ATPrompt >> version [ ^ version
]

{ #category : 'accessing' }
ATPrompt >> version: anObject [ version := anObject
]

{ #category : 'accessing' }
ATPrompt >> versionString [
    ^ version asString
]
