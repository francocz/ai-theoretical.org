Class {
	#name : 'ATStaticPage',
	#superclass : 'Object',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATStaticPage >> content [
	self subclassResponsibility
]

{ #category : 'generating' }
ATStaticPage >> css [
	^ ATStyles baseCss
]

{ #category : 'accessing' }
ATStaticPage >> description [
	self subclassResponsibility
]

{ #category : 'accessing' }
ATStaticPage >> fileName [
	self subclassResponsibility
]

{ #category : 'generating' }
ATStaticPage >> fonts [
	^ '    <link href="https://fonts.googleapis.com/css2?family=Inter:ital,wght@0,300;0,400;0,600;1,300&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">', String lf
]

{ #category : 'generating' }
ATStaticPage >> footer [
	^ '<footer>
    <p class="powered-by">Powered by <a href="https://www.anthropic.com/claude" target="_blank">Claude AI</a> and <a href="https://pharo.org" target="_blank">Pharo Smalltalk</a></p>
</footer>'
]

{ #category : 'generating' }
ATStaticPage >> generate [
	^ String streamContents: [ :s |
		s << '<!DOCTYPE html>'; << String lf.
		s << '<html lang="en">'; << String lf.
		s << self head.
		s << '<body>'; << String lf.
		s << self content.
		s << '</body>'; << String lf.
		s << '</html>' ]
]

{ #category : 'generating' }
ATStaticPage >> head [
	^ String streamContents: [ :s |
		s << '<head>'; << String lf.
		s << '    <meta charset="UTF-8">'; << String lf.
		s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
		s << '    <title>'; << self title; << '</title>'; << String lf.
		s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
		s << '    <meta property="og:title" content="'; << self title; << '">'; << String lf.
		s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
		s << self fonts.
		s << '    <style>'; << String lf.
		s << self css.
		s << '    </style>'; << String lf.
		s << '</head>'; << String lf ]
]

{ #category : 'saving' }
ATStaticPage >> saveTo: aDirectoryPath [
	| file |
	file := aDirectoryPath asFileReference / self fileName.
	file writeStreamDo: [ :stream |
		stream nextPutAll: self generate ].
	^ file
]

{ #category : 'accessing' }
ATStaticPage >> title [
	self subclassResponsibility
]
