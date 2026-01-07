Class {
	#name : 'ATUsageTrackerTest',
	#superclass : 'ATTestCase',
	#category : 'AITheoretical-Tests',
	#package : 'AITheoretical-Tests'
}

{ #category : 'tests' }
ATUsageTrackerTest >> testMultipleProviders [
    | tracker |
    tracker := ATUsageTracker new.
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    tracker recordUsageFor: #google inputTokens: 2000 outputTokens: 1000.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 1000.
    self assert: ((tracker globalUsage at: #google) at: #inputTokens) equals: 2000.
    self assert: tracker globalUsage size equals: 2.
]

{ #category : 'tests' }
ATUsageTrackerTest >> testRecordMultipleUsages [
    | tracker |
    tracker := ATUsageTracker new.
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    tracker recordUsageFor: #anthropic inputTokens: 2000 outputTokens: 1000.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 3000.
    self assert: ((tracker globalUsage at: #anthropic) at: #outputTokens) equals: 1500.
    self assert: ((tracker globalUsage at: #anthropic) at: #calls) equals: 2.
]

{ #category : 'tests' }
ATUsageTrackerTest >> testRecordUsage [
    | tracker |
    tracker := ATUsageTracker new.
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 1000.
    self assert: ((tracker globalUsage at: #anthropic) at: #outputTokens) equals: 500.
    self assert: ((tracker globalUsage at: #anthropic) at: #calls) equals: 1.
]

{ #category : 'tests' }
ATUsageTrackerTest >> testRecordUsageFor [
    | tracker |
    tracker := ATUsageTracker new.
    tracker initialize.
    
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 1000.
    self assert: ((tracker globalUsage at: #anthropic) at: #outputTokens) equals: 500.
    self assert: ((tracker globalUsage at: #anthropic) at: #calls) equals: 1
]

{ #category : 'tests' }
ATUsageTrackerTest >> testRecordUsageForCumulative [
    | tracker |
    tracker := ATUsageTracker new.
    tracker initialize.
    
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    tracker recordUsageFor: #anthropic inputTokens: 500 outputTokens: 250.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 1500.
    self assert: ((tracker globalUsage at: #anthropic) at: #outputTokens) equals: 750.
    self assert: ((tracker globalUsage at: #anthropic) at: #calls) equals: 2
]

{ #category : 'tests' }
ATUsageTrackerTest >> testRecordUsageForMultipleProviders [
    | tracker |
    tracker := ATUsageTracker new.
    tracker initialize.
    
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    tracker recordUsageFor: #google inputTokens: 2000 outputTokens: 1000.
    
    self assert: ((tracker globalUsage at: #anthropic) at: #inputTokens) equals: 1000.
    self assert: ((tracker globalUsage at: #google) at: #inputTokens) equals: 2000
]

{ #category : 'tests' }
ATUsageTrackerTest >> testResetCounters [
    | tracker |
    tracker := ATUsageTracker new.
    tracker recordUsageFor: #anthropic inputTokens: 1000 outputTokens: 500.
    tracker resetCounters.
    
    self assert: tracker resettableUsage isEmpty.
]
