Class {
	#name : 'ATRejectedRepository',
	#superclass : 'Object',
	#instVars : [
		'rejectedSubmissions',
		'filePath'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'accessing' }
ATRejectedRepository class >> current [ ^ current ifNil: [ current := self new initialize ]
]

{ #category : 'accessing' }
ATRejectedRepository class >> reset [ current := nil
]

{ #category : 'adding' }
ATRejectedRepository >> add: anATRejectedSubmission [
    rejectedSubmissions add: anATRejectedSubmission.
    self save
]

{ #category : 'pdf' }
ATRejectedRepository >> downloadPdf: submissionId [
    "Scarica PDF via API e lo salva in locale, ritorna il path"
    | pdfDir pdfPath pdfUrl client |
    submissionId ifNil: [ ^ nil ].
    
    pdfDir := '/Users/Franco/Dropbox/ai-theoretical.org/data/rejected-pdfs' asFileReference.
    pdfDir ensureCreateDirectory.
    
    pdfPath := pdfDir / (submissionId, '.pdf').
    
    pdfUrl := ATRepository current apiBaseUrl, '/submission/', submissionId, '/pdf'.
    
    client := ZnClient new.
    client url: pdfUrl.
    client headerAt: 'Authorization' put: 'Bearer ', ATRepository current apiToken.
    client beBinary.
    client timeout: 60.
    client get.
    
    client isSuccess ifFalse: [ ^ nil ].
    
    pdfPath binaryWriteStreamDo: [ :s | s nextPutAll: client contents ].
    
    ^ pdfPath fullName
]

{ #category : 'pdf' }
ATRejectedRepository >> downloadPdf: pdfKey forSubmission: submissionId [
    "Scarica PDF da R2 e lo salva in locale, ritorna il path"
    | pdfDir pdfPath response url |
    pdfKey ifNil: [ ^ nil ].
    pdfKey isEmpty ifTrue: [ ^ nil ].
    
    pdfDir := '/Users/Franco/Dropbox/ai-theoretical.org/data/rejected-pdfs' asFileReference.
    pdfDir ensureCreateDirectory.
    
    pdfPath := pdfDir / (submissionId, '.pdf').
    
    url := 'https://pub-a49307a12dc04cf9804bdc498dec138d.r2.dev/', pdfKey.
    
    response := ZnClient new
        url: url;
        timeout: 60;
        get;
        response.
    
    response isSuccess ifFalse: [ ^ nil ].
    
    pdfPath binaryWriteStreamDo: [ :s | s nextPutAll: response entity bytes ].
    
    ^ pdfPath fullName
]

{ #category : 'accessing' }
ATRejectedRepository >> filePath [ ^ filePath
]

{ #category : 'accessing' }
ATRejectedRepository >> filePath: aString [ filePath := aString
]

{ #category : 'initialization' }
ATRejectedRepository >> initialize [
    rejectedSubmissions := OrderedCollection new.
    filePath := '/Users/Franco/Dropbox/ai-theoretical.org/data/rejected.ston'
]

{ #category : 'persistence' }
ATRejectedRepository >> load [
    | file |
    file := filePath asFileReference.
    file exists ifFalse: [ ^ self ].
    rejectedSubmissions := file readStreamDo: [ :s | STON fromStream: s ]
]

{ #category : 'accessing' }
ATRejectedRepository >> rejectedSubmissions [ ^ rejectedSubmissions
]

{ #category : 'persistence' }
ATRejectedRepository >> save [
    filePath asFileReference parent ensureCreateDirectory.
    filePath asFileReference writeStreamDo: [ :s | 
        STON put: rejectedSubmissions onStream: s ]
]
