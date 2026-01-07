Class {
	#name : 'ATDeployment',
	#superclass : 'Object',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'operations' }
ATDeployment class >> deploy [
	"Genera le pagine e fa commit+push"
	^ self deployWithMessage: 'Update static pages'
]

{ #category : 'as yet unclassified' }
ATDeployment class >> deployGitRepoPath: aPath withMessage: aMessage [
    "Fa pull, commit e push con path e messaggio custom"
    | cmd result |
    cmd := 'cd "', aPath, '" && git pull && git add -A && git commit -m "', aMessage, '" && git push 2>&1'.
    result := LibC resultOfCommand: cmd.
    ^ result
]

{ #category : 'operations' }
ATDeployment class >> deployWithMessage: aMessage [
	"Genera le pagine e fa commit+push con messaggio custom"
	self generateStaticPages.
	self gitAdd.
	self gitCommit: aMessage.
	self gitPush.
	^ 'Deployed successfully'
]

{ #category : 'operations' }
ATDeployment class >> generateStaticPages [
	"Genera tutti i file HTML statici"
	ATStaticPage generateAllTo: self projectPath.
	^ 'Static pages generated'
]

{ #category : 'git' }
ATDeployment class >> git: aCommand [
	"Esegue un comando git nel repository"
	^ LibC resultOfCommand: 'cd "', self projectPath, '" && git ', aCommand
]

{ #category : 'git' }
ATDeployment class >> gitAdd [
	^ self git: 'add -A'
]

{ #category : 'git' }
ATDeployment class >> gitCommit: aMessage [
	^ self git: 'commit -m "', aMessage, '"'
]

{ #category : 'git' }
ATDeployment class >> gitPull [
	^ self git: 'pull'
]

{ #category : 'git' }
ATDeployment class >> gitPush [
	^ self git: 'push'
]

{ #category : 'git' }
ATDeployment class >> gitStatus [
	^ self git: 'status'
]

{ #category : 'configuration' }
ATDeployment class >> projectPath [
	^ '/Users/Franco/Dropbox/ai-theoretical.org'
]
