Class {
	#name : 'ATSubmitPagePanelsTest',
	#superclass : 'ATTestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testAuthorAccessPanel [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'Manage Your Papers').
    self assert: (html includesSubstring: 'href="author-access.html"')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testContentHasTwoPanels [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'class="panels"').
    self assert: (html includesSubstring: 'class="panel"')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testContentNoLongerHasForm [
    | content |
    content := ATSubmitPage new content.
    self deny: (content includesSubstring: '<form')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testCssHasPanelStyles [
    | css |
    css := ATSubmitPage new css.
    self assert: (css includesSubstring: '.panels').
    self assert: (css includesSubstring: '.panel-button').
    self assert: (css includesSubstring: 'grid-template-columns')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testCssHasPanelsStyles [
    | css |
    css := ATSubmitPage new css.
    self assert: (css includesSubstring: '.panels').
    self assert: (css includesSubstring: '.panel').
    self assert: (css includesSubstring: '.panel-button')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testCssHasResponsiveGrid [
    | css |
    css := ATSubmitPage new css.
    self assert: (css includesSubstring: 'grid-template-columns').
    self assert: (css includesSubstring: '@media')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testDescriptionUpdated [
    self assert: (ATSubmitPage new description includesSubstring: 'manage')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testHasTwoPanels [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'class="panels"').
    self assert: (html includesSubstring: 'class="panel"')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testNewSubmissionPanel [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'Submit a New Paper').
    self assert: (html includesSubstring: 'href="submit-form.html"')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testResponsiveLayout [
    | css |
    css := ATSubmitPage new css.
    self assert: (css includesSubstring: '@media')
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testTitleIsSubmissions [
    self assert: ATSubmitPage new title equals: 'Submissions — AI-Theoretical'
]

{ #category : 'tests' }
ATSubmitPagePanelsTest >> testTitleUpdated [
    self assert: ATSubmitPage new title equals: 'Submissions — AI-Theoretical'
]
