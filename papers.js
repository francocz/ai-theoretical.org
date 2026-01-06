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
        notes: ""
    }
];