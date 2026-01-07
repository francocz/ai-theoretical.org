Class {
	#name : 'ATAssessmentGeneratorTest',
	#superclass : 'TestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests - cost estimation' }
ATAssessmentGeneratorTest >> testEstimateCostForAnthropic [
    | gen usage cost |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    "1 milione di input tokens = $3, 1 milione output = $15"
    usage := Dictionary new
        at: 'input_tokens' put: 1000000;
        at: 'output_tokens' put: 1000000;
        yourself.
    
    cost := gen estimateCostFor: usage.
    
    "Cost should be $3 + $15 = $18"
    self assert: cost equals: 18
]

{ #category : 'tests - cost estimation' }
ATAssessmentGeneratorTest >> testEstimateCostForNilUsage [
    | gen cost |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    cost := gen estimateCostFor: nil.
    
    self assert: cost equals: 0
]

{ #category : 'tests - usage extraction' }
ATAssessmentGeneratorTest >> testExtractUsageFromAnthropic [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #anthropic.
    
    response := Dictionary new
        at: 'usage' put: (Dictionary new
            at: 'input_tokens' put: 1500;
            at: 'output_tokens' put: 800;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 1500.
    self assert: (usage at: 'output_tokens') equals: 800
]

{ #category : 'tests - usage extraction' }
ATAssessmentGeneratorTest >> testExtractUsageFromGoogle [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #google.
    
    response := Dictionary new
        at: 'usageMetadata' put: (Dictionary new
            at: 'promptTokenCount' put: 2000;
            at: 'candidatesTokenCount' put: 500;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 2000.
    self assert: (usage at: 'output_tokens') equals: 500
]

{ #category : 'tests - usage extraction' }
ATAssessmentGeneratorTest >> testExtractUsageFromOpenAI [
    | gen response usage |
    gen := ATAssessmentGenerator new.
    gen provider: #openai.
    
    response := Dictionary new
        at: 'usage' put: (Dictionary new
            at: 'prompt_tokens' put: 1800;
            at: 'completion_tokens' put: 600;
            yourself);
        yourself.
    
    usage := gen extractUsageFrom: response.
    
    self assert: (usage at: 'input_tokens') equals: 1800.
    self assert: (usage at: 'output_tokens') equals: 600
]
