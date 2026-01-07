Class {
	#name : 'ATSiteGenerator',
	#superclass : 'Object',
	#instVars : [
		'repository',
		'outputPath',
		'templatePath',
		'staticPages'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATSiteGenerator class >> for: aRepository outputTo: aPath [
^ self new
    repository: aRepository;
    outputPath: aPath;
    yourself
]

{ #category : 'private' }
ATSiteGenerator >> activePapers [
	"Ritorna solo i paper con status active"
	^ repository papers select: [ :p | p isActive ]
]

{ #category : 'configuration' }
ATSiteGenerator >> addStaticPage: aPageName [
    self staticPages add: aPageName
]

{ #category : 'private' }
ATSiteGenerator >> cleanSeoPages [
| papersDir |
papersDir := outputPath asFileReference / 'papers'.
papersDir exists ifTrue: [
    papersDir files do: [ :f | f delete ] ].
^ papersDir
]

{ #category : 'defaults' }
ATSiteGenerator >> defaultStaticPages [
    "Pagine statiche di default per ai-theoretical.org"
    ^ OrderedCollection withAll: #(
        'index.html'
        'manifesto.html'
        'editorial-framework.html'
        'ai-editorial-prompts.html'
        'invite.html'
        'submit.html'
    )
]

{ #category : 'private' }
ATSiteGenerator >> ensurePapersDirectory [
| papersDir |
papersDir := outputPath asFileReference / 'papers'.
papersDir ensureCreateDirectory.
^ papersDir
]

{ #category : 'private' }
ATSiteGenerator >> escapeHtml: aString [
	aString ifNil: [ ^ '' ].
	^ aString 
		copyReplaceAll: '&' with: '&amp:';
		copyReplaceAll: '<' with: '&lt;';
		copyReplaceAll: '>' with: '&gt;';
		copyReplaceAll: '"' with: '&quot;'
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> escapeXml: aString [
    "Escape caratteri speciali per XML"
    ^ aString 
        copyReplaceAll: '&' with: '&amp;';
        copyReplaceAll: '<' with: '&lt;';
        copyReplaceAll: '>' with: '&gt;';
        copyReplaceAll: '"' with: '&quot;';
        copyReplaceAll: Character cr asString with: ' ';
        copyReplaceAll: Character lf asString with: ' '
]

{ #category : 'generating' }
ATSiteGenerator >> generateAll [
| results |
results := Dictionary new.
results at: 'seoPages' put: self generateAllSeoPages.
results at: 'sitemap' put: self generateSitemap.
^ results
]

{ #category : 'generating' }
ATSiteGenerator >> generateAllSeoPages [
^ repository papers collect: [ :p | self generateSeoPageFor: p ]
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> generateRssFeed [
    "Genera RSS feed per i paper pubblicati"
    | stream papers |
    stream := WriteStream on: String new.
    papers := ATRepository current papers reject: [ :p | p isWithdrawn ].
    "Ordina per data se presente, altrimenti per titolo"
    papers := papers sorted: [ :a :b | 
        (a date isNil and: [ b date isNil ]) 
            ifTrue: [ a title < b title ]
            ifFalse: [ 
                a date ifNil: [ false ] ifNotNil: [ 
                    b date ifNil: [ true ] ifNotNil: [ a date > b date ] ] ] ].
    
    stream nextPutAll: '<?xml version="1.0" encoding="UTF-8"?>'; lf.
    stream nextPutAll: '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">'; lf.
    stream nextPutAll: '<channel>'; lf.
    stream nextPutAll: '<title>AI-Theoretical</title>'; lf.
    stream nextPutAll: '<link>https://ai-theoretical.org</link>'; lf.
    stream nextPutAll: '<description>Human-AI co-authored theoretical papers in philosophy, science, and epistemology</description>'; lf.
    stream nextPutAll: '<language>en</language>'; lf.
    stream nextPutAll: '<atom:link href="https://ai-theoretical.org/feed.xml" rel="self" type="application/rss+xml"/>'; lf.
    
    papers do: [ :paper |
        self renderRssItem: paper to: stream ].
    
    stream nextPutAll: '</channel>'; lf.
    stream nextPutAll: '</rss>'.
    ^ stream contents
]

{ #category : 'generating' }
ATSiteGenerator >> generateSeoPageFor: aPaper [
    | papersDir html file |
    papersDir := self ensurePapersDirectory.
    html := self seoPageForPaper: aPaper.
    file := papersDir / (aPaper slug, '.html').
    file ensureDelete.
    file writeStreamDo: [ :stream |
        stream nextPutAll: html ].
    ^ aPaper slug
]

{ #category : 'generating' }
ATSiteGenerator >> generateSitemap [
    "Genera sitemap.xml con pagine statiche + SEO dei paper attivi"
    | stream baseUrl activePapers file |
    baseUrl := 'https://ai-theoretical.org'.
    activePapers := self activePapers.
    stream := WriteStream on: String new.
    stream nextPutAll: '<?xml version="1.0" encoding="UTF-8"?>'; cr.
    stream nextPutAll: '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'; cr.
    "Pagine statiche"
    self staticPages do: [ :page |
        stream nextPutAll: '<url><loc>'.
        stream nextPutAll: baseUrl; nextPutAll: '/'.
        stream nextPutAll: (page = 'index.html' ifTrue: [ '' ] ifFalse: [ page ]).
        stream nextPutAll: '</loc></url>'; cr ].
    "Solo paper attivi"
    activePapers do: [ :paper |
        stream nextPutAll: '<url><loc>'.
        stream nextPutAll: baseUrl; nextPutAll: '/papers/'; nextPutAll: paper slug; nextPutAll: '.html'.
        stream nextPutAll: '</loc></url>'; cr ].
    stream nextPutAll: '</urlset>'.
    file := outputPath asFileReference / 'sitemap.xml'.
    file ensureDelete.
    file writeStreamDo: [ :f |
        f nextPutAll: stream contents ].
    ^ self staticPages size + activePapers size
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> googleScholarMetaTagsForPaper: aPaper to: stream [
    "Genera meta tags specifici per Google Scholar"
    | dateStr authors |
    
    dateStr := aPaper date 
        ifNil: [ '' ] 
        ifNotNil: [ :d | d yyyymmdd ].
    
    "citation_title"
    stream nextPutAll: '<meta name="citation_title" content="'.
    stream nextPutAll: (self escapeHtml: aPaper title).
    stream nextPutAll: '">' ; lf.
    
    "citation_author - uno per autore"
    authors := aPaper allAuthors.
    (authors isString 
        ifTrue: [ authors substrings: ',' ] 
        ifFalse: [ authors ]) do: [ :author |
            stream nextPutAll: '<meta name="citation_author" content="'.
            stream nextPutAll: (self escapeHtml: author trimBoth).
            stream nextPutAll: '">' ; lf ].
    
    "citation_publication_date"
    dateStr isEmpty ifFalse: [
        stream nextPutAll: '<meta name="citation_publication_date" content="'.
        stream nextPutAll: dateStr.
        stream nextPutAll: '">' ; lf ].
    
    "citation_pdf_url"
    stream nextPutAll: '<meta name="citation_pdf_url" content="https://ai-theoretical.org/papers/'.
    stream nextPutAll: aPaper slug.
    stream nextPutAll: '.pdf">' ; lf.
    
    "citation_abstract_html_url"
    stream nextPutAll: '<meta name="citation_abstract_html_url" content="https://ai-theoretical.org/papers/'.
    stream nextPutAll: aPaper slug.
    stream nextPutAll: '.html">' ; lf.
    
    "citation_publisher"
    stream nextPutAll: '<meta name="citation_publisher" content="AI-Theoretical">' ; lf
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> jsonLdForPaper: aPaper [
    "Genera JSON-LD Schema.org per un paper accademico"
    | dict authorsList dateStr pdfUrl pageUrl |
    
    dateStr := aPaper date 
        ifNil: [ '' ] 
        ifNotNil: [ :d | d yyyymmdd ].
    
    pdfUrl := 'https://ai-theoretical.org/papers/', aPaper slug, '.pdf'.
    pageUrl := 'https://ai-theoretical.org/papers/', aPaper slug, '.html'.
    
    "Costruisce lista autori - gestisce sia Array che String"
    authorsList := aPaper allAuthors.
    authorsList := (authorsList isString 
        ifTrue: [ authorsList substrings: ',' ] 
        ifFalse: [ authorsList ]) collect: [ :name |
            Dictionary new
                at: '@type' put: 'Person';
                at: 'name' put: name trimBoth;
                yourself ].
    
    dict := Dictionary new.
    dict at: '@context' put: 'https://schema.org'.
    dict at: '@type' put: 'ScholarlyArticle'.
    dict at: 'headline' put: aPaper title.
    dict at: 'name' put: aPaper title.
    dict at: 'author' put: authorsList asArray.
    dict at: 'datePublished' put: dateStr.
    dict at: 'abstract' put: (aPaper abstract ifNil: [ '' ]).
    dict at: 'url' put: pageUrl.
    
    "Publisher"
    dict at: 'publisher' put: (Dictionary new
        at: '@type' put: 'Organization';
        at: 'name' put: 'AI-Theoretical';
        at: 'url' put: 'https://ai-theoretical.org';
        yourself).
    
    "PDF come encoding"
    dict at: 'encoding' put: (Dictionary new
        at: '@type' put: 'MediaObject';
        at: 'contentUrl' put: pdfUrl;
        at: 'encodingFormat' put: 'application/pdf';
        yourself).
    
    "Track come genre"
    aPaper track ifNotNil: [ :t |
        dict at: 'genre' put: t ].
    
    "AI models usati"
    aPaper aiModels ifNotNil: [ :models |
        models isEmpty ifFalse: [
            dict at: 'funder' put: (Dictionary new
                at: '@type' put: 'Organization';
                at: 'name' put: 'AI Models: ', models;
                yourself) ] ].
    
    ^ NeoJSONWriter toStringPretty: dict
]

{ #category : 'accessing' }
ATSiteGenerator >> outputPath [
^ outputPath
]

{ #category : 'accessing' }
ATSiteGenerator >> outputPath: aPath [
outputPath := aPath
]

{ #category : 'private' }
ATSiteGenerator >> paperPageCSS [
	^ '
:root { --accent-blue: #2563eb; --text-main: #1a1a1a; --text-muted: #666; --border: #e5e5e0; }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: Inter, sans-serif; background: #fff; color: var(--text-main); line-height: 1.7; padding: 40px; }
.container { max-width: 800px; margin: 0 auto; }
nav { margin-bottom: 40px; }
nav a { color: var(--accent-blue); text-decoration: none; font-size: 0.9rem; }
h1 { font-family: Playfair Display, serif; font-size: 2.2rem; margin-bottom: 15px; line-height: 1.3; }
.meta { color: var(--text-muted); margin-bottom: 25px; font-size: 0.95rem; }
.ai-tag { background: var(--accent-blue); color: #fff; padding: 2px 8px; border-radius: 3px; font-size: 0.8rem; }
.version-tag { background: #e5e5e0; padding: 2px 8px; border-radius: 3px; font-size: 0.8rem; margin-left: 10px; }
.btn { display: inline-block; padding: 10px 20px; margin-right: 10px; margin-bottom: 10px; text-decoration: none; border-radius: 4px; font-size: 0.9rem; }
.btn-black { background: var(--text-main); color: #fff; }
.btn-black:hover { background: var(--accent-blue); }
.withdrawn-notice { background: #ffcccc; padding: 20px; margin-bottom: 25px; border-radius: 6px; border-left: 4px solid #c00; }
section { margin: 35px 0; padding-top: 25px; border-top: 1px solid var(--border); }
section h2 { font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; color: var(--text-muted); margin-bottom: 15px; }
section p, section pre { font-size: 0.95rem; }
pre { white-space: pre-wrap; font-family: inherit; background: #f9f9f9; padding: 15px; border-radius: 4px; }
footer { margin-top: 60px; padding-top: 30px; border-top: 1px solid var(--border); text-align: center; }
.powered-by { font-size: 0.85rem; color: var(--text-main); }
.powered-by a { color: var(--text-main); text-decoration: none; }
.powered-by a:hover { text-decoration: underline; }
'
]

{ #category : 'generating' }
ATSiteGenerator >> regenerateAll [
self cleanSeoPages.
^ self generateAll
]

{ #category : 'configuration' }
ATSiteGenerator >> removeStaticPage: aPageName [
    self staticPages remove: aPageName ifAbsent: []
]

{ #category : 'rendering' }
ATSiteGenerator >> renderPaperContent: aPaper to: stream [
	"Genera il contenuto HTML del paper"
	| dateStr |
	dateStr := aPaper date ifNil: [ '' ] ifNotNil: [ :d | d asString ].
	"Notice se withdrawn"
	aPaper isWithdrawn ifTrue: [
		stream nextPutAll: '<div class="withdrawn-notice">'.
		stream nextPutAll: '<strong>WITHDRAWN</strong><br>'.
		stream nextPutAll: (aPaper withdrawalReason ifNil: [ 'This paper has been withdrawn by the author.' ]).
		stream nextPutAll: '</div>'; lf ].
	"Titolo e meta"
	stream nextPutAll: '<h1>'; nextPutAll: aPaper title; nextPutAll: '</h1>'; lf.
	stream nextPutAll: '<p class="meta">By <strong>'; nextPutAll: (aPaper authors ifNil: [ '' ]); nextPutAll: '</strong>'.
	stream nextPutAll: ' & <span class="ai-tag">'; nextPutAll: (aPaper aiModels ifNil: [ '' ]); nextPutAll: '</span>'.
	stream nextPutAll: ' | '; nextPutAll: dateStr.
	(aPaper pages notNil and: [ aPaper pages notEmpty ]) ifTrue: [
		stream nextPutAll: ' • '; nextPutAll: aPaper pages; nextPutAll: ' pages' ].
	aPaper version > 1 ifTrue: [
		stream nextPutAll: '<span class="version-tag">v'; nextPutAll: aPaper version asString; nextPutAll: '</span>' ].
	stream nextPutAll: '</p>'; lf.
	"Download button"
	aPaper isActive ifTrue: [
		stream nextPutAll: '<a href="'; nextPutAll: aPaper slug; nextPutAll: '.pdf" class="btn btn-black" download>Download PDF</a>'; lf ].
	"Abstract"
	(aPaper abstract notNil and: [ aPaper abstract notEmpty ]) ifTrue: [
		stream nextPutAll: '<section><h2>Abstract</h2><p>'; nextPutAll: aPaper abstract; nextPutAll: '</p></section>'; lf ].
	"AI Collaboration"
	(aPaper aiCollaboration notNil and: [ aPaper aiCollaboration notEmpty ]) ifTrue: [
		stream nextPutAll: '<section><h2>AI Collaboration</h2><p>'; nextPutAll: aPaper aiCollaboration; nextPutAll: '</p></section>'; lf ].
	"AI Assessment"
	(aPaper aiAssessment notNil and: [ aPaper aiAssessment notEmpty ]) ifTrue: [
		stream nextPutAll: '<section><h2>AI Editorial Assessment</h2><pre>'; nextPutAll: aPaper aiAssessment; nextPutAll: '</pre></section>'; lf ].
	"Notes"
	(aPaper notes notNil and: [ aPaper notes notEmpty ]) ifTrue: [
		stream nextPutAll: '<section><h2>Notes</h2><pre>'; nextPutAll: aPaper notes; nextPutAll: '</pre></section>'; lf ].
	"Footer"
	stream nextPutAll: '<footer><div class="powered-by">Powered by <a href="https://www.anthropic.com/claude" target="_blank">Claude AI</a> and <a href="https://pharo.org" target="_blank">Pharo Smalltalk</a></div></footer>'; lf
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> renderRssItem: aPaper to: stream [
    "Genera un item RSS per un paper"
    | dateStr truncatedAbstract |
    
    dateStr := aPaper date 
        ifNil: [ '' ] 
        ifNotNil: [ :d | d asDateAndTime asRFC2822String ].
    truncatedAbstract := self escapeXml: (self truncateAbstract: (aPaper abstract ifNil: [ '' ])).
    
    stream nextPutAll: '<item>'; lf.
    stream nextPutAll: '<title>'; nextPutAll: (self escapeXml: aPaper title); nextPutAll: '</title>'; lf.
    stream nextPutAll: '<link>https://ai-theoretical.org/papers/'; nextPutAll: aPaper slug; nextPutAll: '.html</link>'; lf.
    stream nextPutAll: '<guid isPermaLink="true">https://ai-theoretical.org/papers/'; nextPutAll: aPaper slug; nextPutAll: '.html</guid>'; lf.
    stream nextPutAll: '<description>'; nextPutAll: truncatedAbstract; nextPutAll: '</description>'; lf.
    
    dateStr isEmpty ifFalse: [
        stream nextPutAll: '<pubDate>'; nextPutAll: dateStr; nextPutAll: '</pubDate>'; lf ].
    
    "Autori come dc:creator"
    (aPaper allAuthors isString 
        ifTrue: [ aPaper allAuthors substrings: ',' ] 
        ifFalse: [ aPaper allAuthors ]) do: [ :author |
            stream nextPutAll: '<dc:creator>'; nextPutAll: (self escapeXml: author trimBoth); nextPutAll: '</dc:creator>'; lf ].
    
    "Link al PDF come enclosure"
    stream nextPutAll: '<enclosure url="https://ai-theoretical.org/papers/'; nextPutAll: aPaper slug; nextPutAll: '.pdf" type="application/pdf"/>'; lf.
    
    stream nextPutAll: '</item>'; lf
]

{ #category : 'accessing' }
ATSiteGenerator >> repository [
^ repository
]

{ #category : 'accessing' }
ATSiteGenerator >> repository: aRepo [
repository := aRepo
]

{ #category : 'generating' }
ATSiteGenerator >> seoPageForPaper: aPaper [
    "Genera pagina HTML completa per un paper con meta tags SEO/OG/Schema.org"
    | stream abstract dateStr truncatedAbstract |
    stream := WriteStream on: String new.
    abstract := aPaper abstract ifNil: [ '' ].
    truncatedAbstract := self truncateAbstract: abstract.
    dateStr := aPaper date ifNil: [ '' ] ifNotNil: [ :d | d asString ].
    
    stream nextPutAll: '<!DOCTYPE html>'; lf.
    stream nextPutAll: '<html lang="en">'; lf.
    stream nextPutAll: '<head>'; lf.
    stream nextPutAll: '<meta charset="UTF-8">'; lf.
    stream nextPutAll: '<meta name="viewport" content="width=device-width, initial-scale=1.0">'; lf.
    stream nextPutAll: '<link rel="icon" type="image/svg+xml" href="../favicon.svg">'; lf.
    
    "Robots directive"
    aPaper isWithdrawn ifTrue: [
        stream nextPutAll: '<meta name="robots" content="noindex">'; lf ].
    
    "Title"
    stream nextPutAll: '<title>'; nextPutAll: (self escapeHtml: aPaper title); nextPutAll: ' — AI-Theoretical</title>'; lf.
    
    "Standard meta"
    stream nextPutAll: '<meta name="description" content="'; nextPutAll: (self escapeHtml: truncatedAbstract); nextPutAll: '">'; lf.
    stream nextPutAll: '<meta name="keywords" content="AI, theoretical papers, human-AI collaboration, '; nextPutAll: (self escapeHtml: aPaper authors); nextPutAll: '">'; lf.
    
    "Google Scholar meta tags"
    self googleScholarMetaTagsForPaper: aPaper to: stream.
    
    "Open Graph"
    stream nextPutAll: '<meta property="og:title" content="'; nextPutAll: (self escapeHtml: aPaper title); nextPutAll: ' — AI-Theoretical">'; lf.
    stream nextPutAll: '<meta property="og:description" content="'; nextPutAll: (self escapeHtml: truncatedAbstract); nextPutAll: '">'; lf.
    stream nextPutAll: '<meta property="og:url" content="https://ai-theoretical.org/papers/'; nextPutAll: aPaper slug; nextPutAll: '.html">'; lf.
    stream nextPutAll: '<meta property="og:type" content="article">'; lf.
    stream nextPutAll: '<meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; lf.
    
    "Twitter Cards"
    self twitterCardsForPaper: aPaper to: stream.
    
    "Canonical"
    stream nextPutAll: '<link rel="canonical" href="https://ai-theoretical.org/papers/'; nextPutAll: aPaper slug; nextPutAll: '.html">'; lf.
    
    "RSS Feed"
    stream nextPutAll: '<link rel="alternate" type="application/rss+xml" title="AI-Theoretical RSS Feed" href="https://ai-theoretical.org/feed.xml">'; lf.
    
    "JSON-LD Schema.org"
    stream nextPutAll: '<script type="application/ld+json">'; lf.
    stream nextPutAll: (self jsonLdForPaper: aPaper).
    stream nextPutAll: '</script>'; lf.
    
    "Fonts and CSS"
    stream nextPutAll: '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">'; lf.
    stream nextPutAll: '<style>'; nextPutAll: self paperPageCSS; nextPutAll: '</style>'; lf.
    stream nextPutAll: '</head>'; lf.
    stream nextPutAll: '<body>'; lf.
    stream nextPutAll: '<div class="container">'; lf.
    stream nextPutAll: '<nav><a href="/">← Back to AI-Theoretical</a></nav>'; lf.
    self renderPaperContent: aPaper to: stream.
    stream nextPutAll: '</div>'; lf.
    stream nextPutAll: '</body></html>'.
    ^ stream contents
]

{ #category : 'accessing' }
ATSiteGenerator >> staticPages [
    "Ritorna le pagine statiche, con default se non configurate"
    ^ staticPages ifNil: [ staticPages := self defaultStaticPages ]
]

{ #category : 'accessing' }
ATSiteGenerator >> staticPages: aCollection [
    staticPages := aCollection asOrderedCollection
]

{ #category : 'private' }
ATSiteGenerator >> truncateAbstract: aString [
	| clean |
	clean := aString copyReplaceAll: '"' with: ''''.
	^ clean size > 160
		ifTrue: [ (clean copyFrom: 1 to: 157), '...' ]
		ifFalse: [ clean ]
]

{ #category : 'as yet unclassified' }
ATSiteGenerator >> twitterCardsForPaper: aPaper to: stream [
    "Genera meta tags per Twitter Cards"
    | truncatedAbstract |
    
    truncatedAbstract := self truncateAbstract: (aPaper abstract ifNil: [ '' ]).
    
    stream nextPutAll: '<meta name="twitter:card" content="summary_large_image">' ; lf.
    stream nextPutAll: '<meta name="twitter:site" content="@AITheoretical">' ; lf.
    stream nextPutAll: '<meta name="twitter:title" content="'.
    stream nextPutAll: (self escapeHtml: aPaper title).
    stream nextPutAll: '">' ; lf.
    stream nextPutAll: '<meta name="twitter:description" content="'.
    stream nextPutAll: (self escapeHtml: truncatedAbstract).
    stream nextPutAll: '">' ; lf.
    stream nextPutAll: '<meta name="twitter:image" content="https://ai-theoretical.org/og-image.jpg">' ; lf
]
