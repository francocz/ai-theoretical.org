# AI-Theoretical Architecture

Detailed technical documentation of the AI-Theoretical platform.

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         USERS                                    │
│                    (Authors / Readers)                           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Workers   │  │     KV      │  │          R2             │  │
│  │   (API)     │  │ (metadata)  │  │   (PDF storage)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              Zero Trust (Admin Auth)                        ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GITHUB PAGES                                   │
│           (Static HTML, CSS, JS, PDFs)                          │
└─────────────────────────────────────────────────────────────────┘
                      ▲
                      │ git push
                      │
┌─────────────────────────────────────────────────────────────────┐
│                 PHARO SMALLTALK                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ ATRepository│  │ATAutomation │  │   ATWebConsole          │  │
│  │  (domain)   │  │  (workflow) │  │   (local admin)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              MCP Server (Claude Integration)                ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Cloudflare Workers (API Layer)

**File**: `worker/ai-theoretical-api-v9.4.js`

Handles all HTTP API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/submit` | POST | New paper submission |
| `/api/confirm/:token` | GET | Email confirmation (double opt-in) |
| `/api/request-access` | POST | Author access request |
| `/api/author-login/:token` | GET | Author authentication |
| `/api/withdraw` | POST | Paper withdrawal |
| `/api/new-version` | POST | Submit new paper version |
| `/api/pending` | GET | List pending submissions (admin) |
| `/api/approve/:id` | POST | Approve submission (admin) |
| `/api/reject/:id` | POST | Reject submission (admin) |

### 2. Cloudflare KV (Metadata Storage)

**Namespaces**:
- `PENDING_SUBMISSIONS` - Submissions awaiting confirmation/review
- `PAPERS_METADATA` - Published paper metadata
- `ACCESS_TOKENS` - Temporary author access tokens
- `PROCESSED_IDS` - Deduplication for automation

### 3. Cloudflare R2 (File Storage)

**Bucket**: `ai-theoretical-pdfs`

Stores PDF files with keys like `papers/{slug}.pdf`

### 4. Pharo Smalltalk Classes

#### Core Domain

```
ATPaper
├── title, authors, abstract
├── date, track, version
├── slug (URL-safe identifier)
├── aiModels, aiCollaboration
├── status, isWithdrawn
└── aiAssessment (review results)

ATSubmission
├── All paper fields +
├── authorEmail, authorName
├── submittedAt, confirmedAt
├── pdfFile (temp storage)
└── asPaper (conversion)

ATRepository
├── papers (OrderedCollection)
├── gitRepoPath
├── addPaper:, deletePaper:
├── saveToJsFile:
└── regenerateAllPages
```

#### Static Pages Hierarchy

```
ATStaticPage (abstract)
├── head, body, content, css, javascript
├── saveTo: (generates HTML file)
│
├── ATIndexPage (homepage)
├── ATManifestoPage
├── ATEditorialPrinciplesPage
├── ATAIEditorialPromptPage
├── ATInvitePage
├── ATSubmitPage (two-panel hub)
├── ATSubmitFormPage (submission form)
├── ATAuthorAccessPage
├── ATUpdatePage
└── ATUpdateActionPage
```

#### Site Generation

```
ATSiteGenerator
├── seoPageForPaper: (HTML with Schema.org, Scholar tags)
├── jsonLdForPaper: (Schema.org JSON-LD)
├── googleScholarMetaTagsForPaper:to:
├── twitterCardsForPaper:to:
├── generateRssFeed
├── generateSitemap
└── escapeHtml:, escapeXml:

ATStyles
├── baseCss (shared styles)
├── indexCss (homepage specific)
├── trackFiltersCss
└── formCss
```

#### Automation

```
ATAutomation
├── processAllPending (main loop)
├── processSingleSubmission:
├── shouldProcess: (deduplication)
└── markAsProcessed:

ATAssessmentGenerator
├── provider (anthropic/openai/google)
├── assessSubmission:
├── buildPromptFor:
├── callAnthropicAPI:
├── callOpenAIAPI:
├── callGoogleAPI:
├── extractUsageFrom:
└── estimateCostFor:

ATEmailSender
├── sendConfirmationTo:token:
├── sendAcceptanceTo:paper:
├── sendRejectionTo:reason:
└── smtpConfig
```

#### Admin & Utilities

```
ATWebConsole
├── start/stop (Teapot server)
├── handlePending:
├── handleApprove:
├── handleReject:
├── handleNotifyWithdraw:
└── handleNotifyNewVersion:

ATAuditLog
├── log:action:details:
├── logError:
└── entries

ATDeployment
├── deployGitRepoPath:withMessage:
└── gitCommitAndPush:message:

ATSourceCleaner
└── cleanPackage: (format source code)
```

## Data Flow

### Paper Submission Flow

```
1. Author fills form on submit-form.html
         │
         ▼
2. POST /api/submit (Worker)
   - Validates input
   - Stores PDF in R2
   - Creates pending submission in KV
   - Sends confirmation email
         │
         ▼
3. Author clicks email link
   GET /api/confirm/:token (Worker)
   - Marks submission as confirmed
         │
         ▼
4. ATAutomation.processAllPending (Pharo)
   - Fetches confirmed submissions from KV
   - Runs AI assessment
   - Decides accept/reject
         │
         ├─── Accept ───▶ 5a. Publication
         │                   - Creates ATPaper
         │                   - Generates SEO page
         │                   - Updates papers.js
         │                   - Git commit & push
         │                   - Sends acceptance email
         │
         └─── Reject ───▶ 5b. Rejection
                            - Logs to ATRejectedRepository
                            - Sends rejection email
```

### Author Update Flow

```
1. Author requests access on author-access.html
         │
         ▼
2. POST /api/request-access (Worker)
   - Verifies email owns papers
   - Sends magic link email
         │
         ▼
3. Author clicks link, sees their papers
   Can choose: Withdraw or New Version
         │
         ├─── Withdraw ───▶ POST /api/withdraw
         │                   - Marks paper withdrawn
         │                   - Notifies Pharo
         │                   - Regenerates site
         │
         └─── New Version ─▶ POST /api/new-version
                              - Uploads new PDF
                              - Paper goes to pending
                              - Re-runs AI assessment
```

## SEO Implementation

### Per-Paper SEO Page

Each paper gets `papers/{slug}.html` with:

```html
<!-- Google Scholar -->
<meta name="citation_title" content="...">
<meta name="citation_author" content="...">
<meta name="citation_publication_date" content="2026-01-07">
<meta name="citation_pdf_url" content="...">

<!-- Open Graph -->
<meta property="og:type" content="article">
<meta property="og:title" content="...">

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image">

<!-- Schema.org JSON-LD -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "ScholarlyArticle",
  "headline": "...",
  "author": [...],
  "datePublished": "2026-01-07"
}
</script>

<!-- RSS Discovery -->
<link rel="alternate" type="application/rss+xml" href="/feed.xml">
```

### Sitemap

Generated by `ATSiteGenerator>>generateSitemap`:
- All static pages
- All paper pages
- `<lastmod>` dates
- `<priority>` (0.8 for papers)

## Configuration Files

| File | Purpose |
|------|---------|
| `config/cloudflare.json` | Worker bindings, KV namespaces |
| `secrets/api-keys.json` | AI provider API keys (gitignored) |
| `prompts/editorial-v*.md` | AI assessment prompt versions |

## Testing

22 test classes covering:
- Domain objects (ATPaper, ATSubmission)
- Repository operations
- Page generation
- Web console endpoints
- Assessment generator

Run all tests:
```smalltalk
ATTestCase allSubclasses do: [ :c | c buildSuite run ].
```

## Deployment

### Automatic (via Pharo)
```smalltalk
ATDeployment deployGitRepoPath: ATRepository current gitRepoPath 
             withMessage: 'Description of changes'.
```

### Manual
```bash
cd /path/to/ai-theoretical.org
git add -A
git commit -m "message"
git push
```

GitHub Pages automatically deploys on push to main.

## Monitoring

- **ATAuditLog**: All operations logged in Pharo image
- **Cloudflare Dashboard**: Worker invocations, KV operations
- **Google Search Console**: Indexing status
- **Bing Webmaster Tools**: Indexing status
