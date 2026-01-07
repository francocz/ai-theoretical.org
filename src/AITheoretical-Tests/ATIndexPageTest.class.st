Class {
	#name : 'ATIndexPageTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'as yet unclassified' }
ATIndexPageTest >> testContentHasTrackFilters [
    | html |
    html := ATIndexPage new contentHtml.
    self assert: (html includesSubstring: 'track-filters').
    self assert: (html includesSubstring: 'researchPreprint').
    self assert: (html includesSubstring: 'workingPaper')
]

{ #category : 'as yet unclassified' }
ATIndexPageTest >> testFileName [
    self assert: ATIndexPage new fileName equals: 'index.html'
]

{ #category : 'as yet unclassified' }
ATIndexPageTest >> testFooterHasContactEmail [
    | footer |
    footer := ATIndexPage new footer.
    self assert: (footer includesSubstring: 'franco.cazzaniga@uninsubria.it')
]

{ #category : 'as yet unclassified' }
ATIndexPageTest >> testFooterHasNoAuthorAccessLink [
    "Verifica che il footer non abbia più il link Author Access"
    | footer |
    footer := ATIndexPage new footer.
    self deny: (footer includesSubstring: 'author-access.html').
    self deny: (footer includesSubstring: 'Author Access')
]

{ #category : 'as yet unclassified' }
ATIndexPageTest >> testFooterHasPoweredBy [
    | footer |
    footer := ATIndexPage new footer.
    self assert: (footer includesSubstring: 'Powered by').
    self assert: (footer includesSubstring: 'Claude AI').
    self assert: (footer includesSubstring: 'Pharo Smalltalk')
]
