Class {
	#name : 'ATStaticPagesTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests - submit form page' }
ATStaticPagesTest >> testSubmitFormPageHasBackLink [
    | page html |
    page := ATSubmitFormPage new.
    html := page contentHtml.
    
    "Link torna a submit.html"
    self assert: (html includesSubstring: 'href="submit.html"')
]

{ #category : 'tests - submit form page' }
ATStaticPagesTest >> testSubmitFormPageHasForm [
    | page html |
    page := ATSubmitFormPage new.
    html := page contentHtml.
    
    "Verifica che contenga il form"
    self assert: (html includesSubstring: 'id="submissionForm"').
    
    "Verifica campi richiesti"
    self assert: (html includesSubstring: 'name="authorName"').
    self assert: (html includesSubstring: 'name="authorEmail"').
    self assert: (html includesSubstring: 'name="title"').
    self assert: (html includesSubstring: 'name="abstract"').
    self assert: (html includesSubstring: 'name="track"').
    self assert: (html includesSubstring: 'name="pdf"').
    self assert: (html includesSubstring: 'name="acceptTerms"')
]

{ #category : 'tests - submit form page' }
ATStaticPagesTest >> testSubmitFormPageHasJavaScript [
    | page content |
    page := ATSubmitFormPage new.
    content := page content.
    
    "Verifica che contenga script per form submission"
    self assert: (content includesSubstring: '<script>').
    self assert: (content includesSubstring: '/api/submit').
    self assert: (content includesSubstring: 'addEventListener')
]

{ #category : 'tests - submit form page' }
ATStaticPagesTest >> testSubmitFormPageMetadata [
    | page |
    page := ATSubmitFormPage new.
    
    self assert: page fileName equals: 'submit-form.html'.
    self assert: (page title includesSubstring: 'Submit')
]

{ #category : 'tests - submit page' }
ATStaticPagesTest >> testSubmitPageHasPanelsCss [
    | page css |
    page := ATSubmitPage new.
    css := page css.
    
    "Verifica CSS per pannelli"
    self assert: (css includesSubstring: '.panels').
    self assert: (css includesSubstring: '.panel').
    self assert: (css includesSubstring: 'grid-template-columns')
]

{ #category : 'tests - submit page' }
ATStaticPagesTest >> testSubmitPageHasTwoPanels [
    | page html |
    page := ATSubmitPage new.
    html := page contentHtml.
    
    "Verifica la struttura a due pannelli"
    self assert: (html includesSubstring: 'class="panels"').
    self assert: (html includesSubstring: 'class="panel"').
    
    "Verifica link al form"
    self assert: (html includesSubstring: 'href="submit-form.html"').
    
    "Verifica link ad author access"
    self assert: (html includesSubstring: 'href="author-access.html"')
]

{ #category : 'tests - submit page' }
ATStaticPagesTest >> testSubmitPageMetadata [
    | page |
    page := ATSubmitPage new.
    
    self assert: page fileName equals: 'submit.html'.
    self assert: (page title includesSubstring: 'Submissions')
]
