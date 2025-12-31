/**
 * REPOSITORY DEI PAPER
 * Per aggiungere un paper: copia un blocco tra parentesi graffe e compilalo.
 */
const PAPERS_DATA = [
    {
        title: "The Invisible Pillar: On the Genesis and Concealment of Dualism from the Pre-Socratics to the Moderns",
        author: "Franco Cazzaniga",
        ai_model: "Claude Opus 4.5 (Anthropic)",
        date: "December 2025",
        pages: "20",
        pdf_file: "The Invisible Pillar.pdf",
        readme_url: "https://github.com/francocz/ai-theoretical.org",
        abstract: `This paper traces the genealogy of the dualism between intelligible and sensible, between \emph{logos} and matter, from its pre-Socratic background through its Platonic inauguration to its modern transformations. The central thesis is that Plato introduced a structural division that subsequent philosophy inherited, criticized superficially, re-articulated, but rarely questioned as a framework. The paper examines how this dualism was first epistemic and social (Plato's distinction between philosophical knowledge and common experience), then cosmological (the scientific revolution's separation between the mathematically describable real and the qualitatively perceived apparent), and finally metaphysical (Descartes' res cogitans and res extensa). The natural philosophers of the sixteenth and seventeenth centuries---Copernicus, Kepler, Galileo, Newton---are treated here as what they were: philosophers investigating nature, whose work deepened and transformed the Platonic distance between the true and the accessible. The aim is not to refute dualism but to make it visible as a historical structure, a framework that has become so assimilated as to be invisible.`
        ,
        ai_assessment: `
(A) STRUCTURED SUMMARY
Category: Expository / theoretical essay
Aims: Synthetic and critical reconstruction of the Platonic dualist framework.
Correctness: No errors identified.
Coherence: Adequate.
Consistency: Consistent.
Novelty: Reformulative.
Bibliography: Adequate.
Effectiveness: Achieves aims.
Cross-framework traction: High.
Editorial outcome: Suitable for inclusion as a preprint.

(B) EXTENDED ASSESSMENT
[qui il giudizio esteso, 120–200 parole]
        `,

        ai_collaboration: `
This paper was developed through an iterative process involving an AI language model.
The AI contributed to structuring arguments, testing formulations, and refining exposition.
Final responsibility for content and claims remains human.
        `
    },
    /* Esempio di come aggiungere il prossimo:
    {
        title: "Titolo del prossimo saggio",
        author: "Nome Autore",
        ai_model: "GPT-5 / Gemini 2.0",
        date: "January 2026",
        pages: "15",
        file: "secondo_paper.pdf",
        readme_url: "https://whatever.org"
        abstract: "Qui scriverai l'abstract del secondo saggio..."
    }, 
    */
];
