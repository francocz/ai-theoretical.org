Class {
	#name : 'ATEditorialPrinciplesPage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATEditorialPrinciplesPage >> content [
    ^ '<div class="container">

<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>Editorial Framework</h1>
    <hr>
</header>

<div class="section">
    <h2>Scope</h2>
    <p>
        AI-Theoretical hosts high-level theoretical preprints and working papers developed through
        explicit collaboration between human authors and AI systems. The platform is not a journal
        and does not operate as a peer-review venue.
    </p>
    <p>
        The aim is to provide an open space for structured theoretical work that is rigorous,
        conceptually explicit, and publicly accessible, whether or not it is intended for subsequent
        academic publication.
    </p>
</div>

<div class="section">
    <h2>Admissible domains</h2>
    <p>
        Contributions are restricted to academically grounded domains, including formal sciences,
        natural sciences, and philosophy pursued in an explicitly argumentative and conceptual manner.
        Work in economics, sociology, or political theory is admissible only when it adopts a clear
        theoretical framework and avoids purely rhetorical or ideological discourse.
    </p>
    <p>
        Texts relying primarily on impressionistic commentary, stylistic inflation, or intra-canonical
        self-legitimation fall outside the scope of the platform.
    </p>
</div>

<div class="section">
    <h2>Types of contributions</h2>
    <p>
        Accepted texts are classified into one of the following categories:
    </p>
    <p>
        <strong>Research preprints</strong>, presenting original theses, models, or results in provisional form;
        <br>
        <strong>Working papers</strong>, documenting ongoing research, methodological explorations, or preliminary findings not yet ready for formal publication;
        <br>
        <strong>Expository or theoretical essays</strong>, aimed at conceptual clarification, reconstruction, or critical synthesis;
        <br>
        <strong>Critical reviews</strong>, offering analytically grounded assessments of existing works or research programs.
    </p>
</div>

<div class="section">
    <h2>Editorial assessment</h2>
    <p>
        Each accepted text is accompanied by an AI-assisted editorial assessment. The assessment is
        produced using a fixed and publicly documented evaluation protocol and is published alongside
        the text.
    </p>
    <p>
        The assessment does not certify correctness, originality, or importance in an academic sense.
        Its function is to evaluate formal and conceptual adequacy relative to the text''s declared aims,
        including coherence, consistency, scholarly grounding, and cognitive traction beyond a single
        theoretical canon.
    </p>
</div>

<div class="section">
    <h2>Role of AI</h2>
    <p>
        AI systems are used as explicit cognitive instruments within the editorial process. They do not
        function as autonomous authors or authorities, but as constrained evaluative and generative tools.
    </p>
    <p>
        The use of AI is not concealed. Each text may include a separate note describing the nature and
        extent of AI involvement in its development.
    </p>
</div>

<div class="section">
    <h2>Responsibility</h2>
    <p>
        Final responsibility for inclusion on the platform remains human. In borderline cases, AI-generated
        assessments may be overridden or supplemented by human editorial judgment.
    </p>
</div>

', self footer, '

</div>'
]

{ #category : 'generating' }
ATEditorialPrinciplesPage >> css [
	^ super css, String lf, '
.section h2 {
    font-size: 0.85rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-bottom: 10px;
}

.section p {
    font-size: 0.95rem;
    margin-bottom: 14px;
    color: var(--text-main);
}'
]

{ #category : 'accessing' }
ATEditorialPrinciplesPage >> description [
	^ 'The protocol for AI-assisted editorial assessment. Learn about our criteria for theoretical adequacy, coherence, and scholarly grounding.'
]

{ #category : 'accessing' }
ATEditorialPrinciplesPage >> fileName [
	^ 'editorial-principles.html'
]

{ #category : 'generating' }
ATEditorialPrinciplesPage >> head [
    ^ String streamContents: [ :s |
        s << '<head>'; << String lf.
        s << '    <meta charset="UTF-8">'; << String lf.
        s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
        s << '    <link rel="icon" type="image/svg+xml" href="favicon.svg">'; << String lf.
        s << '    <title>'; << self title; << '</title>'; << String lf.
        s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
        s << '    <meta property="og:title" content="'; << self title; << '">'; << String lf.
        s << '    <meta property="og:description" content="How we evaluate human-AI co-authored papers.">'; << String lf.
        s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
        s << self fonts.
        s << '    <style>'; << String lf.
        s << self css.
        s << '    </style>'; << String lf.
        s << '</head>'; << String lf ]
]

{ #category : 'accessing' }
ATEditorialPrinciplesPage >> title [
	^ 'Editorial Framework — AI-Theoretical'
]
