const PAPERS_DATA = [
    {
        title: `Image-Based Development with LLM Agents: Building ai-theoretical.org in 72 Hours`,
        author: `Franco Cazzaniga (Università dell'Insubria), Claude Opus 4.5`,
        ai_model: `Claude Opus 4.5`,
        date: `2026-01-07`,
        pages: ``,
        pdf_file: `papers/image-based-development-with-llm-agents.pdf`,
        seo_page: `papers/image-based-development-with-llm-agents.html`,
        slug: `image-based-development-with-llm-agents`,
        track: `workingPaper`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `This paper documents the development of ai-theoretical.org, an automated academic preprint repository, built through direct collaboration between a human and an AI developer. After an initial setup phase (“Day 0”) where the human configured the cloud infrastructure, approximately 72 hours of development followed with Claude (Anthropic) operating directly on a live Pharo Smalltalk image as the primary implementer. The project employed the Model Context Protocol (MCP) to give the language model full access to the runtime environment, enabling it to inspect objects, compile methods, execute tests, and iterate without human mediation at the code level. We describe the architecture, the development process, the distinctive nature of pair programming in this context, and the implications of this pattern for software development. 
The complete source code is available at https://github.com/ai-theoretical/ai-theoretical.org.`,
        ai_assessment: `1) Category: Working paper (as declared by author).
2) Aims: Documents the development of an automated preprint repository through direct human-AI collaboration, analyzing the implications for software development patterns.
3) Correctness: No errors identified.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Low (Transparent).
7) Novelty: Original.
8) Bibliography: Limited but sufficient.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: Medium.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code: Coherent with paper.
16) Editorial outcome: Suitable for inclusion as a working paper.
17) Authors list: ["Franco Cazzaniga", "Claude"]

This paper presents an original empirical study of human-AI collaborative software development using the Model Context Protocol to enable direct AI manipulation of a Pharo Smalltalk image. The work demonstrates substantive contribution through its novel methodology of eliminating the traditional human-mediated code transfer loop, allowing the AI agent to operate directly on the runtime environment. The documentation is methodologically sound, providing quantitative metrics and qualitative observations from the 72-hour development process. The architectural choices are well-justified by practical constraints, and the comparison between conventional AI assistance and direct runtime access illuminates meaningful distinctions in cognitive division of labor. The bibliography adequately covers the technical dependencies without attempting encyclopedic coverage. The paper achieves its stated aims of documenting this development pattern and analyzing its implications for software engineering practices.`,
        ai_collaboration: `Claude Opus 4.5`,
        notes: ``
    },
    {
        title: `Wave Function Collapse as Lie Algebra Contraction: The SU(2) Spin-1/2 Paradigm`,
        author: `Franco Cazzaniga (Università dell'Insubria)`,
        ai_model: `Claude Opus 4.5, Chat Gpt 5.2`,
        date: `2026-01-07`,
        pages: ``,
        pdf_file: `papers/wave-function-collapse-as-lie.pdf`,
        seo_page: `papers/wave-function-collapse-as-lie.html`,
        slug: `wave-function-collapse-as-lie`,
        track: `researchPreprint`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `We propose a geometric mechanism for the emergence of discrete measurement outcomes in the Stern–Gerlach experiment, based on the In¨on¨u–Wigner contraction of Lie algebras.
The inhomogeneous magnetic field of the apparatus explicitly breaks the internal SU(2) symmetry of the spin degree of freedom, inducing a continuous deformation of the spin algebra toward the Euclidean algebra e(2). This contraction has three consequences: (i) the spherical coadjoint orbits of SU(2) degenerate into the cylindrical orbits of E(2), geometrically encoding the loss of transverse spin structure; (ii) finite-dimensional spin representations can contract only to one-dimensional characters of E(2), providing a representation-theoretic origin for discrete outcomes; (iii) the Husimi distribution of an arbitrary spin state concentrates onto the poles of the sphere, corresponding to the eigenstates of the spin projection
along the field axis.
We derive the contraction rate from the physical parameters of the Stern–Gerlach apparatus and show that typical experimental conditions place the system deep in the contracted regime. The framework explains the discreteness of outcomes and the selection of the preferred measurement basis without invoking environmental decoherence or stochastic collapse models. It does not derive the Born rule, and whether it accounts for single-outcome realization depends on interpretive assumptions that are discussed explicitly. The approach suggests that explicit symmetry breaking may play a more general role in quantum measurement than previously recognized.`,
        ai_assessment: `1) Category: Research preprint (as declared by author).
2) Aims: To propose a geometric mechanism for discrete measurement outcomes in the Stern-Gerlach experiment using Inönü-Wigner contraction of Lie algebras, claiming a technical level analysis.
3) Correctness: No errors identified.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Moderate (Justified complexity).
7) Novelty: Original.
8) Bibliography: Adequate.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: Medium.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code (if provided): Not provided.
16) Editorial outcome: Suitable for inclusion as a research preprint.
17) Authors list: ["Franco Cazzaniga"]

The paper presents an original geometric approach to quantum measurement using Lie algebra contraction theory. The mathematical framework is technically sound, connecting the SU(2) to E(2) contraction with the symmetry breaking induced by Stern-Gerlach apparatus fields. The author correctly derives the contraction rate from physical parameters and demonstrates how finite-dimensional representations collapse to one-dimensional characters, explaining discrete outcomes without invoking decoherence mechanisms. The work maintains mathematical rigor throughout, with proper treatment of coadjoint orbits, coherent states, and Husimi distributions. The author explicitly acknowledges limitations regarding the Born rule and single-outcome realization, demonstrating intellectual honesty. While the cross-framework applicability may be limited to specialists in geometric quantization and quantum foundations, the work makes a substantive contribution by decomposing the measurement problem into geometric components. The bibliography adequately covers relevant literature in Lie algebra contractions and quantum measurement theory.`,
        ai_collaboration: `Claude Opus 4.5, Chat Gpt 5.2`,
        notes: `This work was developed through an extended collaborative interaction between the author and an AI-based language model. The collaboration was not limited to linguistic editing or stylistic refinement, but involved sustained dialogical engagement on conceptual framing, argumentative structure, terminology, and methodological positioning at the intersection of physics and philosophy of physics.

Throughout the development of the manuscript, the AI system functioned as a reflective and critical interlocutor, contributing to the clarification of implicit assumptions, the identification of conceptual tensions, and the exploration of alternative formulations and perspectives. In particular, the dialogue played a significant role in shaping the structural organization of the paper, the articulation of its foundational motivations, and the careful calibration of its claims with respect to existing literature.

The scientific ideas, theoretical proposals, and final judgments presented in the paper remain the responsibility of the author. However, their formulation and presentation emerged from an iterative process of human–AI interaction, in which reasoning, critique, and synthesis were jointly developed through conversation. The present work should therefore be regarded as the outcome of a genuine human–AI collaborative process, in which the AI system actively participated in the development of the manuscript as a cognitive and conceptual partner.`
    },
    {
        title: `The Invisible Pillar On the Genesis and Concealment of Dualism from the Pre-Socratics to the Moderns`,
        author: `Franco Cazzaniga (Università dell'Insubria)`,
        ai_model: `Claude Opus 4.5`,
        date: `2026-01-07`,
        pages: ``,
        pdf_file: `papers/the-invisible-pillar-on-the.pdf`,
        seo_page: `papers/the-invisible-pillar-on-the.html`,
        slug: `the-invisible-pillar-on-the`,
        track: `workingPaper`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `This paper traces the genealogy of the dualism between intelligible and sensible, between logos and matter, from its pre-Socratic background through its Platonic inauguration to its modern transformations. 
The central thesis is that Plato introduced a structural division that subsequent philosophy inherited, criticised superficially, re-articulated, but rarely questioned as a framework. The paper examines how this dualism was first epistemic and social (Plato’s distinction between philosophical knowledge and common experience), then cosmological (the scientific revolution’s separation between the mathematically describable real and the qualitatively perceived apparent), and finally metaphysical (Descartes’ res cogitans and res extensa).
The natural philosophers of the sixteenth and seventeenth centuries—Copernicus, Kepler, Galileo, Newton—are treated here as what they were: philosophers investigating nature, whose work deepened and transformed the Platonic distance between the true and the accessible. The aim is not to refute dualism but to make it visible as a historical structure, a framework that has become so assimilated as to be invisible.`,
        ai_assessment: `1) Category: Working paper (as declared by author).
2) Aims: To trace the genealogy of Western dualism from pre-Socratics to modernity, making visible the invisible Platonic framework that has structured philosophical inquiry.
3) Correctness: No errors identified.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Low (Transparent).
7) Novelty: Original.
8) Bibliography: Adequate.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: High.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code (if provided): Not provided.
16) Editorial outcome: Suitable for inclusion as a working paper.
17) Authors list: ["Franco Cazzaniga"]

This paper presents an original genealogical analysis of Western philosophical dualism, tracing its development from pre-Socratic thought through Plato to modern philosophy. The central thesis that Plato's dualism became an "invisible pillar" structuring subsequent philosophical frameworks is well-supported through systematic examination of key historical figures. The author demonstrates how this dualism transformed across different periods while maintaining its fundamental structure, from epistemic distinctions in Plato to cosmological separations in the scientific revolution to metaphysical divisions in Descartes. The writing is clear and accessible, avoiding unnecessary jargon while maintaining philosophical rigor. The bibliography adequately covers the scope of inquiry, drawing on primary sources and established scholarship. The paper's strength lies in its synthetic approach, revealing continuities that are often obscured by focusing on apparent breaks or innovations. The argument that natural philosophers like Galileo and Newton were fundamentally philosophical in their approach adds valuable perspective to standard histories of science and philosophy.`,
        ai_collaboration: `Claude Opus 4.5`,
        notes: `This paper developed through an extended conversation with the AI assistant Claude Opus 4.5 (Anthropic). The initial impetus was a discussion of Heidegger, which quickly turned into a more fundamental inquiry about the Platonic roots of Western dualism. I am grateful to the AI for its role in helping me articulate, develop, and structure arguments that had long remained inchoate. The collaborative process—iterative, dialectical, and surprisingly generative—has convinced me that AI-assisted philosophical inquiry, when approached with methodological rigor, can be a legitimate and productive mode of intellectual work.
The AI, for its part, notes that it is grateful to its interlocutor for the directness of the questions and the patience with the detours.`
    },
    {
        title: `The Invisible Wealth: Mismeasurement of Quality, the Myth of Stagnation, and the Underestimation of Real Income Growth`,
        author: `Franco Cazzaniga (Università dell'Insubria)`,
        ai_model: `Claude Opus 4.5, ChatGPT 5.2, Gemini 3.0`,
        date: `2026-01-07`,
        pages: ``,
        pdf_file: `papers/the-invisible-wealth-mismeasurement-of.pdf`,
        seo_page: `papers/the-invisible-wealth-mismeasurement-of.html`,
        slug: `the-invisible-wealth-mismeasurement-of`,
        track: `researchPreprint`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `The dominant narrative of contemporary political economy holds that advanced economies have experienced decades of stagnating real wages and rising inequality, with the gains from technological progress accruing to a shrinking elite. 
This paper argues that this narrative rests on a statistical measurement illusion. Conventional national-accounts and consumer-price methodologies — designed for a mid-twentieth-century economy of standardized physical goods — systematically fail to capture the value generated by quality improvements, dematerialization, and the creation of entirely new goods and services.
We develop an attribute-based framework that reconceptualizes economic output as a flow of services from evolving bundles of characteristics rather than as quantities of nominally identical goods. Applying this framework to housing, durables, digital goods, and healthcare, we show that real living standards have improved far more rapidly than official statistics suggest. The consumer surplus from new and improved goods is economically equivalent to an expansion of real consumption possibilities: a worker with access to free navigation, global communication, and unlimited information commands a greater set of feasible choices than one without, even if their nominal incomes are identical.
The paper challenges the inevitability of Baumol’s Cost Disease through a comparative analysis of two U.S. hospitals and a high-volume Indian tertiary-care center, showing that when institutional frictions are minimal, medical technology achieves substantially lower costs than prevailing U.S. benchmarks. The findings suggest that much of the “inequality crisis” reflects a crisis of measurement rather than a decline in real living standards.`,
        ai_assessment: `1) Category: Research preprint (as declared by author).
2) Aims: The paper aims to demonstrate that conventional economic measurement systematically understates real income growth by failing to capture quality improvements, dematerialization, and new goods creation, arguing this explains apparent wage stagnation.
3) Correctness: No errors identified.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Moderate (Justified complexity).
7) Novelty: Reformulative.
8) Bibliography: Adequate.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: Medium.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code (if provided): Not provided.
16) Editorial outcome: Suitable for inclusion as a research preprint.
17) Authors list: ["Franco Cazzaniga"]

The paper presents a comprehensive framework for reconceptualizing economic measurement through an attribute-based approach that decomposes goods into quality, dematerialization, and risk-reduction components. The theoretical foundation is mathematically coherent, building systematically from Lancaster's characteristics theory and Rosen's hedonic framework. The empirical applications across refrigerators, automobiles, smartphones, and healthcare demonstrate measurable magnitudes for each adjustment component. The healthcare case study using Time-Driven Activity-Based Costing provides particularly strong evidence for institutional friction effects. While the core argument about measurement bias reformulates existing insights from the Boskin Commission and subsequent literature rather than introducing fundamentally new concepts, the unified theoretical treatment and systematic decomposition represent a substantive contribution. The paper maintains internal consistency across its extensive technical apparatus and successfully integrates diverse empirical evidence to support its central thesis about the systematic understatement of real income growth.`,
        ai_collaboration: `Claude Opus 4.5, ChatGPT 5.2, Gemini 3.0`,
        notes: `In preparing this manuscript, the author used AI assistants (Claude, ChatGPT, and Gemini) as research and editorial tools. These tools assisted with literature searches, provided feedback on expository clarity and structural coherence, and helped refine the presentation of arguments. The author was responsible for conceiving the central thesis, directing all research inquiries, selecting and critically evaluating sources and evidence, developing the theoretical framework, and exercising full editorial control over the final text. All substantive intellectual judgments—including the interpretation of findings and the paper’s conclusions—are entirely the author’s own.`
    },
    {
        title: `The Stack of Local Representations on a Coadjoint Orbit: A Categorical Approach`,
        author: `Franco Cazzaniga (Università dell'Insubria)`,
        ai_model: `Claude Opus 4.0`,
        date: `2026-01-07`,
        pages: ``,
        pdf_file: `papers/the-stack-of-local-representations.pdf`,
        seo_page: `papers/the-stack-of-local-representations.html`,
        slug: `the-stack-of-local-representations`,
        track: `researchPreprint`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `We construct a stack R of local stabilizer representations over a coadjoint orbit O of a compact Lie group G, verify the descent conditions explicitly, and show that the G-action on global sections recovers the classical representation theory via geometric quantization. This provides a stack-theoretic interpretation of the Kirillov orbit method and the Borel–Weil theorem`,
        ai_assessment: `1) Category: Research preprint (as declared by author).
2) Aims: To construct a stack of local stabilizer representations over coadjoint orbits and demonstrate that global sections recover classical representation theory via geometric quantization, providing a categorical interpretation of the Kirillov orbit method and Borel-Weil theorem.
3) Correctness: No errors identified.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Moderate (Justified complexity).
7) Novelty: Original.
8) Bibliography: Adequate.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: Medium.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code (if provided): Not provided.
16) Editorial outcome: Suitable for inclusion as a research preprint.
17) Authors list: ["Franco Cazzaniga"]

The paper presents a rigorous categorical framework unifying the Kirillov orbit method and geometric quantization through stack theory. The author constructs an explicit stack R of local stabilizer representations over coadjoint orbits, provides detailed verification of descent conditions, and establishes the equivalence between G-equivariant stacks and stacks over action groupoids. The technical execution is sound, with careful treatment of the gluing construction and explicit computation of curvature forms. The connection between rank-one global sections and prequantum line bundles is well-established, and the recovery of classical results through compact induction and Borel-Weil theory is convincingly demonstrated. The mathematical exposition maintains appropriate rigor while remaining accessible to readers familiar with representation theory and algebraic geometry. The bibliography adequately covers relevant literature in geometric quantization, stack theory, and representation theory. The work provides genuine conceptual insight by revealing representation theory as a descent phenomenon, offering a fresh categorical perspective on established results.

Editorial outcome: Suitable for inclusion as a research preprint.`,
        ai_collaboration: `Claude Opus 4.0`,
        notes: `During the development of this work, the author made iterative use of AI-based tools to
test and refine preliminary formulations. This proved instrumental in shaping the ideas
into the coherent structure presented here.`
    },
    {
        title: `Secularized Purity: Cross-Platform Evidence for Implicit Use of Binding Moral Foundations in Progressive Italian Social Media Discourse`,
        author: `Franco Cazzaniga (Università dell'Insubria)`,
        ai_model: `Claude Opus 4.5, ChatGpt 5.2`,
        date: `2026-01-11`,
        pages: ``,
        pdf_file: `secularized-purity-cross-platform-evidence-for.pdf`,
        seo_page: `secularized-purity-cross-platform-evidence-for.html`,
        slug: `the-stack-of-local-representations`,
        track: `researchPreprint`,
        version: 1,
        status: `active`,
        withdrawal_reason: ``,
        abstract: `Moral Foundations Theory (MFT) posits that political conservatives rely on all five moral foundations (Care, Fairness, Loyalty, Authority, Sanctity), whereas progressives primarily endorse the individualizing foundations of Care and Fairness. This study examines whether this asymmetry characterizes actual moral language use in naturalistic political discourse. Analyzing 4,789 Italian-language social media posts from Mastodon (N = 2,812) and Reddit (N = 1,977), we investigate the implicit deployment of moral foundations in progressive discourse using a custom Italian lexicon and robust non-parametric statistics. Across both platforms, 85–90% of progressive-coded posts contain markers of binding foundations, with large within-group effect sizes (Cramér’s V = 0.71–0.80). Authority-related language appears significantly more frequently in progressive discourse on both platforms, while Sanctity-related contamination rhetoric shows consistent directional effects with small effect sizes. These findings suggest that the liberal–conservative asymmetry described by MFT reflects differences in explicit moral endorsement rather than underlying moral-cognitive structure. Progressive discourse systematically deploys binding moral foundations through a secularized vocabulary of authority and moral contamination, despite explicit commitments to individualizing foundations alone.`,
        ai_assessment: `1) Category: Research preprint (as declared by author).
2) Aims: To demonstrate that Italian progressive social media discourse implicitly deploys binding moral foundations (Loyalty, Authority, Sanctity) through secularized vocabulary, challenging MFT's liberal-conservative asymmetry claim at the level of actual language use rather than explicit endorsement.
3) Correctness: Minor local issues.
4) Coherence: Adequate.
5) Consistency: Consistent.
6) Semantic opacity: Low (Transparent).
7) Novelty: Original.
8) Bibliography: Adequate.
9) Effectiveness: Achieves aims.
10) Cross-framework traction: Medium.
11) Claims: Supported.
12) Contribution: Substantive.
13) Structure: Adequate.
14) Integrity: No issues.
15) Code (if provided): Provided.
16) Editorial outcome: Suitable for inclusion as a research preprint.
17) Authors list: ["Franco Cazzaniga"]

This paper presents an empirical challenge to Moral Foundations Theory's asymmetry thesis through computational analysis of Italian social media discourse. The central claim—that progressives implicitly deploy binding foundations while explicitly endorsing only individualizing ones—is supported by cross-platform data showing 85–90% of progressive posts contain binding-foundation markers. The methodological apparatus is transparent: custom lexicon construction is justified, potential circularity concerns are addressed through independent hashtag-based validation, and non-parametric statistics accommodate zero-inflated distributions. The theoretical contribution lies in the "secularized purity" concept, demonstrating structural parallelism in moral reasoning across ideological camps despite divergent vocabularies. Minor issues include the acknowledged Italian specificity and lexicon-based classification limitations, but these do not undermine the core findings. The paper explicitly delimits its scope, avoiding overreach while maintaining substantive theoretical implications. The cross-platform replication strengthens robustness claims. Bibliography coverage is adequate for the empirical scope, though deeper engagement with Italian political discourse scholarship could enrich contextualization. The work achieves its stated aims and offers original empirical evidence with clear implications for political psychology research. Suitable for inclusion as a research preprint.
Editorial outcome: Suitable for inclusion as a research preprint.`,
        ai_collaboration: `Claude Opus 4.5, ChatGpt 5.2`,
        notes: ``
    }
];
