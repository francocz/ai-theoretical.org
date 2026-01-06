const PAPERS_DATA = [
    {
        title: "Image-Based Development with LLM Agents: Building ai-theoretical.org in 72 Hours",
        author: "Franco Cazzaniga (Università dell'Insubria), Claude Opus 4.5",
        ai_model: "Claude Opus 4.5",
        date: "",
        pages: "",
        pdf_file: "papers/image-based-development-with-llm-agents.pdf",
        seo_page: "papers/image-based-development-with-llm-agents.html",
        slug: "image-based-development-with-llm-agents",
        track: "workingPaper",
        version: 1,
        status: "active",
        withdrawal_reason: "",
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
        title: "Wave Function Collapse as Lie Algebra Contraction: The SU(2) Spin-1/2 Paradigm",
        author: "Franco Cazzaniga (Università dell'Insubria)",
        ai_model: "Claude Opus 4.5, Chat Gpt 5.2",
        date: "",
        pages: "",
        pdf_file: "papers/wave-function-collapse-as-lie.pdf",
        seo_page: "papers/wave-function-collapse-as-lie.html",
        slug: "wave-function-collapse-as-lie",
        track: "researchPreprint",
        version: 1,
        status: "active",
        withdrawal_reason: "",
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
    }
];

