Class {
	#name : 'ATHtmlPage',
	#superclass : 'Object',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATHtmlPage class >> generateAllTo: aPath [
    "Genera tutte le pagine HTML delle sottoclassi"
    | generated |
    generated := OrderedCollection new.
    self allSubclasses do: [ :pageClass |
        pageClass isAbstract ifFalse: [
            generated add: (pageClass new saveTo: aPath) ] ].
    ^ generated
]

{ #category : 'as yet unclassified' }
ATHtmlPage class >> isAbstract [
    "La classe base e ATStaticPage sono astratte"
    ^ self = ATHtmlPage or: [ self = ATStaticPage ]
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> commonStyles [
    "CSS comuni a tutte le pagine"
    ^ '<style>
body { font-family: system-ui, -apple-system, sans-serif; margin: 0; padding: 20px; background: #fafafa; }
.container { max-width: 900px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
h1 { color: #333; margin-bottom: 20px; }
h2 { color: #555; margin-top: 30px; }
p { line-height: 1.6; color: #444; }
a { color: #2196F3; text-decoration: none; }
a:hover { text-decoration: underline; }
nav { margin-bottom: 30px; }
.intro { font-size: 1.1em; color: #666; margin-bottom: 30px; }
.track-card { background: #f8f9fa; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 4px solid #2196F3; }
.track-card h3 { margin-top: 0; color: #333; }
</style>'
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> fileName [
    "Subclass responsibility - ritorna il nome del file, es. 'submit.html'"
    self subclassResponsibility
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> generate [
    "Subclass responsibility - ritorna l'HTML come stringa"
    self subclassResponsibility
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> htmlFooter [
    "Footer HTML standard"
    ^ '</div></body></html>'
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> htmlHead: aTitle [
    "Genera l''head HTML standard con favicon"
    ^ String streamContents: [ :s |
        s nextPutAll: '<!DOCTYPE html><html lang="en"><head>'.
        s nextPutAll: '<meta charset="UTF-8">'.
        s nextPutAll: '<meta name="viewport" content="width=device-width, initial-scale=1.0">'.
        s nextPutAll: '<link rel="icon" type="image/svg+xml" href="favicon.svg">'.
        s nextPutAll: '<title>'; nextPutAll: aTitle; nextPutAll: ' - AI-Theoretical</title>'.
        s nextPutAll: self commonStyles.
        s nextPutAll: '</head>' ]
]

{ #category : 'as yet unclassified' }
ATHtmlPage >> saveTo: aDirectoryPath [
    "Salva la pagina, troncando prima il file esistente"
    | file |
    file := aDirectoryPath asFileReference / self fileName.
    file ensureDelete.
    file writeStreamDo: [ :stream |
        stream nextPutAll: self generate ].
    ^ file
]
