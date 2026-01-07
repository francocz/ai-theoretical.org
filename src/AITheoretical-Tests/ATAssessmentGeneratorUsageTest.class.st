Class {
	#name : 'ATAssessmentGeneratorUsageTest',
	#superclass : 'ATTestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromAnthropicResponse [
    "Test che extractUsageFrom: restituisce chiavi stringa con underscore"
    | gen responseDict usage |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    responseDict := Dictionary new
        at: 'usage' put: (Dictionary new
            at: 'input_tokens' put: 1000;
            at: 'output_tokens' put: 500;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: responseDict.
    
    "Le chiavi devono essere stringhe con underscore"
    self assert: (usage at: 'input_tokens') equals: 1000.
    self assert: (usage at: 'output_tokens') equals: 500
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromAnthropicReturnsStringKeys [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    "Simula risposta Anthropic"
    response := Dictionary new.
    response at: 'usage' put: (Dictionary new
        at: 'input_tokens' put: 1000;
        at: 'output_tokens' put: 500;
        yourself).
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 1000.
    self assert: (usage at: 'output_tokens') equals: 500.
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromGoogleResponse [
    "Test estrazione usage da risposta Google"
    | gen responseDict usage |
    gen := ATAssessmentGenerator new.
    gen provider: #google.
    
    responseDict := Dictionary new
        at: 'usageMetadata' put: (Dictionary new
            at: 'promptTokenCount' put: 2000;
            at: 'candidatesTokenCount' put: 800;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: responseDict.
    
    self assert: (usage at: 'input_tokens') equals: 2000.
    self assert: (usage at: 'output_tokens') equals: 800
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromGoogleReturnsStringKeys [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #google.
    
    "Simula risposta Google"
    response := Dictionary new.
    response at: 'usageMetadata' put: (Dictionary new
        at: 'promptTokenCount' put: 2000;
        at: 'candidatesTokenCount' put: 800;
        yourself).
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 2000.
    self assert: (usage at: 'output_tokens') equals: 800.
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromOpenAIResponse [
    "Test estrazione usage da risposta OpenAI"
    | gen responseDict usage |
    gen := ATAssessmentGenerator new.
    gen provider: #openai.
    
    responseDict := Dictionary new
        at: 'usage' put: (Dictionary new
            at: 'prompt_tokens' put: 1500;
            at: 'completion_tokens' put: 600;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: responseDict.
    
    self assert: (usage at: 'input_tokens') equals: 1500.
    self assert: (usage at: 'output_tokens') equals: 600
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testExtractUsageFromOpenAIReturnsStringKeys [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #openai.
    
    "Simula risposta OpenAI"
    response := Dictionary new.
    response at: 'usage' put: (Dictionary new
        at: 'prompt_tokens' put: 1500;
        at: 'completion_tokens' put: 600;
        yourself).
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 1500.
    self assert: (usage at: 'output_tokens') equals: 600.
]

{ #category : 'tests' }
ATAssessmentGeneratorUsageTest >> testUsageKeyFormat [
    "Verifica che le chiavi nel dizionario usage siano stringhe con underscore"
    | gen responseDict usage |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    responseDict := Dictionary new
        at: 'usage' put: (Dictionary new
            at: 'input_tokens' put: 100;
            at: 'output_tokens' put: 50;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: responseDict.
    
    "Deve contenere chiavi stringa, non simboli"
    self assert: (usage includesKey: 'input_tokens').
    self assert: (usage includesKey: 'output_tokens').
    self deny: (usage includesKey: #inputTokens).
    self deny: (usage includesKey: #outputTokens)
]
