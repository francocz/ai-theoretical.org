Class {
	#name : 'ATStaticPageTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests - ai editorial prompt' }
ATStaticPageTest >> testAIEditorialPromptPageAccessors [
	| page |
	page := ATAIEditorialPromptPage new.
	self assert: page fileName equals: 'ai-editorial-prompt.html'.
	self assert: (page title includesSubstring: 'AI Editorial Prompt').
	self assert: (page description includesSubstring: 'Transparency')
]

{ #category : 'tests - ai editorial prompt' }
ATStaticPageTest >> testAIEditorialPromptPageGenerate [
	| page html |
	page := ATAIEditorialPromptPage new.
	html := page generate.
	self assert: html isString.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: '<title>AI Editorial Prompt').
	self assert: (html includesSubstring: 'prompt-frame').
	self assert: (html includesSubstring: 'ai-prompt.js').
	self assert: (html includesSubstring: '</html>')
]

{ #category : 'tests - integration' }
ATStaticPageTest >> testAllPagesHaveFooter [
	| pageClasses |
	pageClasses := { ATAIEditorialPromptPage. ATEditorialPrinciplesPage. ATIndexPage. ATInvitePage. ATManifestoPage. ATSubmitPage }.
	pageClasses do: [ :cls |
		| html |
		html := cls new generate.
		self assert: (html includesSubstring: '<footer>').
		self assert: (html includesSubstring: 'Claude AI').
		self assert: (html includesSubstring: 'Pharo Smalltalk') ]
]

{ #category : 'tests - integration' }
ATStaticPageTest >> testAllPagesHaveGoogleFonts [
	| pageClasses |
	pageClasses := { ATAIEditorialPromptPage. ATEditorialPrinciplesPage. ATIndexPage. ATInvitePage. ATManifestoPage. ATSubmitPage }.
	pageClasses do: [ :cls |
		| html |
		html := cls new generate.
		self assert: (html includesSubstring: 'fonts.googleapis.com').
		self assert: (html includesSubstring: 'Inter').
		self assert: (html includesSubstring: 'Playfair') ]
]

{ #category : 'tests - integration' }
ATStaticPageTest >> testAllPagesHaveMetaTags [
	| pageClasses |
	pageClasses := { ATAIEditorialPromptPage. ATEditorialPrinciplesPage. ATIndexPage. ATInvitePage. ATManifestoPage. ATSubmitPage }.
	pageClasses do: [ :cls |
		| html |
		html := cls new generate.
		self assert: (html includesSubstring: '<meta charset="UTF-8">').
		self assert: (html includesSubstring: 'viewport').
		self assert: (html includesSubstring: '<title>').
		self assert: (html includesSubstring: 'og:image') ]
]

{ #category : 'tests - integration' }
ATStaticPageTest >> testAllPagesHaveValidHtmlStructure [
	| pageClasses |
	pageClasses := { ATAIEditorialPromptPage. ATEditorialPrinciplesPage. ATIndexPage. ATInvitePage. ATManifestoPage. ATSubmitPage }.
	pageClasses do: [ :cls |
		| html |
		html := cls new generate.
		self assert: (html beginsWith: '<!DOCTYPE html>').
		self assert: (html includesSubstring: '<html').
		self assert: (html includesSubstring: '<head>').
		self assert: (html includesSubstring: '</head>').
		self assert: (html includesSubstring: '<body>').
		self assert: (html includesSubstring: '</body>').
		self assert: (html includesSubstring: '</html>') ]
]

{ #category : 'tests - editorial principles' }
ATStaticPageTest >> testEditorialPrinciplesPageAccessors [
	| page |
	page := ATEditorialPrinciplesPage new.
	self assert: page fileName equals: 'editorial-principles.html'.
	self assert: (page title includesSubstring: 'Editorial Framework').
	self assert: (page description includesSubstring: 'protocol')
]

{ #category : 'tests - editorial principles' }
ATStaticPageTest >> testEditorialPrinciplesPageGenerate [
	| page html |
	page := ATEditorialPrinciplesPage new.
	html := page generate.
	self assert: html isString.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: 'Scope').
	self assert: (html includesSubstring: 'Admissible domains').
	self assert: (html includesSubstring: 'Role of AI').
	self assert: (html includesSubstring: '</html>')
]

{ #category : 'tests - index' }
ATStaticPageTest >> testIndexPageAccessors [
	| page |
	page := ATIndexPage new.
	self assert: page fileName equals: 'index.html'.
	self assert: (page title includesSubstring: 'AI-Theoretical').
	self assert: (page description includesSubstring: 'platform')
]

{ #category : 'tests - pages' }
ATStaticPageTest >> testIndexPageGenerate [
	| page html |
	page := ATIndexPage new.
	html := page generate.
	self assert: html isString.
	self assert: html size > 10000.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: 'Human-AI Theoretical Laboratory').
	self assert: (html includesSubstring: 'manifesto.html').
	self assert: (html includesSubstring: 'searchInput').
	self assert: (html includesSubstring: 'papers.js').
	self assert: (html includesSubstring: 'filter')
]

{ #category : 'tests - invite' }
ATStaticPageTest >> testInvitePageAccessors [
	| page |
	page := ATInvitePage new.
	self assert: page fileName equals: 'invite.html'.
	self assert: (page title includesSubstring: 'Invitation').
	self assert: (page description includesSubstring: 'researchers')
]

{ #category : 'tests - invite' }
ATStaticPageTest >> testInvitePageGenerate [
	| page html |
	page := ATInvitePage new.
	html := page generate.
	self assert: html isString.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: 'Invitation to Participate').
	self assert: (html includesSubstring: 'franco.cazzaniga@uninsubria.it').
	self assert: (html includesSubstring: '</html>')
]

{ #category : 'tests - manifesto' }
ATStaticPageTest >> testManifestoPageAccessors [
	| page |
	page := ATManifestoPage new.
	self assert: page fileName equals: 'manifesto.html'.
	self assert: (page title includesSubstring: 'Manifesto').
	self assert: (page description includesSubstring: 'human-AI symbiosis')
]

{ #category : 'tests - manifesto' }
ATStaticPageTest >> testManifestoPageGenerate [
	| page html |
	page := ATManifestoPage new.
	html := page generate.
	self assert: html isString.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: 'Manifesto').
	self assert: (html includesSubstring: 'collaboration').
	self assert: (html includesSubstring: '</html>')
]

{ #category : 'tests - base class' }
ATStaticPageTest >> testStaticPageFonts [
	| fonts |
	fonts := ATStaticPage new fonts.
	self assert: fonts isString.
	self assert: (fonts includesSubstring: 'fonts.googleapis.com').
	self assert: (fonts includesSubstring: 'Inter').
	self assert: (fonts includesSubstring: 'Playfair')
]

{ #category : 'tests - base class' }
ATStaticPageTest >> testStaticPageFooter [
	| footer |
	footer := ATStaticPage new footer.
	self assert: footer isString.
	self assert: (footer includesSubstring: '<footer>').
	self assert: (footer includesSubstring: 'Claude AI').
	self assert: (footer includesSubstring: 'Pharo Smalltalk')
]

{ #category : 'tests - base class' }
ATStaticPageTest >> testStaticPageIsAbstract [
	self should: [ ATStaticPage new fileName ] raise: Error.
	self should: [ ATStaticPage new title ] raise: Error.
	self should: [ ATStaticPage new description ] raise: Error.
	self should: [ ATStaticPage new content ] raise: Error
]

{ #category : 'tests - styles' }
ATStaticPageTest >> testStylesBaseCssNotEmpty [
	| css |
	css := ATStyles baseCss.
	self assert: css isString.
	self assert: css size > 100.
	self assert: (css includesSubstring: ':root').
	self assert: (css includesSubstring: '--accent-blue').
	self assert: (css includesSubstring: '--text-main').
	self assert: (css includesSubstring: 'font-family')
]

{ #category : 'tests - styles' }
ATStaticPageTest >> testStylesIndexCssNotEmpty [
	| css |
	css := ATStyles indexCss.
	self assert: css isString.
	self assert: css size > 100.
	self assert: (css includesSubstring: '.manifesto-grid').
	self assert: (css includesSubstring: '.search-input').
	self assert: (css includesSubstring: '.paper-entry')
]

{ #category : 'tests - pages' }
ATStaticPageTest >> testSubmitPageAccessors [
	| page |
	page := ATSubmitPage new.
	self assert: page fileName equals: 'submit.html'.
	self assert: (page title includesSubstring: 'Submissions').
	self assert: (page description includesSubstring: 'paper')
]

{ #category : 'tests - pages' }
ATStaticPageTest >> testSubmitPageGenerate [
	| page html |
	page := ATSubmitPage new.
	html := page generate.
	self assert: html isString.
	self assert: html size > 1000.
	self assert: (html includesSubstring: '<!DOCTYPE html>').
	self assert: (html includesSubstring: 'panels').
	self assert: (html includesSubstring: 'submit-form.html').
	self assert: (html includesSubstring: 'author-access.html').
	self assert: (html includesSubstring: '</html>')
]
