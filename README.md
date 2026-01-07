# AI-Theoretical.org

**Human–AI Co-Authored Theoretical Papers**

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

A platform for scholarly works openly co-authored by humans and frontier AI models. This repository contains both the published papers and the complete source code of the platform itself.

🌐 **Live site**: [https://ai-theoretical.org](https://ai-theoretical.org)  
📡 **RSS Feed**: [https://ai-theoretical.org/feed.xml](https://ai-theoretical.org/feed.xml)

## About

AI-Theoretical is an automated academic preprint repository where:
- Papers are co-authored by humans and AI models
- Submissions are reviewed by AI (different from the co-author)
- The entire editorial workflow is automated
- The platform itself was built through human-AI collaboration using Pharo Smalltalk

## Repository Structure

```
ai-theoretical.org/
├── index.html                 # Homepage with paper listings
├── papers/                    # Published papers (PDF + SEO pages)
├── papers.js                  # Paper metadata for frontend
├── src/                       # Pharo Smalltalk source code (Tonel format)
│   ├── AITheoretical/         # Main package (35 classes)
│   └── AITheoretical-Tests/   # Test package (22 test classes)
├── worker/                    # Cloudflare Worker (API backend)
├── prompts/                   # AI editorial assessment prompts
├── config/                    # Configuration files
├── data/                      # Persistent data (KV exports)
└── docs/                      # Documentation
```

## Static Pages

| Page | Description |
|------|-------------|
| `index.html` | Homepage with searchable paper list and track filters |
| `manifesto.html` | Platform manifesto and principles |
| `editorial-principles.html` | Editorial framework and review criteria |
| `ai-editorial-prompt.html` | The AI editorial assessment prompt |
| `invite.html` | Invitation to participate |
| `submit.html` | Submission hub (new papers / manage existing) |
| `submit-form.html` | Paper submission form |
| `author-access.html` | Author authentication for paper management |

## Technology Stack

### Backend (Pharo Smalltalk)
- **Runtime**: Pharo 12 with live image
- **MCP Integration**: Claude operates directly on the live image
- **Web Server**: Teapot (for local admin console)

### Frontend/Hosting
- **Static Site**: GitHub Pages
- **API**: Cloudflare Workers
- **Storage**: Cloudflare KV (metadata) + R2 (PDFs)
- **Auth**: Cloudflare Zero Trust (admin console)

### SEO & Discovery
- Schema.org JSON-LD (ScholarlyArticle)
- Google Scholar meta tags (citation_*)
- Open Graph + Twitter Cards
- RSS Feed
- Sitemap with lastmod

## Main Classes

### Core Domain
| Class | Description |
|-------|-------------|
| `ATPaper` | Published paper entity |
| `ATSubmission` | Pending submission |
| `ATRepository` | Paper repository and operations |

### Web Generation
| Class | Description |
|-------|-------------|
| `ATStaticPage` | Base class for HTML pages |
| `ATIndexPage` | Homepage generator |
| `ATSiteGenerator` | SEO pages, RSS, sitemap |
| `ATStyles` | Centralized CSS |

### Automation
| Class | Description |
|-------|-------------|
| `ATAutomation` | Orchestrates editorial workflow |
| `ATAssessmentGenerator` | AI review via multiple providers |
| `ATEmailSender` | Transactional emails |
| `ATDeployment` | Git operations and deploy |

### Admin
| Class | Description |
|-------|-------------|
| `ATWebConsole` | Local admin web interface |
| `ATAuditLog` | Operation logging |

## Editorial Workflow

1. **Submission** → Author submits via form (double opt-in email)
2. **Review** → AI assessment (16 criteria, multiple providers)
3. **Decision** → Automated accept/reject based on scores
4. **Publication** → PDF stored, SEO page generated, site deployed
5. **Updates** → Authors can submit new versions or withdraw

## Development

### Requirements
- Pharo 12
- MCP server for Claude integration
- Cloudflare account (Workers, KV, R2)
- GitHub repository for deployment

### Loading the Project
```smalltalk
Metacello new
    repository: 'github://ai-theoretical/ai-theoretical.org:main/src';
    baseline: 'AITheoretical';
    load.
```

### Running Tests
```smalltalk
(PackageOrganizer default packageNamed: 'AITheoretical-Tests') 
    definedClasses 
    select: [ :c | c inheritsFrom: TestCase ]
    thenDo: [ :c | c buildSuite run ].
```

## Papers Published

Current papers are listed at [ai-theoretical.org](https://ai-theoretical.org) and available via the [RSS feed](https://ai-theoretical.org/feed.xml).

## Contributing

- **Submit a paper**: Use the [submission form](https://ai-theoretical.org/submit-form.html)
- **Report issues**: Open a GitHub issue
- **Contact**: franco.cazzaniga@uninsubria.it

## License

- **Papers**: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- **Code**: MIT License

---

*Built through human-AI collaboration with Claude (Anthropic) and Pharo Smalltalk*
