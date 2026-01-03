Class {
	#name : 'ATInvitePage',
	#superclass : 'ATStaticPage',
	#category : 'AITheoretical',
	#package : 'AITheoretical'
}

{ #category : 'generating' }
ATInvitePage >> content [
	^ '<div class="container">
<header>
    <a href="index.html" class="nav">← Back</a>
    <h1>Invitation to Participate</h1>
    <hr>
</header>
<div class="section">
    <p>
        AI-Theoretical invites researchers and scholars interested in using AI as an active partner
        in theoretical work to participate in the project.
    </p>
</div>
<div class="section">
    <p>
        The platform hosts high-level preprints or working papers developed in explicit collaboration
        with AI systems. Contributions may come from different fields, including the sciences,
        mathematics, philosophy, and other domains where theoretical reasoning plays a central role.
    </p>
</div>
<div class="section">
    <p>
        Texts that fit the scope of the platform may subsequently undergo an
        AI-performed editorial assessment, carried out in accordance with the
        provisions outlined in the AI editorial prompt and published alongside the paper.
    </p>
</div>
<div class="section">
    <p>
        If you are interested in contributing or in discussing a possible collaboration,
        you are invited to get in touch.
    </p>
</div>
<div class="section">
    <p>
        Contact: <a href="mailto:franco.cazzaniga@uninsubria.it">franco.cazzaniga@uninsubria.it</a>
    </p>
</div>
', self footer, '
</div>'
]

{ #category : 'accessing' }
ATInvitePage >> description [
	^ 'Join the AI-Theoretical project. We invite researchers interested in exploring human-AI co-authorship in philosophy, science, and mathematics.'
]

{ #category : 'accessing' }
ATInvitePage >> fileName [
	^ 'invite.html'
]

{ #category : 'generating' }
ATInvitePage >> head [
	^ String streamContents: [ :s |
		s << '<head>'; << String lf.
		s << '    <meta charset="UTF-8">'; << String lf.
		s << '    <meta name="viewport" content="width=device-width, initial-scale=1.0">'; << String lf.
		s << '    <title>'; << self title; << '</title>'; << String lf.
		s << '    <meta name="description" content="'; << self description; << '">'; << String lf.
		s << '    <meta property="og:title" content="Join AI-Theoretical">'; << String lf.
		s << '    <meta property="og:description" content="Call for contributions: human-AI symbiotic theoretical works.">'; << String lf.
		s << '    <meta property="og:image" content="https://ai-theoretical.org/og-image.jpg">'; << String lf.
		s << self fonts.
		s << '    <style>'; << String lf.
		s << self css.
		s << '    </style>'; << String lf.
		s << '</head>'; << String lf ]
]

{ #category : 'accessing' }
ATInvitePage >> title [
	^ 'Invitation to Participate — AI-Theoretical'
]
