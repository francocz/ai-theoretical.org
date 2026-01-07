Class {
	#name : 'ATSubmitPageTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testContentHasAuthorAccessLink [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'href="author-access.html"').
    self assert: (html includesSubstring: 'Author Access')
]

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testContentHasNewSubmissionLink [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'href="submit-form.html"').
    self assert: (html includesSubstring: 'New Submission')
]

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testContentHasTwoPanels [
    | html |
    html := ATSubmitPage new contentHtml.
    self assert: (html includesSubstring: 'class="panels"').
    self assert: (html includesSubstring: 'class="panel"')
]

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testCssHasPanelStyles [
    | css |
    css := ATSubmitPage new css.
    self assert: (css includesSubstring: '.panels').
    self assert: (css includesSubstring: '.panel').
    self assert: (css includesSubstring: '.panel-button')
]

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testFileName [
    self assert: ATSubmitPage new fileName equals: 'submit.html'
]

{ #category : 'as yet unclassified' }
ATSubmitPageTest >> testTitle [
    self assert: ATSubmitPage new title equals: 'Submissions — AI-Theoretical'
]
