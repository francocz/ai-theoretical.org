Class {
	#name : 'ATRepository',
	#superclass : 'Object',
	#instVars : [
		'papers',
		'gitRepoPath',
		'submissions',
		'apiBaseUrl',
		'apiToken',
		'pendingVersionUpdates'
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
    "Accetta una submission remota: scarica PDF, genera pagina, aggiorna Cloudflare, deploya"
    | paper slug generator allAuthors pdfDownloaded |
    
    "Crea paper dalla submission"
    aSubmission accept.
    paper := aSubmission asPaper.
    paper aiAssessment: assessmentText.
    paper aiCollaboration: collaborationText.
    paper notes: notesText.
    paper submissionId: aSubmission id.
    
    "Estrai lista autori dall assessment AI"
    allAuthors := ATAutomation current parseAuthors: assessmentText.
    allAuthors isEmpty ifTrue: [
        "Fallback: usa solo il corresponding author"
        allAuthors := { aSubmission authorName } ].
    paper allAuthors: allAuthors.
    
    "Genera slug dal titolo"
    paper generateSlug.
    slug := self uniqueSlugFor: paper slug.
    paper slug: slug.
    
    "Scarica PDF da R2"
    pdfDownloaded := self downloadPdfForSubmission: aSubmission toSlug: slug.
    pdfDownloaded ifFalse: [
        Transcript show: '[Accept] WARNING: PDF download failed for ', slug; cr ].
    
    "Genera pagina HTML del paper"
    generator := ATSiteGenerator for: self outputTo: gitRepoPath.
    generator generateSeoPageFor: paper.
    
    "Aggiorna status su Cloudflare"
    self updateRemoteSubmissionStatus: aSubmission id to: 'accepted'.
    
    "Aggiungi al repository locale e salva papers.js"
    papers add: paper.
    self saveToJsFile: gitRepoPath, '/papers.js'.
    
    "Deploy automatico"
    ATDeployment deployGitRepoPath: gitRepoPath withMessage: 'Published: ', paper title.
    
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
        stream nextPutAll: '        title: '; nextPutAll: (self jsBacktickValue: paper title); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        author: '; nextPutAll: (self jsBacktickValue: paper authors); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        ai_model: '; nextPutAll: (self jsBacktickValue: paper aiModels); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        date: '; nextPutAll: (self jsBacktickValue: paper date); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        pages: '; nextPutAll: (self jsBacktickValue: paper pages); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        pdf_file: '; nextPutAll: (self jsBacktickValue: 'papers/', paper slug, '.pdf'); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        seo_page: '; nextPutAll: (self jsBacktickValue: 'papers/', paper slug, '.html'); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        slug: '; nextPutAll: (self jsBacktickValue: paper slug); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        track: '; nextPutAll: (self jsBacktickValue: paper track); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        version: '; nextPutAll: paper version asString; nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        status: '; nextPutAll: (self jsBacktickValue: paper status asString); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        withdrawal_reason: '; nextPutAll: (self jsBacktickValue: paper withdrawalReason); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        abstract: '; nextPutAll: (self jsBacktickValue: paper abstract); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        ai_assessment: '; nextPutAll: (self jsBacktickValue: paper aiAssessment); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        ai_collaboration: '; nextPutAll: (self jsBacktickValue: paper aiCollaboration); nextPutAll: ','.
        stream nextPutAll: lf.
        stream nextPutAll: '        notes: '; nextPutAll: (self jsBacktickValue: paper notes).
        stream nextPutAll: lf.
        stream nextPutAll: '    }'.
        index < papers size ifTrue: [ stream nextPutAll: ',' ].
        stream nextPutAll: lf ].
    stream nextPutAll: '];'.
    ^ stream contents
]

{ #category : 'as yet unclassified' }
ATRepository >> completeVersionUpdate: uploadToken pdfBytes: pdfBytes [
    "Completa l''upload di una nuova versione"
    | updateInfo paper slug newVersion newTrack pdfPath |
    
    pendingVersionUpdates ifNil: [ 
        ^ Dictionary new at: #success put: false; at: #error put: 'No pending update'; yourself ].
    
    updateInfo := pendingVersionUpdates at: uploadToken ifAbsent: [ 
        ^ Dictionary new at: #success put: false; at: #error put: 'Invalid upload token'; yourself ].
    
    "Verifica scadenza"
    (DateAndTime now > (updateInfo at: #expiresAt)) ifTrue: [
        pendingVersionUpdates removeKey: uploadToken.
        ^ Dictionary new at: #success put: false; at: #error put: 'Upload token expired'; yourself ].
    
    slug := updateInfo at: #slug.
    newVersion := updateInfo at: #newVersion.
    newTrack := updateInfo at: #newTrack.
    
    paper := self paperForSlug: slug.
    paper ifNil: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Paper not found'; yourself ].
    
    "Aggiorna paper"
    paper version: newVersion.
    newTrack ifNotNil: [ paper track: newTrack ].
    
    "Salva nuovo PDF"
    pdfPath := gitRepoPath asFileReference / 'papers' / (slug, '.pdf').
    pdfPath ensureDelete.
    pdfPath binaryWriteStreamDo: [ :s | s nextPutAll: pdfBytes ].
    
    "Rigenera sito"
    self generateSite.
    self deploy.
    
    "Rimuovi update pendente"
    pendingVersionUpdates removeKey: uploadToken.
    
    "Log"
    Transcript show: 'Paper updated: ', slug, ' to version ', newVersion asString; cr.
    
    ^ Dictionary new
        at: #success put: true;
        at: #message put: 'Paper updated to version ', newVersion asString;
        at: #version put: newVersion;
        yourself
]

{ #category : 'actions' }
ATRepository >> deletePaper: aPaper [
    "Cancella un paper e tutti i file associati (PDF, pagina SEO), rigenera index e fa push"
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
    
    "Rigenera index.html con la lista aggiornata"
    ATIndexPage new saveTo: gitRepoPath.
    
    "Deploy automatico"
    ATDeployment deployGitRepoPath: gitRepoPath withMessage: 'Deleted: ', aPaper title.
    
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
    "Scarica il PDF da R2 via API e lo salva nella cartella papers. Ritenta 3 volte."
    | pdfUrl client pdfBytes papersDir destFile attempts |
    aSubmission id ifNil: [ 
        Transcript show: '[PDF Download] ERROR: submission id is nil'; cr.
        ^ false ].
    
    pdfUrl := apiBaseUrl, '/submission/', aSubmission id, '/pdf'.
    papersDir := gitRepoPath asFileReference / 'papers'.
    papersDir ensureCreateDirectory.
    destFile := papersDir / (aSlug, '.pdf').
    
    attempts := 0.
    [ attempts < 3 ] whileTrue: [
        attempts := attempts + 1.
        Transcript show: '[PDF Download] Attempt ', attempts asString, ' for ', aSlug; cr.
        
        [ 
            client := ZnClient new.
            client url: pdfUrl.
            client headerAt: 'Authorization' put: 'Bearer ', apiToken.
            client timeout: 120.
            client get.
            
            client isSuccess ifTrue: [
                pdfBytes := client contents asByteArray.
                destFile binaryWriteStreamDo: [ :stream |
                    stream nextPutAll: pdfBytes ].
                Transcript show: '[PDF Download] SUCCESS: ', aSlug, ' (', pdfBytes size asString, ' bytes)'; cr.
                ^ true ]
            ifFalse: [
                Transcript show: '[PDF Download] HTTP Error: ', client response status asString; cr ]
        ] on: Error do: [ :ex |
            Transcript show: '[PDF Download] Exception: ', ex messageText; cr ].
        
        "Aspetta 2 secondi prima di ritentare"
        (Delay forSeconds: 2) wait ].
    
    Transcript show: '[PDF Download] FAILED after 3 attempts: ', aSlug; cr.
    ^ false
]

{ #category : 'as yet unclassified' }
ATRepository >> ensureGitignorePrivateData [
	"Assicura che private-data sia in .gitignore"
	| gitignoreFile content newLine |
	gitignoreFile := gitRepoPath asFileReference / '.gitignore'.
	content := gitignoreFile exists 
		ifTrue: [ gitignoreFile contents ]
		ifFalse: [ '' ].
	
	newLine := 'private-data/'.
	(content includesSubstring: newLine) ifTrue: [ ^ 'Already in .gitignore' ].
	
	gitignoreFile writeStreamDo: [ :s |
		s nextPutAll: content.
		content isEmpty ifFalse: [ 
			(content endsWith: String lf) ifFalse: [ s lf ] ].
		s nextPutAll: '# Sensitive data - emails and personal info'; lf.
		s nextPutAll: newLine; lf ].
	
	^ 'Added private-data/ to .gitignore'
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

{ #category : 'as yet unclassified' }
ATRepository >> getRateLimitStatus [
    "Recupera stato rate limit dall'API"
    ^ self apiGet: '/rate-limit'
]

{ #category : 'accessing' }
ATRepository >> gitRepoPath [
^ gitRepoPath
]

{ #category : 'accessing' }
ATRepository >> gitRepoPath: aPath [
gitRepoPath := aPath
]

{ #category : 'as yet unclassified' }
ATRepository >> handleUpdateRequest: anEmail [
    "Gestisce una richiesta di update. Ritorna dizionario con risultato."
    | registry request papers |
    
    "Verifica rate limit"
    registry := ATUpdateRegistry current.
    (registry canRequestForEmail: anEmail) ifFalse: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Too many requests. Please try again tomorrow.';
            yourself ].
    
    "Verifica se ci sono paper per questa email"
    papers := self papersForAuthorEmail: anEmail.
    papers isEmpty ifTrue: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'No published papers found for this email address.';
            yourself ].
    
    "Crea richiesta e invia email"
    request := registry createRequestForEmail: anEmail.
    
    [ self sendUpdateEmail: anEmail token: request token papers: papers ]
        on: Error
        do: [ :e |
            registry invalidateToken: request token.
            ^ Dictionary new
                at: #success put: false;
                at: #error put: 'Failed to send email. Please try again later.';
                yourself ].
    
    ^ Dictionary new
        at: #success put: true;
        yourself
]

{ #category : 'as yet unclassified' }
ATRepository >> hasPublishedPapersForEmail: anEmail [
    "Verifica se questa email ha paper pubblicati"
    ^ (self papersForAuthorEmail: anEmail) notEmpty
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

{ #category : 'as yet unclassified' }
ATRepository >> jsBacktickValue: aValueOrNil [
    "Formatta un valore per JavaScript usando backticks (per stringhe multilinea)"
    | str |
    str := aValueOrNil ifNil: [ '' ] ifNotNil: [ :v |
        v isString 
            ifTrue: [ v ]
            ifFalse: [ 
                (v respondsTo: #yyyymmdd)
                    ifTrue: [ v yyyymmdd ]
                    ifFalse: [ v asString ] ] ].
    ^ '`', (self escapeBackticks: str), '`'
]

{ #category : 'as yet unclassified' }
ATRepository >> jsQuotedValue: aStringOrNil [
    "Formatta un valore per JavaScript usando virgolette doppie (per stringhe semplici)"
    ^ '"', (self escapeJsQuotes: (aStringOrNil ifNil: [ '' ])), '"'
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

{ #category : 'as yet unclassified' }
ATRepository >> newVersionForPaperWithSlug: aSlug token: aToken pdfBytes: pdfBytes newTrack: trackOrNil [
    "Aggiunge nuova versione di un paper"
    | request paper newVersion |
    
    request := ATUpdateRegistry current requestForToken: aToken.
    request ifNil: [ 
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Invalid or expired token.';
            yourself ].
    
    paper := self paperWithSlug: aSlug.
    paper ifNil: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Paper not found.';
            yourself ].
    
    "Verifica che il paper appartenga all''autore"
    paper authorEmail asLowercase = request email asLowercase ifFalse: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'You are not authorized to modify this paper.';
            yourself ].
    
    paper isWithdrawn ifTrue: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Cannot update a withdrawn paper.';
            yourself ].
    
    "Incrementa versione"
    newVersion := (paper version ifNil: [ 1 ]) + 1.
    paper version: newVersion.
    
    "Cambia track se richiesto"
    (trackOrNil notNil and: [ trackOrNil notEmpty ]) ifTrue: [
        paper track: trackOrNil ].
    
    "Salva nuovo PDF"
    self savePdfBytes: pdfBytes forSlug: aSlug.
    
    "Aggiorna data"
    paper date: Date today.
    
    self savePapers.
    self regenerateAllPages.
    self deploy.
    
    ^ Dictionary new
        at: #success put: true;
        at: #version put: newVersion;
        yourself
]

{ #category : 'querying' }
ATRepository >> paperWithSlug: aSlug [
^ papers detect: [ :p | p slug = aSlug ] ifNone: [ nil ]
]

{ #category : 'accessing' }
ATRepository >> papers [
^ papers
]

{ #category : 'as yet unclassified' }
ATRepository >> papersForAuthorEmail: anEmail [
    "Ritorna i paper pubblicati da questo autore"
    ^ papers select: [ :p | 
        p authorEmail asLowercase = anEmail asLowercase 
            and: [ p isWithdrawn not ] ]
]

{ #category : 'as yet unclassified' }
ATRepository >> papersForToken: aToken [
    "Ritorna i paper per un token valido, o nil se token invalido/scaduto"
    | request papers |
    request := ATUpdateRegistry current requestForToken: aToken.
    request ifNil: [ ^ nil ].
    
    papers := self papersForAuthorEmail: request email.
    ^ papers collect: [ :p |
        Dictionary new
            at: #slug put: p slug;
            at: #title put: p title;
            at: #track put: p track;
            at: #date put: p date asString;
            at: #withdrawn put: p isWithdrawn;
            yourself ]
]

{ #category : 'querying' }
ATRepository >> pendingSubmissions [
^ self submissions select: [ :s | s isPending ]
]

{ #category : 'as yet unclassified' }
ATRepository >> processUpdateRequest: anEmail [
    "Processa richiesta di update. Ritorna dizionario con risultato"
    | registry status request papers updateUrl |
    
    registry := ATUpdateRegistry current.
    status := registry rateLimitStatusForEmail: anEmail.
    
    "Verifica rate limit"
    (status at: #canRequest) ifFalse: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Too many requests. Please try again tomorrow.';
            yourself ].
    
    "Verifica se email ha paper"
    (self hasPublishedPapersForEmail: anEmail) ifFalse: [
        "Non rivelare se email esiste o no - messaggio generico"
        ^ Dictionary new
            at: #success put: true;
            at: #message put: 'If this email has published papers, you will receive a link shortly.';
            yourself ].
    
    "Crea richiesta"
    request := registry createRequestForEmail: anEmail.
    request ifNil: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Could not create request. Please try again.';
            yourself ].
    
    "Invia email"
    papers := self papersForAuthorEmail: anEmail.
    updateUrl := 'https://ai-theoretical.org/update.html?token=', request token.
    
    [ self sendUpdateEmail: anEmail token: request token papers: papers ]
        on: Error
        do: [ :e |
            Transcript show: 'Failed to send update email: ', e messageText; cr.
            ^ Dictionary new
                at: #success put: false;
                at: #error put: 'Failed to send email. Please try again.';
                yourself ].
    
    ^ Dictionary new
        at: #success put: true;
        at: #message put: 'If this email has published papers, you will receive a link shortly.';
        yourself
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
    | file |
    file := aFilePath asFileReference.
    file ensureDelete.
    file writeStreamDo: [ :stream |
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

{ #category : 'as yet unclassified' }
ATRepository >> sendUpdateEmail: anEmail token: aToken papers: papersList [
    "Invia email con link per gestire i paper"
    | subject body paperTitles |
    
    paperTitles := String streamContents: [ :s |
        papersList do: [ :p |
            s nextPutAll: '  • '; nextPutAll: p title; cr ] ].
    
    subject := 'AI-Theoretical: Manage Your Paper(s)'.
    
    body := 'Hello,

You requested to manage your paper(s) on AI-Theoretical.

Your published paper(s):
', paperTitles, '
Click the link below to manage your publication(s):

https://ai-theoretical.org/update.html?token=', aToken, '

This link is valid for 24 hours.

Available actions:
- Withdraw your paper
- Upload a new version
- Change the paper''s track/category

If you did not request this, you can safely ignore this email.

Best regards,
AI-Theoretical
https://ai-theoretical.org
'.
    
    ATEmailSender 
        sendTo: anEmail 
        subject: subject 
        body: body
]

{ #category : 'as yet unclassified' }
ATRepository >> setRateLimitConfig: aDict [
    "Configura rate limit via API"
    ^ self apiPost: '/rate-limit' data: aDict
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

{ #category : 'as yet unclassified' }
ATRepository >> updatePaperVersion: aSlug withToken: aToken newTrack: newTrackOrNil [
    "Prepara update di versione. Ritorna URL per upload PDF"
    | registry request paper newVersion uploadToken |
    
    registry := ATUpdateRegistry current.
    request := registry requestForToken: aToken.
    request ifNil: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Invalid or expired token'; yourself ].
    
    paper := self paperForSlug: aSlug.
    paper ifNil: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Paper not found'; yourself ].
    
    "Verifica che il paper appartenga a questa email"
    (paper authorEmail asLowercase = request email asLowercase) ifFalse: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Unauthorized'; yourself ].
    
    "Calcola nuova versione"
    newVersion := (paper version ifNil: [ 1 ]) + 1.
    
    "Genera token per upload"
    uploadToken := UUID new asString36.
    
    "Salva info per upload pendente"
    pendingVersionUpdates ifNil: [ pendingVersionUpdates := Dictionary new ].
    pendingVersionUpdates at: uploadToken put: (Dictionary new
        at: #slug put: aSlug;
        at: #email put: request email;
        at: #newVersion put: newVersion;
        at: #newTrack put: newTrackOrNil;
        at: #createdAt put: DateAndTime now;
        at: #expiresAt put: (DateAndTime now + 1 hour);
        yourself).
    
    ^ Dictionary new
        at: #success put: true;
        at: #uploadToken put: uploadToken;
        at: #currentVersion put: (paper version ifNil: [ 1 ]);
        at: #newVersion put: newVersion;
        at: #newTrack put: (newTrackOrNil ifNil: [ paper track ]);
        yourself
]

{ #category : 'api - submissions' }
ATRepository >> updateRemoteSubmissionStatus: submissionId to: newStatus [
"Aggiorna lo status di una submission su Cloudflare"
^ self apiPost: '/submission/', submissionId, '/status' data: { 'status' -> newStatus } asDictionary
]

{ #category : 'as yet unclassified' }
ATRepository >> validateUpdateToken: aToken [
    "Valida token e ritorna info sui paper. Ritorna dizionario"
    | registry request papers |
    
    registry := ATUpdateRegistry current.
    request := registry requestForToken: aToken.
    
    request ifNil: [
        ^ Dictionary new
            at: #valid put: false;
            at: #error put: 'Invalid or expired link. Please request a new one.';
            yourself ].
    
    papers := self papersForAuthorEmail: request email.
    
    ^ Dictionary new
        at: #valid put: true;
        at: #email put: request email;
        at: #expiresAt put: request expiresAt asString;
        at: #papers put: (papers collect: [ :p |
            Dictionary new
                at: #slug put: p slug;
                at: #title put: p title;
                at: #track put: p track;
                at: #date put: p date asString;
                at: #version put: (p version ifNil: [ 1 ]);
                yourself ]);
        yourself
]

{ #category : 'as yet unclassified' }
ATRepository >> withdrawPaper: aSlug withToken: aToken reason: aReason [
    "Ritira un paper. Verifica token prima"
    | registry request paper |
    
    registry := ATUpdateRegistry current.
    request := registry requestForToken: aToken.
    request ifNil: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Invalid or expired token'; yourself ].
    
    paper := self paperForSlug: aSlug.
    paper ifNil: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Paper not found'; yourself ].
    
    "Verifica che il paper appartenga a questa email"
    (paper authorEmail asLowercase = request email asLowercase) ifFalse: [
        ^ Dictionary new at: #success put: false; at: #error put: 'Unauthorized'; yourself ].
    
    "Ritira il paper"
    paper withdraw: (aReason ifEmpty: [ 'Withdrawn by author' ]).
    
    "Rigenera sito"
    self generateSite.
    self deploy.
    
    "Consuma token"
    registry consumeToken: aToken.
    
    "Log"
    Transcript show: 'Paper withdrawn: ', aSlug, ' by ', request email; cr.
    
    ^ Dictionary new
        at: #success put: true;
        at: #message put: 'Paper withdrawn successfully';
        yourself
]

{ #category : 'as yet unclassified' }
ATRepository >> withdrawPaperWithSlug: aSlug token: aToken [
    "Ritira un paper. Verifica che il token sia valido per questo paper."
    | request paper |
    
    request := ATUpdateRegistry current requestForToken: aToken.
    request ifNil: [ 
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Invalid or expired token.';
            yourself ].
    
    paper := self paperWithSlug: aSlug.
    paper ifNil: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Paper not found.';
            yourself ].
    
    "Verifica che il paper appartenga all''autore"
    paper authorEmail asLowercase = request email asLowercase ifFalse: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'You are not authorized to modify this paper.';
            yourself ].
    
    paper isWithdrawn ifTrue: [
        ^ Dictionary new
            at: #success put: false;
            at: #error put: 'Paper is already withdrawn.';
            yourself ].
    
    "Ritira il paper"
    paper withdraw.
    self savePapers.
    self regenerateAllPages.
    self deploy.
    
    ^ Dictionary new
        at: #success put: true;
        yourself
]
