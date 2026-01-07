Class {
	#name : 'ATSubmitFormPageTest',
	#superclass : 'ATTestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentHtmlContainsBackLink [
    | html |
    html := ATSubmitFormPage new contentHtml.
    self assert: (html includesSubstring: 'href="submit.html"')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentHtmlContainsForm [
    | html |
    html := ATSubmitFormPage new contentHtml.
    self assert: (html includesSubstring: '<form id="submissionForm">').
    self assert: (html includesSubstring: 'Submit Paper')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentHtmlContainsTrackSelector [
    | html |
    html := ATSubmitFormPage new contentHtml.
    self assert: (html includesSubstring: 'researchPreprint').
    self assert: (html includesSubstring: 'workingPaper')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentHtmlHasBackLink [
    | html |
    html := ATSubmitFormPage new contentHtml.
    self assert: (html includesSubstring: 'href="submit.html"')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentHtmlHasForm [
    | html |
    html := ATSubmitFormPage new contentHtml.
    self assert: (html includesSubstring: '<form id="submissionForm">').
    self assert: (html includesSubstring: 'Submit Paper').
    self assert: (html includesSubstring: 'acceptTerms')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testContentIncludesJavascript [
    | content |
    content := ATSubmitFormPage new content.
    self assert: (content includesSubstring: '<script>')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testCssHasFormStyles [
    | css |
    css := ATSubmitFormPage new css.
    self assert: (css includesSubstring: '.form-group').
    self assert: (css includesSubstring: '.disclaimer-box')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testDescription [
    self assert: (ATSubmitFormPage new description includesSubstring: 'Submit')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testFileName [
    self assert: ATSubmitFormPage new fileName equals: 'submit-form.html'
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testJavascriptContainsFormHandler [
    | js |
    js := ATSubmitFormPage new javascript.
    self assert: (js includesSubstring: 'submissionForm').
    self assert: (js includesSubstring: 'fetch')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testJavascriptHasSubmitHandler [
    | js |
    js := ATSubmitFormPage new javascript.
    self assert: (js includesSubstring: 'addEventListener').
    self assert: (js includesSubstring: '/api/submit')
]

{ #category : 'tests' }
ATSubmitFormPageTest >> testTitle [
    self assert: ATSubmitFormPage new title equals: 'Submit a Paper — AI-Theoretical'
]
