Class {
	#name : 'ATSiteGeneratorTest',
	#superclass : 'TestCase',
	#instVars : [
		'generator',
		'tempDir',
		'repo'
	],
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'running' }
ATSiteGeneratorTest >> setUp [
	super setUp.
	tempDir := FileLocator temp / ('test-site-', UUID new asString).
	tempDir ensureCreateDirectory.
	repo := ATRepository new.
	repo gitRepoPath: tempDir pathString.
	generator := ATSiteGenerator new.
	generator repository: repo.
	generator outputPath: tempDir pathString
]

{ #category : 'running' }
ATSiteGeneratorTest >> tearDown [
	tempDir ensureDeleteAll.
	super tearDown
]

{ #category : 'tests' }
ATSiteGeneratorTest >> testGenerateSitemap [
	| paper sitemapFile content |
	paper := ATPaper new.
	paper title: 'Test'.
	paper slug: 'test-paper'.
	repo addPaper: paper.
	generator generateSitemap.
	sitemapFile := tempDir / 'sitemap.xml'.
	self assert: sitemapFile exists.
	content := sitemapFile contents.
	self assert: (content includesSubstring: 'test-paper.html')
]

{ #category : 'tests' }
ATSiteGeneratorTest >> testSeoPageContainsFooter [
	| paper html |
	paper := ATPaper new.
	paper title: 'Test'.
	paper slug: 'test'.
	html := generator seoPageForPaper: paper.
	self assert: (html includesSubstring: '<footer>').
	self assert: (html includesSubstring: 'Powered by').
	self assert: (html includesSubstring: 'Claude AI').
	self assert: (html includesSubstring: 'Pharo Smalltalk')
]

{ #category : 'tests' }
ATSiteGeneratorTest >> testSeoPageContainsOgTags [
	| paper html |
	paper := ATPaper new.
	paper title: 'Test Paper'.
	paper authors: 'John Doe'.
	paper abstract: 'This is an abstract'.
	paper slug: 'test-paper'.
	html := generator seoPageForPaper: paper.
	self assert: (html includesSubstring: 'og:title').
	self assert: (html includesSubstring: 'og:description').
	self assert: (html includesSubstring: 'og:image').
	self assert: (html includesSubstring: 'og:url')
]

{ #category : 'tests' }
ATSiteGeneratorTest >> testWithdrawnPageHasNoindex [
	| paper html |
	paper := ATPaper new.
	paper title: 'Withdrawn Paper'.
	paper slug: 'withdrawn'.
	paper withdraw: 'Reason'.
	html := generator seoPageForPaper: paper.
	self assert: (html includesSubstring: 'noindex')
]
