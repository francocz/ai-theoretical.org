Class {
	#name : 'ATRepository',
	#superclass : 'Object',
	#instVars : [
		'papers',
		'gitRepoPath',
		'submissions',
		'apiBaseUrl',
		'apiToken'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'instance creation' }
ATRepository class >> current [

	^ Current ifNil: [ Current := self new ]
]

{ #category : 'instance creation' }
ATRepository class >> reset [
Current := nil
]

{ #category : 'submissions' }
ATRepository >> acceptRemoteSubmission: aSubmission withAssessment: assessmentText withCollaboration: collaborationText withNotes: notesText [
	"Accetta una submission remota: scarica PDF, genera pagina, aggiorna Cloudflare"
	| paper slug generator |
	"Crea paper dalla submission"
	aSubmission accept.
	paper := aSubmission asPaper.
	paper aiAssessment: assessmentText.
	paper aiCollaboration: collaborationText.
	paper notes: notesText.
	paper submissionId: aSubmission id.
	"Genera slug unico"
	slug := self uniqueSlugFor: paper.
	paper slug: slug.
	"Scarica PDF da R2"
	self downloadPdfForSubmission: aSubmission toSlug: slug.
	"Genera pagina HTML del paper"
	generator := ATSiteGenerator for: self outputTo: gitRepoPath.
	generator generateSeoPageFor: paper.
	"Aggiorna status su Cloudflare"
	self updateRemoteSubmissionStatus: aSubmission id to: 'accepted'.
	"Aggiungi al repository locale e salva papers.js"
	self addPaper: paper.
	self saveToJsFile: gitRepoPath, '/papers.js'.
	^ paper
]

{ #category : 'actions' }
ATRepository >> acceptSubmission: aSubmission withAssessment: assessmentText withCollaboration: collaborationText [
^ self acceptSubmission: aSubmission withAssessment: assessmentText withCollaboration: collaborationText withNotes: ''
]

{ #category : 'actions' }
ATRepository >> acceptSubmission: aSubmission withAssessment: assessmentText withCollaboration: collaborationText withNotes: notesText [
| paper |
aSubmission accept.
paper := aSubmission asPaper.
paper aiAssessment: assessmentText.
paper aiCollaboration: collaborationText.
paper notes: notesText.
self addPaper: paper.
^ paper
]

{ #category : 'adding' }
ATRepository >> addPaper: aPaper [
	"Aggiunge il paper, assicurando che lo slug sia unico"
	| uniqueSlug |
	aPaper slug ifNil: [ aPaper generateSlug ].
	uniqueSlug := self uniqueSlugFor: aPaper slug.
	aPaper slug: uniqueSlug.
	papers add: aPaper.
	^ aPaper
]

{ #category : 'adding' }
ATRepository >> addSubmission: aSubmission [
self submissions add: aSubmission.
^ aSubmission
]

{ #category : 'api - configuration' }
ATRepository >> apiBaseUrl [
^ apiBaseUrl ifNil: [ 'https://ai-theoretical.org/api' ]
]

{ #category : 'api - configuration' }
ATRepository >> apiBaseUrl: aUrl [
apiBaseUrl := aUrl
]

{ #category : 'api - requests' }
ATRepository >> apiGet: aPath [
"Esegue GET autenticata all'API"
| client response |
client := ZnClient new.
client url: self apiBaseUrl, aPath.
client headerAt: 'Authorization' put: 'Bearer ', self apiToken.
client get.
response := client response.
response isSuccess ifFalse: [
    self error: 'API error: ', response status asString ].
^ NeoJSONReader fromString: client contents
]

{ #category : 'api - requests' }
ATRepository >> apiPost: aPath data: aDict [
"Esegue POST autenticata all'API"
| client response |
client := ZnClient new.
client url: self apiBaseUrl, aPath.
client headerAt: 'Authorization' put: 'Bearer ', self apiToken.
client headerAt: 'Content-Type' put: 'application/json'.
client entity: (ZnEntity json: (NeoJSONWriter toString: aDict)).
client post.
response := client response.
response isSuccess ifFalse: [
    self error: 'API error: ', response status asString ].
^ NeoJSONReader fromString: client contents
]

{ #category : 'api - configuration' }
ATRepository >> apiToken [
^ apiToken
]

{ #category : 'api - configuration' }
ATRepository >> apiToken: aToken [
apiToken := aToken
]

{ #category : 'exporting' }
ATRepository >> asJSON [
^ NeoJSONWriter toStringPretty: (papers collect: [ :p | p asDictionary ])
]

{ #category : 'converting' }
ATRepository >> asJavaScript [
	| stream lf |
	lf := String lf.
	stream := WriteStream on: String new.
	stream nextPutAll: 'const PAPERS_DATA = ['.
	stream nextPutAll: lf.
	papers doWithIndex: [ :paper :index |
		stream nextPutAll: '    {'.
		stream nextPutAll: lf.
		stream nextPutAll: '        title: "'; nextPutAll: (self escapeJsQuotes: paper title); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        author: "'; nextPutAll: (self escapeJsQuotes: paper authors); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        ai_model: "'; nextPutAll: (self escapeJsQuotes: paper aiModels); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        date: "'; nextPutAll: (self escapeJsQuotes: (paper date ifNil: [ '' ])); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        pages: "'; nextPutAll: (self escapeJsQuotes: (paper pages ifNil: [ '' ])); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        pdf_file: "papers/'; nextPutAll: (self escapeJsQuotes: paper slug); nextPutAll: '.pdf",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        seo_page: "papers/'; nextPutAll: (self escapeJsQuotes: paper slug); nextPutAll: '.html",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        slug: "'; nextPutAll: (self escapeJsQuotes: paper slug); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        version: '; nextPutAll: paper version asString; nextPutAll: ','.
		stream nextPutAll: lf.
		stream nextPutAll: '        status: "'; nextPutAll: paper status asString; nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        withdrawal_reason: "'; nextPutAll: (self escapeJsQuotes: (paper withdrawalReason ifNil: [ '' ])); nextPutAll: '",'.
		stream nextPutAll: lf.
		stream nextPutAll: '        abstract: `'; nextPutAll: (self escapeBackticks: (paper abstract ifNil: [ '' ])); nextPutAll: '`,'.
		stream nextPutAll: lf.
		stream nextPutAll: '        ai_assessment: `'; nextPutAll: (self escapeBackticks: (paper aiAssessment ifNil: [ '' ])); nextPutAll: '`,'.
		stream nextPutAll: lf.
		stream nextPutAll: '        ai_collaboration: `'; nextPutAll: (self escapeBackticks: (paper aiCollaboration ifNil: [ '' ])); nextPutAll: '`,'.
		stream nextPutAll: lf.
		stream nextPutAll: '        notes: "'; nextPutAll: (self escapeJsQuotes: (paper notes ifNil: [ '' ])); nextPutAll: '"'.
		stream nextPutAll: lf.
		stream nextPutAll: '    }'.
		index < papers size ifTrue: [ stream nextPutAll: ',' ].
		stream nextPutAll: lf ].
	stream nextPutAll: '];'.
	^ stream contents
]

{ #category : 'removing' }
ATRepository >> deletePaper: aPaper [
	"Cancella un paper e tutti i file associati (PDF, pagina SEO)"
	| papersDir pdfFile seoFile |
	
	"Verifica che il paper esista"
	(papers includes: aPaper) ifFalse: [ 
		self error: 'Paper not found in repository' ].
	
	"Percorsi dei file"
	papersDir := gitRepoPath asFileReference / 'papers'.
	pdfFile := papersDir / (aPaper slug, '.pdf').
	seoFile := papersDir / (aPaper slug, '.html').
	
	"Cancella PDF se esiste"
	pdfFile exists ifTrue: [ pdfFile delete ].
	
	"Cancella pagina SEO se esiste"
	seoFile exists ifTrue: [ seoFile delete ].
	
	"Rimuovi dalla collection"
	papers remove: aPaper.
	
	"Salva papers.js aggiornato"
	self saveToJsFile: gitRepoPath, '/papers.js'.
	
	^ aPaper
]

{ #category : 'removing' }
ATRepository >> deletePaperBySlug: aSlug [
	"Cancella un paper dato lo slug"
	| paper |
	paper := self paperWithSlug: aSlug.
	paper ifNil: [ self error: 'Paper not found: ', aSlug ].
	^ self deletePaper: paper
]

{ #category : 'deployment' }
ATRepository >> deploy [
    "Pubblica tutto su GitHub: papers.js, SEO pages, sitemap, commit e push"
    | gen repoPath |
    repoPath := self gitRepoPath asFileReference.
    
    "1. Salva papers.js"
    self saveToJsFile: (repoPath / 'papers.js') pathString.
    
    "2. Genera SEO pages e sitemap"
    gen := ATSiteGenerator new.
    gen repository: self.
    gen outputPath: repoPath pathString.
    gen generateAllSeoPages.
    gen generateSitemap.
    
    "3. Git add, commit, push"
    LibC system: 'cd ' , repoPath pathString , ' && git add -A && git commit -m "Update papers" && git push'.
    
    ^ 'Deployed to GitHub'
]

{ #category : 'pdf' }
ATRepository >> downloadPdfForSubmission: aSubmission toSlug: aSlug [
	"Scarica il PDF da R2 via API e lo salva nella cartella papers"
	| pdfUrl client pdfBytes papersDir destFile |
	aSubmission id ifNil: [ ^ false ].
	"Costruisci URL per download PDF"
	pdfUrl := apiBaseUrl, '/submission/', aSubmission id, '/pdf'.
	"Download PDF"
	client := ZnClient new.
	client url: pdfUrl.
	client headerAt: 'Authorization' put: 'Bearer ', apiToken.
	client setBinaryMode.
	client get.
	client isSuccess ifFalse: [ ^ false ].
	pdfBytes := client contents.
	"Salva in papers/"
	papersDir := gitRepoPath asFileReference / 'papers'.
	papersDir ensureCreateDirectory.
	destFile := papersDir / (aSlug, '.pdf').
	destFile binaryWriteStreamDo: [ :stream |
		stream nextPutAll: pdfBytes ].
	^ true
]

{ #category : 'private' }
ATRepository >> escapeBackticks: aString [
	"Escape backticks per template literals JavaScript"
	| result |
	aString ifNil: [ ^ '' ].
	result := aString copyReplaceAll: '`' with: '\`'.
	result := result copyReplaceAll: '${' with: '\${'."escape interpolation"
	^ result
]

{ #category : 'private' }
ATRepository >> escapeJs: aString [
    "Escape caratteri speciali per stringhe JavaScript tra virgolette"
    | result |
    aString ifNil: [ ^ '' ].
    result := aString copyReplaceAll: '\' with: '\\'.
    result := result copyReplaceAll: '"' with: '\"'.
    result := result copyReplaceAll: String cr with: '\n'.
    result := result copyReplaceAll: String lf with: '\n'.
    ^ result
]

{ #category : 'private' }
ATRepository >> escapeJsQuotes: aString [
    "Escape caratteri speciali per stringhe JavaScript tra virgolette doppie"
    | result |
    aString ifNil: [ ^ '' ].
    result := aString copyReplaceAll: '\' with: '\\'.
    result := result copyReplaceAll: '"' with: '\"'.
    ^ result
]

{ #category : 'api - submissions' }
ATRepository >> fetchRemoteSubmissions [
"Scarica le submission pending dall'API Cloudflare"
| data subClass |
subClass := Smalltalk globals at: #ATSubmission.
data := self apiGet: '/submissions'.
^ data collect: [ :dict |
    subClass fromDictionary: dict ]
]

{ #category : 'accessing' }
ATRepository >> gitRepoPath [
^ gitRepoPath
]

{ #category : 'accessing' }
ATRepository >> gitRepoPath: aPath [
gitRepoPath := aPath
]

{ #category : 'querying' }
ATRepository >> hasSlug: aSlug [
^ papers anySatisfy: [ :p | p slug = aSlug ]
]

{ #category : 'initialization' }
ATRepository >> initialize [
papers := OrderedCollection new.
submissions := OrderedCollection new.
gitRepoPath := '/path/to/repo'
]

{ #category : 'importing' }
ATRepository >> loadFromFile: aFilePath [
| content |
content := aFilePath asFileReference contents.
self loadFromJSON: content
]

{ #category : 'importing' }
ATRepository >> loadFromJSON: aString [
| data paperClass |
paperClass := Smalltalk globals at: #ATPaper.
data := NeoJSONReader fromString: aString.
papers := OrderedCollection new.
data do: [ :dict |
    self addPaper: (paperClass fromDictionary: dict) ]
]

{ #category : 'querying' }
ATRepository >> paperWithSlug: aSlug [
^ papers detect: [ :p | p slug = aSlug ] ifNone: [ nil ]
]

{ #category : 'accessing' }
ATRepository >> papers [
^ papers
]

{ #category : 'querying' }
ATRepository >> pendingSubmissions [
^ self submissions select: [ :s | s isPending ]
]

{ #category : 'api' }
ATRepository >> rejectRemoteSubmission: aSubmission [
    "Rifiuta una submission su Cloudflare"
    self updateRemoteSubmissionStatus: aSubmission id to: 'rejected'.
    aSubmission status: #rejected.
    ^ aSubmission
]

{ #category : 'actions' }
ATRepository >> rejectSubmission: aSubmission [
aSubmission reject
]

{ #category : 'exporting' }
ATRepository >> saveToFile: aFilePath [
aFilePath asFileReference writeStreamDo: [ :stream |
    stream nextPutAll: self asJSON ]
]

{ #category : 'exporting' }
ATRepository >> saveToJsFile: aFilePath [
aFilePath asFileReference writeStreamDo: [ :stream |
    stream nextPutAll: self asJavaScript ]
]

{ #category : 'searching' }
ATRepository >> search: aString [
	"Ricerca full-text in titolo, abstract e autore"
	| query |
	query := aString asLowercase.
	^ papers select: [ :p |
		(p title asLowercase includesSubstring: query) or: [
		(p authors asLowercase includesSubstring: query) or: [
		p abstract notNil and: [ p abstract asLowercase includesSubstring: query ] ] ] ]
]

{ #category : 'searching' }
ATRepository >> searchByAbstract: aString [
	"Cerca papers per keyword nell'abstract (case insensitive)"
	| query |
	query := aString asLowercase.
	^ papers select: [ :p | 
		p abstract notNil and: [ p abstract asLowercase includesSubstring: query ] ]
]

{ #category : 'searching' }
ATRepository >> searchByAuthor: aString [
	"Cerca papers per autore (case insensitive, partial match)"
	| query |
	query := aString asLowercase.
	^ papers select: [ :p | p authors asLowercase includesSubstring: query ]
]

{ #category : 'searching' }
ATRepository >> searchByDateFrom: startDate to: endDate [
	"Cerca papers in un range di date"
	^ papers select: [ :p |
		| paperDate |
		paperDate := [ Date fromString: p date ] on: Error do: [ nil ].
		paperDate notNil and: [ paperDate >= startDate and: [ paperDate <= endDate ] ] ]
]

{ #category : 'searching' }
ATRepository >> searchByTitle: aString [
	"Cerca papers per titolo (case insensitive, partial match)"
	| query |
	query := aString asLowercase.
	^ papers select: [ :p | p title asLowercase includesSubstring: query ]
]

{ #category : 'searching' }
ATRepository >> searchByYear: aYear [
	"Cerca papers di un anno specifico"
	| yearString |
	yearString := aYear asString.
	^ papers select: [ :p | 
		p date notNil and: [ p date includesSubstring: yearString ] ]
]

{ #category : 'searching' }
ATRepository >> searchWithCriteria: aCriteriaDict [
	"Ricerca con criteri multipli: author, title, abstract, year, keywords"
	| results |
	results := papers.
	(aCriteriaDict at: 'author' ifAbsent: [nil]) ifNotNil: [ :v |
		v ifNotEmpty: [ results := results select: [ :p | p authors asLowercase includesSubstring: v asLowercase ] ] ].
	(aCriteriaDict at: 'title' ifAbsent: [nil]) ifNotNil: [ :v |
		v ifNotEmpty: [ results := results select: [ :p | p title asLowercase includesSubstring: v asLowercase ] ] ].
	(aCriteriaDict at: 'abstract' ifAbsent: [nil]) ifNotNil: [ :v |
		v ifNotEmpty: [ results := results select: [ :p | p abstract notNil and: [ p abstract asLowercase includesSubstring: v asLowercase ] ] ] ].
	(aCriteriaDict at: 'year' ifAbsent: [nil]) ifNotNil: [ :v |
		v ifNotEmpty: [ results := results select: [ :p | p date notNil and: [ p date includesSubstring: v asString ] ] ] ].
	(aCriteriaDict at: 'keywords' ifAbsent: [nil]) ifNotNil: [ :v |
		v ifNotEmpty: [ 
			| keywords |
			keywords := (v substrings: ' ,') collect: #asLowercase.
			results := results select: [ :p |
				| text |
				text := (p title, ' ', p authors, ' ', (p abstract ifNil: [''])) asLowercase.
				keywords allSatisfy: [ :kw | text includesSubstring: kw ] ] ] ].
	^ results
]

{ #category : 'accessing' }
ATRepository >> submissions [
^ submissions ifNil: [ submissions := OrderedCollection new ]
]

{ #category : 'api - submissions' }
ATRepository >> syncSubmissions [
"Scarica e aggiorna le submission locali"
submissions := self fetchRemoteSubmissions asOrderedCollection
]

{ #category : 'private' }
ATRepository >> uniqueSlugFor: aBaseSlug [
| candidate counter |
candidate := aBaseSlug.
counter := 2.
[ self hasSlug: candidate ] whileTrue: [
    candidate := aBaseSlug, '-', counter asString.
    counter := counter + 1 ].
^ candidate
]

{ #category : 'api - submissions' }
ATRepository >> updateRemoteSubmissionStatus: submissionId to: newStatus [
"Aggiorna lo status di una submission su Cloudflare"
^ self apiPost: '/submission/', submissionId, '/status' data: { 'status' -> newStatus } asDictionary
]
