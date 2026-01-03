Class {
	#name : 'ATManifestoPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATManifestoPage >> content [
	^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>Manifesto</h1>
    <hr>
</header>

<div class="section">
    <p>
        AI-Theoretical is a space for high-level theoretical writing developed through explicit collaboration
        between human authors and AI systems.
    </p>
</div>

<div class="section">
    <p>
        For us, collaboration refers to the joint participation of human and artificial agents in the
        generative phase of writing. AI systems are not confined to stylistic refinement or bibliographic
        assistance, but actively contribute by suggesting unconventional connections, alternative
        conceptual routes, and exploratory directions that may lie outside the author''s initial framing.
    </p>
</div>

<div class="section">
    <p>
        The text takes shape through an ongoing interaction. The human author retains full responsibility
        for the overall architecture, the substantive claims, and the interpretive decisions that give
        coherence to the work, while the AI operates as a generative and supporting interlocutor throughout
        the process.
    </p>
</div>

<div class="section">
    <p>
        In addition, the AI provides immediately accessible background knowledge and, within practical
        limits, support in assessing the correctness of specific claims. This form of assistance is
        effective insofar as the AI is used to navigate shared bodies of knowledge through appropriate
        disciplinary methods, rather than being treated as an epistemic authority.
    </p>
</div>

<div class="section">
    <p>
        What matters here is the capacity of a text to sustain conceptual scrutiny and to generate
        constraints that remain meaningful beyond a single theoretical idiom.
    </p>
</div>

', self footer, '

</div>'
]

{ #category : 'accessing' }
ATManifestoPage >> description [
	^ 'Our vision for human-AI symbiosis in theoretical research. Exploring transparent authorship and AI as an active cognitive partner in epistemology and science.'
]

{ #category : 'accessing' }
ATManifestoPage >> fileName [
	^ 'manifesto.html'
]

{ #category : 'generating' }
ATManifestoPage >> head [
	^ String streamContents: [ :s |
		s << '<head>'; << String lf.
		s << '    <meta charset="UTF-8">'; << String lf.
		s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
		s << '    <title>'; << self title; << '</title>'; << String lf.
		s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
		s << '    <meta property="og:title" content="'; << self title; << '">'; << String lf.
		s << '    <meta property="og:description" content="A new framework for human-AI co-authorship in theoretical disciplines.">'; << String lf.
		s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
		s << self fonts.
		s << '    <style>'; << String lf.
		s << self css.
		s << '    </style>'; << String lf.
		s << '</head>'; << String lf ]
]

{ #category : 'accessing' }
ATManifestoPage >> title [
	^ 'Manifesto — AI-Theoretical'
]
