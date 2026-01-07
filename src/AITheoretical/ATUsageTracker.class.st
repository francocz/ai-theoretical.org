Class {
	#name : 'ATUsageTracker',
	#superclass : 'Object',
	#instVars : [
		'globalUsage',
		'resettableUsage',
		'lastReset'
	],
	#classVars : [
		'Current'
	],
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'as yet unclassified' }
ATUsageTracker class >> current [
    ^ Current ifNil: [ Current := self new ]
]

{ #category : 'as yet unclassified' }
ATUsageTracker class >> reset [
    Current := nil
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> emptyProviderUsage [
    "Ritorna un dizionario vuoto per un provider"
    ^ Dictionary new
        at: #inputTokens put: 0;
        at: #outputTokens put: 0;
        at: #calls put: 0;
        yourself
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> estimatedCostFor: provider usage: usageDict [
    "Stima costo in USD basato su pricing approssimativo"
    | input output inputCost outputCost |
    input := usageDict at: #inputTokens ifAbsent: [ 0 ].
    output := usageDict at: #outputTokens ifAbsent: [ 0 ].
    
    "Pricing per milione di token (approssimativo)"
    provider = #anthropic ifTrue: [
        "Claude Sonnet 4.5: $3/M input, $15/M output"
        inputCost := input / 1000000.0 * 3.
        outputCost := output / 1000000.0 * 15 ].
    provider = #openai ifTrue: [
        "GPT-4o: $2.50/M input, $10/M output"
        inputCost := input / 1000000.0 * 2.5.
        outputCost := output / 1000000.0 * 10 ].
    provider = #google ifTrue: [
        "Gemini 2.5 Flash: $0.15/M input, $0.60/M output"
        inputCost := input / 1000000.0 * 0.15.
        outputCost := output / 1000000.0 * 0.60 ].
    
    inputCost ifNil: [ inputCost := 0 ].
    outputCost ifNil: [ outputCost := 0 ].
    ^ inputCost + outputCost
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> globalUsage [
    ^ globalUsage
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> initialize [
    super initialize.
    globalUsage := Dictionary new.
    resettableUsage := Dictionary new.
    lastReset := DateAndTime now
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> lastReset [
    ^ lastReset
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> recordUsageFor: provider inputTokens: input outputTokens: output [
    "Registra usage per un provider (es: #anthropic, #openai, #google)"
    | global resettable |
    
    "Global usage"
    global := globalUsage at: provider ifAbsentPut: [ self emptyProviderUsage ].
    global at: #inputTokens put: (global at: #inputTokens) + input.
    global at: #outputTokens put: (global at: #outputTokens) + output.
    global at: #calls put: (global at: #calls) + 1.
    
    "Resettable usage"
    resettable := resettableUsage at: provider ifAbsentPut: [ self emptyProviderUsage ].
    resettable at: #inputTokens put: (resettable at: #inputTokens) + input.
    resettable at: #outputTokens put: (resettable at: #outputTokens) + output.
    resettable at: #calls put: (resettable at: #calls) + 1
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> resetCounters [
    "Resetta i contatori resettabili, mantiene quelli globali"
    resettableUsage := Dictionary new.
    lastReset := DateAndTime now
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> resettableUsage [
    ^ resettableUsage
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> summary [
    "Ritorna un dizionario con tutto il summary"
    | result |
    result := Dictionary new.
    result at: #lastReset put: lastReset.
    result at: #global put: (self summaryFor: globalUsage).
    result at: #resettable put: (self summaryFor: resettableUsage).
    ^ result
]

{ #category : 'as yet unclassified' }
ATUsageTracker >> summaryFor: usageDict [
    "Crea summary per un tipo di usage"
    | summary totalInput totalOutput totalCost totalCalls |
    summary := Dictionary new.
    totalInput := 0.
    totalOutput := 0.
    totalCost := 0.
    totalCalls := 0.
    
    usageDict keysAndValuesDo: [ :provider :usage |
        | cost |
        cost := self estimatedCostFor: provider usage: usage.
        summary at: provider put: (Dictionary new
            at: #inputTokens put: (usage at: #inputTokens);
            at: #outputTokens put: (usage at: #outputTokens);
            at: #calls put: (usage at: #calls);
            at: #estimatedCost put: cost;
            yourself).
        totalInput := totalInput + (usage at: #inputTokens).
        totalOutput := totalOutput + (usage at: #outputTokens).
        totalCost := totalCost + cost.
        totalCalls := totalCalls + (usage at: #calls) ].
    
    summary at: #totals put: (Dictionary new
        at: #inputTokens put: totalInput;
        at: #outputTokens put: totalOutput;
        at: #calls put: totalCalls;
        at: #estimatedCost put: totalCost;
        yourself).
    ^ summary
]
