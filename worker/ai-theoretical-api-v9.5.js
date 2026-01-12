/**
 * AI-Theoretical Submission Worker
 * Version: 9.5
 * Updated: 2026-01-11
 * 
 * 
 *  Changes in v9.4:
 *   - Added public paper access: /papers/:slug.pdf and /papers/:slug.zip
 *     Serves accepted papers directly from R2 (no more local copy to GitHub)
 *   - Added appeal system for rejected submissions:
 *     - POST /api/appeal - Submit appeal with optional new PDF/ZIP
 *     - GET /api/appeal/:token - Check appeal validity
 *     - 14 days deadline from rejection
 *     - One appeal only, second assessment is final
 *   - Added generateSlug() function matching Pharo logic
 * 
 * Changes in v9.4:
 *   - Withdraw and new-version now notify Pharo to regenerate site
 *   - Paper is removed from homepage immediately after withdraw/new-version
 * 
 * Changes in v9.3:
 *   - Fixed routing: changed /author-access/:token to /api/author-access/page/:token
 *   - This ensures the worker handles the request instead of GitHub Pages
 * 
 * Changes in v9.2:
 *   - Added POST /api/author-access/withdraw - Withdraw a paper
 *   - Added POST /api/author-access/new-version - Submit new version of paper
 *   - Author access page now fully functional with API calls
 *   - Withdrawal and new version confirmation emails
 *   - Version history tracking for papers
 * 
 * Changes in v9.1:
 *   - Added GET /api/author-access/page/:token - HTML page for managing papers
 *   - Page shows list of author's papers with withdraw/new version options
 * 
 * Changes in v9.0:
 *   - Added author-access system for paper withdrawal and versioning
 *   - POST /api/author-access/request - Request access link via email (public, rate limited)
 *   - GET  /api/author-access/rate-limit - View author-access rate limit status (protected)
 *   - POST /api/author-access/rate-limit - Configure author-access rate limits (protected)
 *   - Separate rate limiting for author-access (per-email and global daily limits)
 * 
 * Changes in v8.0:
 *   - Added coAuthors field for multi-author submissions
 * 
 * Changes in v5.0:
 *   - Added rate limiting (global daily + per-IP)
 *   - Rate limits configurable via protected API endpoints
 *   - Rate limit status visible in API
 * 
 * Changes in v4.0:
 *   - Added track selection (researchPreprint, workingPaper, expositoryEssay, criticalReview)
 *   - Track is required field in submission
 *   - Track included in submission data and emails
 * 
 * Endpoints:
 *   POST /api/submit                    - Riceve nuova submission (pubblico, rate limited) → status: unconfirmed
 *   GET  /api/confirm/:token            - Conferma email (pubblico) → status: pending
 *   GET  /api/submissions               - Lista submission pending (protetto)
 *   GET  /api/submission/:id            - Singola submission (protetto)
 *   POST /api/submission/:id/status     - Aggiorna status (protetto)
 *   DELETE /api/submission/:id          - Elimina submission (protetto)
 *   POST /api/send-email                - Invia email via Resend (protetto)
 *   POST /api/verify-token              - Verifica paper token per gestione (pubblico)
 *   GET  /api/submission/:id/pdf        - Download PDF (protetto)
 *   GET  /api/submission/:id/code       - Download code ZIP (protetto)
 *   GET  /api/rate-limit                - Stato rate limit submission (protetto)
 *   POST /api/rate-limit                - Configura rate limit submission (protetto)
 *   POST /api/author-access/request     - Richiedi link accesso autore (pubblico, rate limited)
 *   GET  /api/author-access/rate-limit  - Stato rate limit author-access (protetto)
 *   POST /api/author-access/rate-limit  - Configura rate limit author-access (protetto)
 *   GET  /api/author-access/page/:token - Pagina gestione paper autore (pubblico, token required)
 *   POST /api/author-access/withdraw    - Ritira un paper (pubblico, token required)
 *   POST /api/author-access/new-version - Nuova versione paper (pubblico, token required)
 * 
 * Environment bindings richiesti:
 *   - SUBMISSIONS: KV namespace per i metadati
 *   - PAPERS: R2 bucket per i PDF e code
 *   - API_TOKEN: Secret per autenticazione
 *   - RESEND_API_KEY: Secret per Resend email
 */

// Valid tracks
const VALID_TRACKS = ['researchPreprint', 'workingPaper', 'expositoryEssay', 'criticalReview'];

const TRACK_DISPLAY_NAMES = {
  researchPreprint: 'Research Preprint',
  workingPaper: 'Working Paper',
  expositoryEssay: 'Expository/Theoretical Essay',
  criticalReview: 'Critical Review'
};

// Rate limit defaults for submissions
const DEFAULT_DAILY_LIMIT = 50;
const DEFAULT_IP_LIMIT = 5;
const RATE_LIMIT_CONFIG_KEY = '__rate_limit_config__';
const RATE_LIMIT_DAILY_KEY = '__rate_limit_daily__';

// Rate limit defaults for author-access
const DEFAULT_AUTHOR_ACCESS_DAILY_LIMIT = 10;
const DEFAULT_AUTHOR_ACCESS_EMAIL_LIMIT = 3;
const AUTHOR_ACCESS_CONFIG_KEY = '__author_access_config__';
const AUTHOR_ACCESS_DAILY_KEY = '__author_access_daily__';

// ============================================
// SLUG GENERATION (must match Pharo logic)
// ============================================

function generateSlug(title) {
  const words = title.trim().split(/\s+/);
  const truncated = words.slice(0, 5).join(' ');
  return truncated
    .toLowerCase()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '');
}

// ============================================
// APPEAL HELPERS
// ============================================

function generateAppealToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let token = '';
  for (let i = 0; i < 32; i++) {
    token += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return token;
}

function isAppealValid(submission) {
  if (!submission.rejectedAt || !submission.appealToken) return false;
  const rejectedDate = new Date(submission.rejectedAt);
  const now = new Date();
  const daysDiff = (now - rejectedDate) / (1000 * 60 * 60 * 24);
  return daysDiff <= 14;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
    
    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    try {
      // POST /api/submit - Nuova submission (pubblico, rate limited)
      if (path === '/api/submit' && request.method === 'POST') {
        // Check rate limit BEFORE processing
        const clientIP = request.headers.get('CF-Connecting-IP') || 'unknown';
        const rateLimitCheck = await checkRateLimit(env, clientIP);
        
        if (!rateLimitCheck.allowed) {
          return new Response(JSON.stringify({ 
            error: 'Rate limit exceeded',
            reason: rateLimitCheck.reason,
            retryAfter: rateLimitCheck.retryAfter
          }), {
            status: 429,
            headers: { 
              ...corsHeaders, 
              'Content-Type': 'application/json',
              'Retry-After': String(rateLimitCheck.retryAfter || 3600)
            }
          });
        }
        
        return await handleSubmit(request, env, corsHeaders, clientIP);
      }
      
      // GET /api/confirm/:token - Conferma email (pubblico)
      const confirmMatch = path.match(/^\/api\/confirm\/([A-Za-z0-9]+)$/);
      if (confirmMatch && request.method === 'GET') {
        return await handleConfirm(confirmMatch[1], env);
      }
      
      // POST /api/verify-token - Verifica token per gestione paper (pubblico)
      if (path === '/api/verify-token' && request.method === 'POST') {
        return await handleVerifyToken(request, env, corsHeaders);
      }
      
      // POST /api/author-access/request - Richiedi link accesso autore (pubblico, rate limited)
      if (path === '/api/author-access/request' && request.method === 'POST') {
        return await handleAuthorAccessRequest(request, env, corsHeaders);
      }
      
      // GET /api/author-access/page/:token - Pagina gestione paper (pubblico)
      const authorAccessMatch = path.match(/^\/api\/author-access\/page\/([a-f0-9-]+)$/);
      if (authorAccessMatch && request.method === 'GET') {
        return await handleAuthorAccessPage(authorAccessMatch[1], env);
      }
      
      // POST /api/author-access/withdraw - Ritira un paper (pubblico, token required)
      if (path === '/api/author-access/withdraw' && request.method === 'POST') {
        return await handleAuthorAccessWithdraw(request, env, corsHeaders);
      }
      
      // POST /api/author-access/new-version - Carica nuova versione (pubblico, token required)
      if (path === '/api/author-access/new-version' && request.method === 'POST') {
        return await handleAuthorAccessNewVersion(request, env, corsHeaders);
      }
      
      // Tutti gli altri endpoint richiedono autenticazione
      if (!isAuthenticated(request, env)) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      
      // GET /api/rate-limit - Stato rate limit submission (protetto)
      if (path === '/api/rate-limit' && request.method === 'GET') {
        return await handleGetRateLimit(env, corsHeaders);
      }
      
      // POST /api/rate-limit - Configura rate limit submission (protetto)
      if (path === '/api/rate-limit' && request.method === 'POST') {
        return await handleSetRateLimit(request, env, corsHeaders);
      }
      
      // GET /api/author-access/rate-limit - Stato rate limit author-access (protetto)
      if (path === '/api/author-access/rate-limit' && request.method === 'GET') {
        return await handleGetAuthorAccessRateLimit(env, corsHeaders);
      }
      
      // POST /api/author-access/rate-limit - Configura rate limit author-access (protetto)
      if (path === '/api/author-access/rate-limit' && request.method === 'POST') {
        return await handleSetAuthorAccessRateLimit(request, env, corsHeaders);
      }
      
      // GET /api/submissions - Lista pending
      if (path === '/api/submissions' && request.method === 'GET') {
        return await handleList(env, corsHeaders);
      }
      
      // POST /api/send-email - Invia email (protetto)
      if (path === '/api/send-email' && request.method === 'POST') {
        if (!isAuthenticated(request, env)) {
          return new Response(JSON.stringify({ error: 'Unauthorized' }), {
            status: 401,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          });
        }
        return await handleSendEmail(request, env, corsHeaders);
      }
      
      // GET /api/submission/:id
      const getMatch = path.match(/^\/api\/submission\/([a-z0-9-]+)$/);
      if (getMatch && request.method === 'GET') {
        return await handleGet(getMatch[1], env, corsHeaders);
      }
      
      // GET /api/submission/:id/pdf - Download PDF
      const pdfMatch = path.match(/^\/api\/submission\/([a-z0-9-]+)\/pdf$/);
      if (pdfMatch && request.method === 'GET') {
        return await handleDownloadPdf(pdfMatch[1], env, corsHeaders);
      }
      
      // GET /api/submission/:id/code - Download code ZIP
      const codeMatch = path.match(/^\/api\/submission\/([a-z0-9-]+)\/code$/);
      if (codeMatch && request.method === 'GET') {
        return await handleDownloadCode(codeMatch[1], env, corsHeaders);
      }
      
      // POST /api/submission/:id/status
      const statusMatch = path.match(/^\/api\/submission\/([a-z0-9-]+)\/status$/);
      if (statusMatch && request.method === 'POST') {
        return await handleStatusUpdate(statusMatch[1], request, env, corsHeaders);
      }
      
      // DELETE /api/submission/:id
      const deleteMatch = path.match(/^\/api\/submission\/([a-z0-9-]+)$/);
      if (deleteMatch && request.method === 'DELETE') {
        return await handleDelete(deleteMatch[1], env, corsHeaders);
      }
      
// ============================================
      // PUBLIC PAPER ACCESS (after accept)
      // ============================================
      
      // GET /papers/:slug.pdf - Serve published PDF
      const publicPdfMatch = path.match(/^\/papers\/([a-z0-9-]+)\.pdf$/);
      if (publicPdfMatch && request.method === 'GET') {
        const slug = publicPdfMatch[1];
        
        const list = await env.SUBMISSIONS_KV.list();
        let submission = null;
        
        for (const key of list.keys) {
          const data = await env.SUBMISSIONS_KV.get(key.name, 'json');
          if (data && data.status === 'accepted' && generateSlug(data.title) === slug) {
            submission = data;
            break;
          }
        }
        
        if (!submission) {
          return new Response('Not found', { status: 404, headers: corsHeaders });
        }
        
        const object = await env.SUBMISSIONS_BUCKET.get(submission.pdfKey);
        if (!object) {
          return new Response('File not found', { status: 404, headers: corsHeaders });
        }
        
        return new Response(object.body, {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/pdf',
            'Content-Disposition': `inline; filename="${slug}.pdf"`,
            'Cache-Control': 'public, max-age=86400'
          }
        });
      }
      
      // GET /papers/:slug.zip - Serve published code archive
      const publicZipMatch = path.match(/^\/papers\/([a-z0-9-]+)\.zip$/);
      if (publicZipMatch && request.method === 'GET') {
        const slug = publicZipMatch[1];
        
        const list = await env.SUBMISSIONS_KV.list();
        let submission = null;
        
        for (const key of list.keys) {
          const data = await env.SUBMISSIONS_KV.get(key.name, 'json');
          if (data && data.status === 'accepted' && generateSlug(data.title) === slug) {
            submission = data;
            break;
          }
        }
        
        if (!submission || !submission.codeZipKey) {
          return new Response('Not found', { status: 404, headers: corsHeaders });
        }
        
        const object = await env.SUBMISSIONS_BUCKET.get(submission.codeZipKey);
        if (!object) {
          return new Response('File not found', { status: 404, headers: corsHeaders });
        }
        
        return new Response(object.body, {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/zip',
            'Content-Disposition': `attachment; filename="${slug}.zip"`,
            'Cache-Control': 'public, max-age=86400'
          }
        });
      }      
	        // ============================================
	        // APPEAL SYSTEM
	        // ============================================
      
	        // GET /api/appeal/:token - Check appeal status/validity (pubblico)
	        const appealCheckMatch = path.match(/^\/api\/appeal\/([A-Za-z0-9]+)$/);
	        if (appealCheckMatch && request.method === 'GET') {
	          const token = appealCheckMatch[1];
        
	          const list = await env.SUBMISSIONS_KV.list();
	          for (const key of list.keys) {
	            const data = await env.SUBMISSIONS_KV.get(key.name, 'json');
	            if (data && data.appealToken === token) {
	              if (!isAppealValid(data)) {
	                return new Response(JSON.stringify({ 
	                  valid: false, 
	                  reason: 'Appeal deadline has passed' 
	                }), {
	                  status: 200,
	                  headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	                });
	              }
	              return new Response(JSON.stringify({
	                valid: true,
	                title: data.title,
	                deadline: data.appealDeadline,
	                originalAssessment: data.assessmentText
	              }), {
	                status: 200,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
	          }
        
	          return new Response(JSON.stringify({ valid: false, reason: 'Invalid token' }), {
	            status: 404,
	            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	          });
	        }
      
	        // POST /api/appeal - Submit an appeal (pubblico)
	        if (path === '/api/appeal' && request.method === 'POST') {
	          try {
	            const formData = await request.formData();
          
	            const appealToken = formData.get('appealToken');
	            const responseText = formData.get('responseText');
	            const newPdf = formData.get('pdf');
	            const newCode = formData.get('code');
          
	            if (!appealToken) {
	              return new Response(JSON.stringify({ error: 'Appeal token is required' }), {
	                status: 400,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
	            if (!responseText || responseText.trim().length < 50) {
	              return new Response(JSON.stringify({ error: 'Response text is required (minimum 50 characters)' }), {
	                status: 400,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
          
	            const list = await env.SUBMISSIONS_KV.list();
	            let submission = null;
	            let submissionId = null;
          
	            for (const key of list.keys) {
	              const data = await env.SUBMISSIONS_KV.get(key.name, 'json');
	              if (data && data.appealToken === appealToken) {
	                submission = data;
	                submissionId = key.name;
	                break;
	              }
	            }
          
	            if (!submission) {
	              return new Response(JSON.stringify({ error: 'Invalid appeal token' }), {
	                status: 404,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
          
	            if (submission.appealCount >= 1) {
	              return new Response(JSON.stringify({ error: 'Appeal already submitted. Decision is final.' }), {
	                status: 400,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
          
	            if (!isAppealValid(submission)) {
	              return new Response(JSON.stringify({ error: 'Appeal deadline has passed (14 days from rejection)' }), {
	                status: 400,
	                headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	              });
	            }
          
	            if (newPdf && newPdf.size > 0) {
	              if (newPdf.type !== 'application/pdf') {
	                return new Response(JSON.stringify({ error: 'File must be a PDF' }), {
	                  status: 400,
	                  headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	                });
	              }
	              const pdfKey = `submissions/${submissionId}-appeal.pdf`;
	              await env.SUBMISSIONS_BUCKET.put(pdfKey, newPdf.stream(), {
	                httpMetadata: { contentType: 'application/pdf' }
	              });
	              submission.pdfKey = pdfKey;
	            }
          
	            if (newCode && newCode.size > 0) {
	              if (!newCode.type.includes('zip')) {
	                return new Response(JSON.stringify({ error: 'Code must be a ZIP file' }), {
	                  status: 400,
	                  headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	                });
	              }
	              const codeKey = `submissions/${submissionId}-appeal-code.zip`;
	              await env.SUBMISSIONS_BUCKET.put(codeKey, newCode.stream(), {
	                httpMetadata: { contentType: 'application/zip' }
	              });
	              submission.codeZipKey = codeKey;
	            }
          
	            submission.status = 'appealed';
	            submission.appealCount = 1;
	            submission.appealText = responseText.trim();
	            submission.appealedAt = new Date().toISOString();
	            submission.appealToken = null;
          
	            await env.SUBMISSIONS_KV.put(submissionId, JSON.stringify(submission));
          
	            return new Response(JSON.stringify({
	              success: true,
	              message: 'Appeal submitted successfully. Your submission will be re-evaluated.',
	              id: submissionId
	            }), {
	              status: 200,
	              headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	            });
          
	          } catch (error) {
	            return new Response(JSON.stringify({ error: 'Failed to process appeal: ' + error.message }), {
	              status: 500,
	              headers: { ...corsHeaders, 'Content-Type': 'application/json' }
	            });
	          }
	        }
			
      // 404
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
      
    } catch (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
};

// ============================================================================
// SUBMISSION RATE LIMITING FUNCTIONS
// ============================================================================

/**
 * Get rate limit configuration from KV
 */
async function getRateLimitConfig(env) {
  const data = await env.SUBMISSIONS.get(RATE_LIMIT_CONFIG_KEY);
  if (data) {
    return JSON.parse(data);
  }
  return {
    dailyLimit: DEFAULT_DAILY_LIMIT,
    ipLimit: DEFAULT_IP_LIMIT,
    enabled: true,
    alertEmail: null
  };
}

/**
 * Get today's date string (UTC) for rate limit keys
 */
function getTodayKey() {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD
}

/**
 * Get daily rate limit data
 */
async function getDailyData(env) {
  const todayKey = getTodayKey();
  const key = `${RATE_LIMIT_DAILY_KEY}:${todayKey}`;
  const data = await env.SUBMISSIONS.get(key);
  
  if (data) {
    return JSON.parse(data);
  }
  return {
    date: todayKey,
    globalCount: 0,
    ipCounts: {}
  };
}

/**
 * Save daily rate limit data (with TTL of 48 hours to auto-cleanup)
 */
async function saveDailyData(env, data) {
  const key = `${RATE_LIMIT_DAILY_KEY}:${data.date}`;
  await env.SUBMISSIONS.put(key, JSON.stringify(data), {
    expirationTtl: 48 * 60 * 60  // 48 hours
  });
}

/**
 * Check if submission is allowed under rate limits
 * Returns: { allowed: boolean, reason?: string, retryAfter?: number }
 */
async function checkRateLimit(env, clientIP) {
  const config = await getRateLimitConfig(env);
  
  // Rate limiting disabled?
  if (!config.enabled) {
    return { allowed: true };
  }
  
  const daily = await getDailyData(env);
  
  // Check global daily limit
  if (daily.globalCount >= config.dailyLimit) {
    // Calculate seconds until midnight UTC
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    tomorrow.setUTCHours(0, 0, 0, 0);
    const retryAfter = Math.ceil((tomorrow - now) / 1000);
    
    return {
      allowed: false,
      reason: 'Daily submission limit reached. Please try again tomorrow.',
      retryAfter
    };
  }
  
  // Check per-IP limit
  const ipCount = daily.ipCounts[clientIP] || 0;
  if (ipCount >= config.ipLimit) {
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    tomorrow.setUTCHours(0, 0, 0, 0);
    const retryAfter = Math.ceil((tomorrow - now) / 1000);
    
    return {
      allowed: false,
      reason: 'Too many submissions from your IP address today. Please try again tomorrow.',
      retryAfter
    };
  }
  
  return { allowed: true };
}

/**
 * Record a submission for rate limiting
 */
async function recordSubmission(env, clientIP) {
  const daily = await getDailyData(env);
  
  daily.globalCount += 1;
  daily.ipCounts[clientIP] = (daily.ipCounts[clientIP] || 0) + 1;
  
  await saveDailyData(env, daily);
  
  // Check if we should send alert
  const config = await getRateLimitConfig(env);
  if (config.alertEmail) {
    const threshold80 = Math.ceil(config.dailyLimit * 0.8);
    
    if (daily.globalCount === threshold80) {
      await sendRateLimitAlert(env, config.alertEmail, 'warning', daily.globalCount, config.dailyLimit);
    } else if (daily.globalCount === config.dailyLimit) {
      await sendRateLimitAlert(env, config.alertEmail, 'critical', daily.globalCount, config.dailyLimit);
    }
  }
  
  return daily;
}

/**
 * Send rate limit alert email
 */
async function sendRateLimitAlert(env, email, level, count, limit) {
  const subject = level === 'critical' 
    ? '[ai-theoretical.org] CRITICAL: Daily submission limit reached'
    : '[ai-theoretical.org] Warning: 80% of daily submission limit reached';
  
  const body = `Rate limit alert for ai-theoretical.org

Status: ${level.toUpperCase()}
Current count: ${count}/${limit}
Date: ${getTodayKey()}

${level === 'critical' 
  ? 'New submissions are now being rejected until midnight UTC.'
  : 'Consider monitoring for potential abuse.'}
`;

  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.RESEND_API_KEY}`
      },
      body: JSON.stringify({
        to: [email],
        from: 'AI-Theoretical <noreply@ai-theoretical.org>',
        subject: subject,
        text: body
      })
    });
  } catch (e) {
    // Ignore email errors - don't break submission flow
    console.error('Failed to send rate limit alert:', e);
  }
}

/**
 * GET /api/rate-limit
 * Returns current rate limit status and configuration
 */
async function handleGetRateLimit(env, corsHeaders) {
  const config = await getRateLimitConfig(env);
  const daily = await getDailyData(env);
  
  // Sort IPs by count for visibility
  const topIPs = Object.entries(daily.ipCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([ip, count]) => ({ ip, count }));
  
  return new Response(JSON.stringify({
    config: {
      dailyLimit: config.dailyLimit,
      ipLimit: config.ipLimit,
      enabled: config.enabled,
      alertEmail: config.alertEmail ? '***configured***' : null
    },
    today: {
      date: daily.date,
      globalCount: daily.globalCount,
      remaining: Math.max(0, config.dailyLimit - daily.globalCount),
      percentUsed: ((daily.globalCount / config.dailyLimit) * 100).toFixed(1),
      uniqueIPs: Object.keys(daily.ipCounts).length,
      topIPs
    }
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * POST /api/rate-limit
 * Update rate limit configuration
 * Body: { dailyLimit?: number, ipLimit?: number, enabled?: boolean, alertEmail?: string|null }
 */
async function handleSetRateLimit(request, env, corsHeaders) {
  const body = await request.json();
  const config = await getRateLimitConfig(env);
  
  // Update only provided fields
  if (typeof body.dailyLimit === 'number' && body.dailyLimit > 0) {
    config.dailyLimit = body.dailyLimit;
  }
  if (typeof body.ipLimit === 'number' && body.ipLimit > 0) {
    config.ipLimit = body.ipLimit;
  }
  if (typeof body.enabled === 'boolean') {
    config.enabled = body.enabled;
  }
  if (body.alertEmail !== undefined) {
    config.alertEmail = body.alertEmail; // can be null to disable
  }
  
  await env.SUBMISSIONS.put(RATE_LIMIT_CONFIG_KEY, JSON.stringify(config));
  
  return new Response(JSON.stringify({ 
    success: true, 
    config: {
      dailyLimit: config.dailyLimit,
      ipLimit: config.ipLimit,
      enabled: config.enabled,
      alertEmail: config.alertEmail ? '***configured***' : null
    }
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// ============================================================================
// AUTHOR-ACCESS RATE LIMITING FUNCTIONS
// ============================================================================

/**
 * Get author-access rate limit configuration from KV
 */
async function getAuthorAccessConfig(env) {
  const data = await env.SUBMISSIONS.get(AUTHOR_ACCESS_CONFIG_KEY);
  if (data) {
    return JSON.parse(data);
  }
  return {
    dailyLimit: DEFAULT_AUTHOR_ACCESS_DAILY_LIMIT,
    emailLimit: DEFAULT_AUTHOR_ACCESS_EMAIL_LIMIT,
    enabled: true
  };
}

/**
 * Get daily author-access rate limit data
 */
async function getAuthorAccessDailyData(env) {
  const todayKey = getTodayKey();
  const key = `${AUTHOR_ACCESS_DAILY_KEY}:${todayKey}`;
  const data = await env.SUBMISSIONS.get(key);
  
  if (data) {
    return JSON.parse(data);
  }
  return {
    date: todayKey,
    globalCount: 0,
    emailCounts: {}
  };
}

/**
 * Save daily author-access rate limit data (with TTL of 48 hours)
 */
async function saveAuthorAccessDailyData(env, data) {
  const key = `${AUTHOR_ACCESS_DAILY_KEY}:${data.date}`;
  await env.SUBMISSIONS.put(key, JSON.stringify(data), {
    expirationTtl: 48 * 60 * 60  // 48 hours
  });
}

/**
 * Check if author-access request is allowed under rate limits
 * Returns: { allowed: boolean, reason?: string }
 */
async function checkAuthorAccessRateLimit(env, email) {
  const config = await getAuthorAccessConfig(env);
  
  if (!config.enabled) {
    return { allowed: true };
  }
  
  const daily = await getAuthorAccessDailyData(env);
  const emailLower = email.toLowerCase();
  
  // Check global daily limit
  if (daily.globalCount >= config.dailyLimit) {
    return {
      allowed: false,
      reason: 'Too many access requests today. Please try again tomorrow.'
    };
  }
  
  // Check per-email limit
  const emailCount = daily.emailCounts[emailLower] || 0;
  if (emailCount >= config.emailLimit) {
    return {
      allowed: false,
      reason: 'Too many requests for this email today. Please try again tomorrow.'
    };
  }
  
  return { allowed: true };
}

/**
 * Record an author-access request for rate limiting
 */
async function recordAuthorAccessRequest(env, email) {
  const daily = await getAuthorAccessDailyData(env);
  const emailLower = email.toLowerCase();
  
  daily.globalCount += 1;
  daily.emailCounts[emailLower] = (daily.emailCounts[emailLower] || 0) + 1;
  
  await saveAuthorAccessDailyData(env, daily);
  return daily;
}

/**
 * GET /api/author-access/rate-limit
 * Returns current author-access rate limit status and configuration
 */
async function handleGetAuthorAccessRateLimit(env, corsHeaders) {
  const config = await getAuthorAccessConfig(env);
  const daily = await getAuthorAccessDailyData(env);
  
  // Sort emails by count for visibility
  const topEmails = Object.entries(daily.emailCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .map(([email, count]) => ({ email: email.replace(/(.{3}).*(@.*)/, '$1***$2'), count }));
  
  return new Response(JSON.stringify({
    config: {
      dailyLimit: config.dailyLimit,
      emailLimit: config.emailLimit,
      enabled: config.enabled
    },
    today: {
      date: daily.date,
      globalCount: daily.globalCount,
      remaining: Math.max(0, config.dailyLimit - daily.globalCount),
      uniqueEmails: Object.keys(daily.emailCounts).length,
      topEmails
    }
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * POST /api/author-access/rate-limit
 * Update author-access rate limit configuration
 * Body: { dailyLimit?: number, emailLimit?: number, enabled?: boolean }
 */
async function handleSetAuthorAccessRateLimit(request, env, corsHeaders) {
  const body = await request.json();
  const config = await getAuthorAccessConfig(env);
  
  if (typeof body.dailyLimit === 'number' && body.dailyLimit > 0) {
    config.dailyLimit = body.dailyLimit;
  }
  if (typeof body.emailLimit === 'number' && body.emailLimit > 0) {
    config.emailLimit = body.emailLimit;
  }
  if (typeof body.enabled === 'boolean') {
    config.enabled = body.enabled;
  }
  
  await env.SUBMISSIONS.put(AUTHOR_ACCESS_CONFIG_KEY, JSON.stringify(config));
  
  return new Response(JSON.stringify({ 
    success: true, 
    config
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// ============================================================================
// AUTHOR-ACCESS REQUEST HANDLER
// ============================================================================

/**
 * POST /api/author-access/request
 * Body: { "email": "author@example.com" }
 * 
 * Checks if email has any accepted papers, generates access token, sends email
 */
async function handleAuthorAccessRequest(request, env, corsHeaders) {
  const { email } = await request.json();
  
  if (!email) {
    return new Response(JSON.stringify({ error: 'Email is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return new Response(JSON.stringify({ error: 'Invalid email format' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Check rate limit
  const rateLimitCheck = await checkAuthorAccessRateLimit(env, email);
  if (!rateLimitCheck.allowed) {
    return new Response(JSON.stringify({ 
      success: false,
      error: rateLimitCheck.reason
    }), {
      status: 429,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Find all accepted papers for this email
  const emailLower = email.toLowerCase();
  const authorPapers = [];
  
  const allKeys = await env.SUBMISSIONS.list();
  for (const key of allKeys.keys) {
    // Skip internal keys
    if (key.name.startsWith('__')) continue;
    if (key.name.startsWith('confirm:')) continue;
    if (key.name.startsWith('author-access:')) continue;
    
    const data = await env.SUBMISSIONS.get(key.name);
    if (data) {
      const sub = JSON.parse(data);
      if (sub.authorEmail && sub.authorEmail.toLowerCase() === emailLower && sub.status === 'accepted') {
        authorPapers.push({
          id: sub.id,
          title: sub.title,
          track: sub.track,
          submittedAt: sub.submittedAt
        });
      }
    }
  }
  
  // Record the request for rate limiting (even if no papers found - prevents enumeration)
  await recordAuthorAccessRequest(env, email);
  
  // Always return success to prevent email enumeration attacks
  // But only actually send email if papers exist
  if (authorPapers.length > 0) {
    // Generate access token
    const accessToken = crypto.randomUUID();
    const expiresAt = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
    
    // Store token with paper list
    await env.SUBMISSIONS.put(`author-access:${accessToken}`, JSON.stringify({
      email: emailLower,
      papers: authorPapers,
      createdAt: new Date().toISOString(),
      expiresAt: expiresAt
    }), {
      expirationTtl: 24 * 60 * 60  // 24 hours
    });
    
    // Send email with access link
    await sendAuthorAccessEmail(env, email, authorPapers, accessToken);
  }
  
  // Always return same response (prevents email enumeration)
  return new Response(JSON.stringify({ 
    success: true,
    message: 'If you have published papers with this email, you will receive an access link shortly.'
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * Send author access email with link to manage papers
 */
async function sendAuthorAccessEmail(env, to, papers, accessToken) {
  const accessUrl = `https://ai-theoretical.org/api/author-access/page/${accessToken}`;
  
  const paperListHtml = papers.map(p => `
    <tr>
      <td style="padding:12px;border-bottom:1px solid #eee;">
        <strong>${p.title}</strong><br>
        <span style="color:#666;font-size:13px;">${TRACK_DISPLAY_NAMES[p.track] || p.track}</span>
      </td>
    </tr>
  `).join('');
  
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <div style="background:white;border-radius:12px;box-shadow:0 2px 10px rgba(0,0,0,0.1);padding:40px;">
      
      <h1 style="color:#1a1a1a;font-size:24px;margin:0 0 24px;text-align:center;">
        Manage Your Papers
      </h1>
      
      <p style="color:#333;font-size:16px;line-height:1.6;margin:0 0 24px;">
        You requested access to manage your papers on AI-Theoretical. Click the button below to:
      </p>
      
      <ul style="color:#333;font-size:15px;line-height:1.8;margin:0 0 24px;padding-left:20px;">
        <li>Withdraw a paper</li>
        <li>Submit a new version</li>
        <li>Change paper category</li>
      </ul>
      
      <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#666;font-size:14px;margin:0 0 12px;"><strong>Your papers:</strong></p>
        <table style="width:100%;border-collapse:collapse;">
          ${paperListHtml}
        </table>
      </div>
      
      <div style="text-align:center;margin:0 0 24px;">
        <a href="${accessUrl}" style="display:inline-block;background:#2563eb;color:white;padding:16px 48px;border-radius:8px;text-decoration:none;font-weight:600;font-size:16px;">
          Access Your Papers
        </a>
      </div>
      
      <p style="color:#666;font-size:14px;line-height:1.6;margin:0 0 8px;">
        Or copy and paste this link:
      </p>
      <p style="background:#f8f9fa;padding:12px;border-radius:6px;font-size:13px;color:#2563eb;word-break:break-all;margin:0 0 24px;">
        ${accessUrl}
      </p>
      
      <div style="background:#fff3cd;border:1px solid #ffc107;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#856404;font-size:14px;margin:0;">
          <strong>⏰ This link expires in 24 hours.</strong><br>
          If you did not request this, please ignore this email.
        </p>
      </div>
      
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      
      <p style="color:#999;font-size:12px;text-align:center;margin:0;">
        AI-Theoretical — A preprint server for AI-assisted theoretical writing<br>
        <a href="https://ai-theoretical.org" style="color:#2563eb;">ai-theoretical.org</a>
      </p>
      
    </div>
  </div>
</body>
</html>`;

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'AI-Theoretical <noreply@ai-theoretical.org>',
      to: [to],
      subject: 'Manage your papers on AI-Theoretical',
      html: emailHtml
    })
  });
}

/**
 * GET /api/author-access/page/:token
 * Mostra pagina HTML per gestire i paper dell'autore
 */
async function handleAuthorAccessPage(token, env) {
  // Recupera dati dal token
  const tokenData = await env.SUBMISSIONS.get(`author-access:${token}`);
  
  if (!tokenData) {
    return new Response(renderAuthorAccessPage(null, null, 'expired'), {
      status: 400,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  const data = JSON.parse(tokenData);
  
  // Verifica scadenza
  if (Date.now() > data.expiresAt) {
    return new Response(renderAuthorAccessPage(null, null, 'expired'), {
      status: 400,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  return new Response(renderAuthorAccessPage(data, token, 'valid'), {
    status: 200,
    headers: { 'Content-Type': 'text/html; charset=utf-8' }
  });
}

/**
 * Genera pagina HTML per gestione paper autore
 */
function renderAuthorAccessPage(data, accessToken, status) {
  if (status === 'expired') {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Link Expired — AI-Theoretical</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
      max-width: 440px;
      width: 100%;
      padding: 48px 40px;
      text-align: center;
    }
    .icon {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: #f44336;
      color: white;
      font-size: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
    }
    h1 { color: #1a1a1a; font-size: 24px; font-weight: 600; margin-bottom: 16px; }
    p { color: #666; font-size: 15px; line-height: 1.7; margin-bottom: 32px; }
    .btn {
      display: inline-block;
      background: #1a1a1a;
      color: white;
      padding: 14px 36px;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 500;
      font-size: 15px;
      transition: background 0.2s;
    }
    .btn:hover { background: #333; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">⏰</div>
    <h1>Link Expired</h1>
    <p>This access link has expired.<br><br>Access links are valid for <strong>24 hours</strong>.<br>Please request a new link.</p>
    <a href="https://ai-theoretical.org/author-access.html" class="btn">Request New Link</a>
  </div>
</body>
</html>`;
  }
  
  // Pagina valida con lista paper
  const paperCards = data.papers.map(p => `
    <div class="paper-card">
      <h3>${p.title}</h3>
      <div class="paper-meta">
        <span class="track">${TRACK_DISPLAY_NAMES[p.track] || p.track}</span>
        <span class="date">Submitted: ${new Date(p.submittedAt).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })}</span>
      </div>
      <div class="paper-actions">
        <button class="btn btn-secondary" onclick="showWithdrawModal('${p.id}', '${p.title.replace(/'/g, "\\'")}')">Withdraw Paper</button>
        <button class="btn btn-primary" onclick="showNewVersionModal('${p.id}', '${p.title.replace(/'/g, "\\'")}')">Submit New Version</button>
      </div>
    </div>
  `).join('');
  
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Manage Your Papers — AI-Theoretical</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: #f5f5f5;
      min-height: 100vh;
      padding: 40px 20px;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
    }
    header {
      background: white;
      border-radius: 12px;
      padding: 32px;
      margin-bottom: 24px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    header h1 {
      color: #1a1a1a;
      font-size: 28px;
      margin-bottom: 8px;
    }
    header p {
      color: #666;
      font-size: 15px;
    }
    .paper-card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 16px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .paper-card h3 {
      color: #1a1a1a;
      font-size: 18px;
      margin-bottom: 12px;
      line-height: 1.4;
    }
    .paper-meta {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }
    .paper-meta .track {
      background: #e3f2fd;
      color: #1565c0;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 13px;
      font-weight: 500;
    }
    .paper-meta .date {
      color: #666;
      font-size: 13px;
      display: flex;
      align-items: center;
    }
    .paper-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }
    .btn {
      padding: 10px 20px;
      border-radius: 6px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      border: none;
      transition: all 0.2s;
    }
    .btn-primary {
      background: #2563eb;
      color: white;
    }
    .btn-primary:hover {
      background: #1d4ed8;
    }
    .btn-secondary {
      background: white;
      color: #dc2626;
      border: 1px solid #dc2626;
    }
    .btn-secondary:hover {
      background: #fef2f2;
    }
    .warning-box {
      background: #fff3cd;
      border: 1px solid #ffc107;
      border-radius: 8px;
      padding: 16px;
      margin-top: 24px;
    }
    .warning-box p {
      color: #856404;
      font-size: 14px;
      margin: 0;
    }
    
    /* Modal styles */
    .modal-overlay {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.5);
      align-items: center;
      justify-content: center;
      z-index: 1000;
    }
    .modal-overlay.active {
      display: flex;
    }
    .modal {
      background: white;
      border-radius: 12px;
      padding: 32px;
      max-width: 500px;
      width: 90%;
      max-height: 90vh;
      overflow-y: auto;
    }
    .modal h2 {
      color: #1a1a1a;
      font-size: 20px;
      margin-bottom: 16px;
    }
    .modal p {
      color: #666;
      font-size: 15px;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .modal-actions {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
    }
    .btn-cancel {
      background: #f3f4f6;
      color: #374151;
    }
    .btn-cancel:hover {
      background: #e5e7eb;
    }
    .btn-danger {
      background: #dc2626;
      color: white;
    }
    .btn-danger:hover {
      background: #b91c1c;
    }
    .form-group {
      margin-bottom: 20px;
    }
    .form-group label {
      display: block;
      margin-bottom: 8px;
      font-weight: 500;
      color: #333;
    }
    .form-group select,
    .form-group input[type="file"] {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
    }
    .paper-title-ref {
      background: #f8f9fa;
      padding: 12px;
      border-radius: 6px;
      margin-bottom: 16px;
      font-weight: 500;
      color: #1a1a1a;
    }
    .status-message {
      padding: 12px;
      border-radius: 6px;
      margin-top: 16px;
      display: none;
    }
    .status-message.success {
      background: #d1fae5;
      color: #065f46;
      display: block;
    }
    .status-message.error {
      background: #fee2e2;
      color: #991b1b;
      display: block;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>Manage Your Papers</h1>
      <p>Select a paper below to withdraw it or submit a new version.</p>
    </header>
    
    ${paperCards}
    
    <div class="warning-box">
      <p><strong>⏰ This session expires in 24 hours.</strong> After that, you'll need to request a new access link.</p>
    </div>
  </div>
  
  <!-- Withdraw Modal -->
  <div class="modal-overlay" id="withdrawModal">
    <div class="modal">
      <h2>Withdraw Paper</h2>
      <div class="paper-title-ref" id="withdrawPaperTitle"></div>
      <p>Are you sure you want to withdraw this paper? This action will remove the paper from AI-Theoretical. This cannot be undone.</p>
      <div id="withdrawStatus" class="status-message"></div>
      <div class="modal-actions">
        <button class="btn btn-cancel" onclick="closeModal('withdrawModal')">Cancel</button>
        <button class="btn btn-danger" id="confirmWithdrawBtn" onclick="confirmWithdraw()">Withdraw Paper</button>
      </div>
    </div>
  </div>
  
  <!-- New Version Modal -->
  <div class="modal-overlay" id="newVersionModal">
    <div class="modal">
      <h2>Submit New Version</h2>
      <div class="paper-title-ref" id="newVersionPaperTitle"></div>
      <p>Upload a new version of your paper. The new version will replace the current one after review.</p>
      <form id="newVersionForm">
        <div class="form-group">
          <label for="newPdf">New PDF File</label>
          <input type="file" id="newPdf" accept=".pdf" required>
        </div>
        <div class="form-group">
          <label for="newTrack">Category (optional change)</label>
          <select id="newTrack">
            <option value="">Keep current category</option>
            <option value="researchPreprint">Research Preprint</option>
            <option value="workingPaper">Working Paper</option>
            <option value="expositoryEssay">Expository/Theoretical Essay</option>
            <option value="criticalReview">Critical Review</option>
          </select>
        </div>
      </form>
      <div id="newVersionStatus" class="status-message"></div>
      <div class="modal-actions">
        <button class="btn btn-cancel" onclick="closeModal('newVersionModal')">Cancel</button>
        <button class="btn btn-primary" id="confirmNewVersionBtn" onclick="confirmNewVersion()">Submit New Version</button>
      </div>
    </div>
  </div>
  
  <script>
    const ACCESS_TOKEN = '${accessToken}';
    let currentPaperId = null;
    let currentPaperTitle = null;
    
    function showWithdrawModal(paperId, paperTitle) {
      currentPaperId = paperId;
      currentPaperTitle = paperTitle;
      document.getElementById('withdrawPaperTitle').textContent = paperTitle;
      document.getElementById('withdrawStatus').className = 'status-message';
      document.getElementById('withdrawStatus').textContent = '';
      document.getElementById('confirmWithdrawBtn').disabled = false;
      document.getElementById('confirmWithdrawBtn').textContent = 'Withdraw Paper';
      document.getElementById('withdrawModal').classList.add('active');
    }
    
    function showNewVersionModal(paperId, paperTitle) {
      currentPaperId = paperId;
      currentPaperTitle = paperTitle;
      document.getElementById('newVersionPaperTitle').textContent = paperTitle;
      document.getElementById('newVersionStatus').className = 'status-message';
      document.getElementById('newVersionStatus').textContent = '';
      document.getElementById('newVersionForm').reset();
      document.getElementById('confirmNewVersionBtn').disabled = false;
      document.getElementById('confirmNewVersionBtn').textContent = 'Submit New Version';
      document.getElementById('newVersionModal').classList.add('active');
    }
    
    function closeModal(modalId) {
      document.getElementById(modalId).classList.remove('active');
      currentPaperId = null;
      currentPaperTitle = null;
    }
    
    async function confirmWithdraw() {
      const btn = document.getElementById('confirmWithdrawBtn');
      const status = document.getElementById('withdrawStatus');
      
      btn.disabled = true;
      btn.textContent = 'Processing...';
      status.className = 'status-message';
      status.textContent = '';
      
      try {
        const response = await fetch('https://ai-theoretical.org/api/author-access/withdraw', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            accessToken: ACCESS_TOKEN,
            paperId: currentPaperId
          })
        });
        
        const data = await response.json();
        
        if (data.success) {
          status.className = 'status-message success';
          status.textContent = 'Paper withdrawn successfully. You will receive a confirmation email.';
          btn.textContent = 'Done';
          // Remove the paper card from the page
          setTimeout(() => {
            location.reload();
          }, 2000);
        } else {
          status.className = 'status-message error';
          status.textContent = data.error || 'Failed to withdraw paper. Please try again.';
          btn.disabled = false;
          btn.textContent = 'Withdraw Paper';
        }
      } catch (err) {
        status.className = 'status-message error';
        status.textContent = 'Network error. Please check your connection and try again.';
        btn.disabled = false;
        btn.textContent = 'Withdraw Paper';
      }
    }
    
    async function confirmNewVersion() {
      const btn = document.getElementById('confirmNewVersionBtn');
      const status = document.getElementById('newVersionStatus');
      const pdfFile = document.getElementById('newPdf').files[0];
      const newTrack = document.getElementById('newTrack').value;
      
      if (!pdfFile) {
        status.className = 'status-message error';
        status.textContent = 'Please select a PDF file.';
        return;
      }
      
      btn.disabled = true;
      btn.textContent = 'Uploading...';
      status.className = 'status-message';
      status.textContent = '';
      
      try {
        const formData = new FormData();
        formData.append('accessToken', ACCESS_TOKEN);
        formData.append('paperId', currentPaperId);
        formData.append('pdf', pdfFile);
        if (newTrack) {
          formData.append('track', newTrack);
        }
        
        const response = await fetch('https://ai-theoretical.org/api/author-access/new-version', {
          method: 'POST',
          body: formData
        });
        
        const data = await response.json();
        
        if (data.success) {
          status.className = 'status-message success';
          status.textContent = data.message + ' You will receive a confirmation email.';
          btn.textContent = 'Done';
          setTimeout(() => {
            location.reload();
          }, 2000);
        } else {
          status.className = 'status-message error';
          status.textContent = data.error || 'Failed to submit new version. Please try again.';
          btn.disabled = false;
          btn.textContent = 'Submit New Version';
        }
      } catch (err) {
        status.className = 'status-message error';
        status.textContent = 'Network error. Please check your connection and try again.';
        btn.disabled = false;
        btn.textContent = 'Submit New Version';
      }
    }
    
    // Close modal on outside click
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
      overlay.addEventListener('click', (e) => {
        if (e.target === overlay) {
          overlay.classList.remove('active');
        }
      });
    });
    
    // Close modal on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        document.querySelectorAll('.modal-overlay.active').forEach(m => m.classList.remove('active'));
      }
    });
  </script>
</body>
</html>`;
}

/**
 * Valida token author-access e restituisce i dati
 * Returns: { valid: true, data: {...} } or { valid: false, error: string }
 */
async function validateAuthorAccessToken(env, accessToken) {
  if (!accessToken) {
    return { valid: false, error: 'Access token is required' };
  }
  
  const tokenData = await env.SUBMISSIONS.get(`author-access:${accessToken}`);
  if (!tokenData) {
    return { valid: false, error: 'Invalid or expired access token' };
  }
  
  const data = JSON.parse(tokenData);
  
  if (Date.now() > data.expiresAt) {
    return { valid: false, error: 'Access token has expired' };
  }
  
  return { valid: true, data };
}

/**
 * POST /api/author-access/withdraw
 * Body: { "accessToken": "...", "paperId": "..." }
 * 
 * Withdraws a paper (marks as withdrawn, removes from public listing)
 */
async function handleAuthorAccessWithdraw(request, env, corsHeaders) {
  const { accessToken, paperId } = await request.json();
  
  // Validate token
  const tokenCheck = await validateAuthorAccessToken(env, accessToken);
  if (!tokenCheck.valid) {
    return new Response(JSON.stringify({ success: false, error: tokenCheck.error }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Check if paperId is in the authorized list
  const authorizedPaperIds = tokenCheck.data.papers.map(p => p.id);
  if (!authorizedPaperIds.includes(paperId)) {
    return new Response(JSON.stringify({ success: false, error: 'Paper not found or not authorized' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Get the submission
  const submissionData = await env.SUBMISSIONS.get(paperId);
  if (!submissionData) {
    return new Response(JSON.stringify({ success: false, error: 'Paper not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(submissionData);
  
  // Check if already withdrawn
  if (submission.status === 'withdrawn') {
    return new Response(JSON.stringify({ success: false, error: 'Paper is already withdrawn' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Mark as withdrawn
  submission.status = 'withdrawn';
  submission.withdrawnAt = new Date().toISOString();
  submission.withdrawnBy = 'author';
  
  await env.SUBMISSIONS.put(paperId, JSON.stringify(submission));
  
  // Remove from index if present
  await removeFromIndex(env, paperId);
  
  // Notify Pharo to regenerate site (remove paper from homepage)
  await notifyPharoWithdraw(env, paperId);
  
  // Send confirmation email to author
  await sendWithdrawalConfirmationEmail(env, submission.authorEmail, submission.title);
  
  return new Response(JSON.stringify({ 
    success: true, 
    message: 'Paper has been withdrawn successfully'
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * Send withdrawal confirmation email
 */
async function sendWithdrawalConfirmationEmail(env, to, paperTitle) {
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <div style="background:white;border-radius:12px;box-shadow:0 2px 10px rgba(0,0,0,0.1);padding:40px;">
      
      <h1 style="color:#1a1a1a;font-size:24px;margin:0 0 24px;text-align:center;">
        Paper Withdrawn
      </h1>
      
      <p style="color:#333;font-size:16px;line-height:1.6;margin:0 0 24px;">
        Your paper has been successfully withdrawn from AI-Theoretical.
      </p>
      
      <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#666;font-size:14px;margin:0 0 4px;">Paper title:</p>
        <p style="color:#1a1a1a;font-size:16px;font-weight:600;margin:0;">${paperTitle}</p>
      </div>
      
      <p style="color:#666;font-size:14px;line-height:1.6;margin:0 0 24px;">
        The paper has been removed from public listing. If you have any questions, please contact us.
      </p>
      
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      
      <p style="color:#999;font-size:12px;text-align:center;margin:0;">
        AI-Theoretical — A preprint server for AI-assisted theoretical writing<br>
        <a href="https://ai-theoretical.org" style="color:#2563eb;">ai-theoretical.org</a>
      </p>
      
    </div>
  </div>
</body>
</html>`;

  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'AI-Theoretical <noreply@ai-theoretical.org>',
        to: [to],
        subject: `Paper withdrawn: ${paperTitle}`,
        html: emailHtml
      })
    });
  } catch (e) {
    console.error('Failed to send withdrawal confirmation email:', e);
  }
}

/**
 * POST /api/author-access/new-version
 * Body: multipart/form-data with accessToken, paperId, pdf, track (optional)
 * 
 * Submits a new version of an existing paper
 */
async function handleAuthorAccessNewVersion(request, env, corsHeaders) {
  const formData = await request.formData();
  
  const accessToken = formData.get('accessToken');
  const paperId = formData.get('paperId');
  const newTrack = formData.get('track');
  const pdfFile = formData.get('pdf');
  
  // Validate token
  const tokenCheck = await validateAuthorAccessToken(env, accessToken);
  if (!tokenCheck.valid) {
    return new Response(JSON.stringify({ success: false, error: tokenCheck.error }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Check if paperId is in the authorized list
  const authorizedPaperIds = tokenCheck.data.papers.map(p => p.id);
  if (!authorizedPaperIds.includes(paperId)) {
    return new Response(JSON.stringify({ success: false, error: 'Paper not found or not authorized' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Validate PDF
  if (!pdfFile || pdfFile.size === 0) {
    return new Response(JSON.stringify({ success: false, error: 'PDF file is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  if (!pdfFile.type.includes('pdf')) {
    return new Response(JSON.stringify({ success: false, error: 'File must be a PDF' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  if (pdfFile.size > 50 * 1024 * 1024) {
    return new Response(JSON.stringify({ success: false, error: 'PDF must be smaller than 50MB' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Validate track if provided
  if (newTrack && !VALID_TRACKS.includes(newTrack)) {
    return new Response(JSON.stringify({ 
      success: false, 
      error: `Invalid track. Must be one of: ${VALID_TRACKS.join(', ')}` 
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Get the original submission
  const submissionData = await env.SUBMISSIONS.get(paperId);
  if (!submissionData) {
    return new Response(JSON.stringify({ success: false, error: 'Paper not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(submissionData);
  
  // Check if paper is in a state that allows new versions
  if (submission.status === 'withdrawn') {
    return new Response(JSON.stringify({ success: false, error: 'Cannot submit new version of a withdrawn paper' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Calculate new version number
  const currentVersion = submission.version || 1;
  const newVersion = currentVersion + 1;
  
  // Store old PDF key for potential cleanup
  const oldPdfKey = submission.pdfKey;
  
  // Upload new PDF
  const newPdfKey = `submissions/${paperId}-v${newVersion}.pdf`;
  await env.PAPERS.put(newPdfKey, pdfFile.stream(), {
    httpMetadata: { contentType: 'application/pdf' }
  });
  
  // Update submission
  submission.pdfKey = newPdfKey;
  submission.version = newVersion;
  submission.versionHistory = submission.versionHistory || [];
  submission.versionHistory.push({
    version: currentVersion,
    pdfKey: oldPdfKey,
    replacedAt: new Date().toISOString()
  });
  submission.lastUpdatedAt = new Date().toISOString();
  
  // Update track if requested
  if (newTrack) {
    submission.previousTrack = submission.track;
    submission.track = newTrack;
  }
  
  // If paper was accepted, put it back to pending for review
  if (submission.status === 'accepted') {
    submission.previousStatus = 'accepted';
    submission.status = 'pending';
    submission.statusNote = 'New version submitted - awaiting review';
    await addToIndex(env, paperId);
  }
  
  await env.SUBMISSIONS.put(paperId, JSON.stringify(submission));
  
  // Notify Pharo to remove paper from site (goes back to pending)
  await notifyPharoNewVersion(env, paperId);
  
  // Send confirmation email
  await sendNewVersionConfirmationEmail(env, submission.authorEmail, submission.title, newVersion, newTrack);
  
  return new Response(JSON.stringify({ 
    success: true, 
    message: `New version (v${newVersion}) submitted successfully`,
    version: newVersion,
    status: submission.status
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * Send new version confirmation email
 */
async function sendNewVersionConfirmationEmail(env, to, paperTitle, version, newTrack) {
  const trackNote = newTrack 
    ? `<p style="color:#666;font-size:14px;margin:0;">Category changed to: <strong>${TRACK_DISPLAY_NAMES[newTrack] || newTrack}</strong></p>`
    : '';
  
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <div style="background:white;border-radius:12px;box-shadow:0 2px 10px rgba(0,0,0,0.1);padding:40px;">
      
      <h1 style="color:#1a1a1a;font-size:24px;margin:0 0 24px;text-align:center;">
        New Version Submitted
      </h1>
      
      <p style="color:#333;font-size:16px;line-height:1.6;margin:0 0 24px;">
        Your new version has been submitted and is now under review.
      </p>
      
      <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#666;font-size:14px;margin:0 0 4px;">Paper title:</p>
        <p style="color:#1a1a1a;font-size:16px;font-weight:600;margin:0 0 12px;">${paperTitle}</p>
        <p style="color:#666;font-size:14px;margin:0 0 4px;">Version:</p>
        <p style="color:#2563eb;font-size:16px;font-weight:600;margin:0;">v${version}</p>
        ${trackNote}
      </div>
      
      <p style="color:#666;font-size:14px;line-height:1.6;margin:0 0 24px;">
        You will receive an email when your new version has been reviewed.
      </p>
      
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      
      <p style="color:#999;font-size:12px;text-align:center;margin:0;">
        AI-Theoretical — A preprint server for AI-assisted theoretical writing<br>
        <a href="https://ai-theoretical.org" style="color:#2563eb;">ai-theoretical.org</a>
      </p>
      
    </div>
  </div>
</body>
</html>`;

  try {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'AI-Theoretical <noreply@ai-theoretical.org>',
        to: [to],
        subject: `New version submitted: ${paperTitle} (v${version})`,
        html: emailHtml
      })
    });
  } catch (e) {
    console.error('Failed to send new version confirmation email:', e);
  }
}

/**
 * Notify Pharo console that a paper was withdrawn
 * Pharo will remove the paper from the site and regenerate
 */
async function notifyPharoWithdraw(env, paperId) {
  try {
    const response = await fetch('https://console.ai-theoretical.org/api/notify-withdraw', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ paperId })
    });
    const result = await response.json();
    console.log('Pharo notify-withdraw result:', result);
  } catch (e) {
    // Don't fail the main operation if Pharo notification fails
    console.error('Failed to notify Pharo about withdrawal:', e);
  }
}

/**
 * Notify Pharo console that a new version was submitted
 * Pharo will remove the paper from the site (pending review)
 */
async function notifyPharoNewVersion(env, paperId) {
  try {
    const response = await fetch('https://console.ai-theoretical.org/api/notify-new-version', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ paperId })
    });
    const result = await response.json();
    console.log('Pharo notify-new-version result:', result);
  } catch (e) {
    // Don't fail the main operation if Pharo notification fails
    console.error('Failed to notify Pharo about new version:', e);
  }
}

// ============================================================================
// AUTHENTICATION
// ============================================================================

/**
 * Verifica autenticazione via header Authorization: Bearer <token>
 */
function isAuthenticated(request, env) {
  const auth = request.headers.get('Authorization');
  if (!auth || !auth.startsWith('Bearer ')) {
    return false;
  }
  const token = auth.slice(7);
  return token === env.API_TOKEN;
}

/**
 * Genera token casuale per conferma email
 */
function generateConfirmToken(length = 32) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  const randomValues = new Uint8Array(length);
  crypto.getRandomValues(randomValues);
  for (let i = 0; i < length; i++) {
    result += chars[randomValues[i] % chars.length];
  }
  return result;
}

// ============================================================================
// SUBMISSION HANDLING
// ============================================================================

/**
 * POST /api/submit
 * Riceve: multipart/form-data con campi + file PDF + file code (opzionale)
 */
async function handleSubmit(request, env, corsHeaders, clientIP) {
  const formData = await request.formData();
  
  // Validazione campi obbligatori
  const required = ['authorName', 'authorEmail', 'title', 'abstract', 'aiModels', 'track', 'acceptTerms'];
  for (const field of required) {
    if (!formData.get(field)) {
      return new Response(JSON.stringify({ error: `Missing required field: ${field}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
  
  // Valida track
  const track = formData.get('track');
  if (!VALID_TRACKS.includes(track)) {
    return new Response(JSON.stringify({ 
      error: `Invalid track. Must be one of: ${VALID_TRACKS.join(', ')}` 
    }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Verifica accettazione termini
  if (formData.get('acceptTerms') !== 'true') {
    return new Response(JSON.stringify({ error: 'Terms must be accepted' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Valida formato email
  const authorEmail = formData.get('authorEmail');
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(authorEmail)) {
    return new Response(JSON.stringify({ error: 'Invalid email format' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Genera ID univoco, paper token e confirm token
  const id = crypto.randomUUID();
  const paperToken = crypto.randomUUID().slice(0, 8);
  const confirmToken = generateConfirmToken(32);
  const submittedAt = new Date().toISOString();
  
  // Gestisci PDF
  let pdfKey = null;
  const pdfFile = formData.get('pdf');
  if (pdfFile && pdfFile.size > 0) {
    // Verifica che sia un PDF
    if (!pdfFile.type.includes('pdf')) {
      return new Response(JSON.stringify({ error: 'File must be a PDF' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Limite 50MB
    if (pdfFile.size > 50 * 1024 * 1024) {
      return new Response(JSON.stringify({ error: 'PDF must be smaller than 50MB' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Salva in R2
    pdfKey = `submissions/${id}.pdf`;
    await env.PAPERS.put(pdfKey, pdfFile.stream(), {
      httpMetadata: { contentType: 'application/pdf' }
    });
  }
  
  // Gestisci Code ZIP (opzionale)
  let codeZipKey = null;
  let hasCode = false;
  const codeFile = formData.get('code');
  if (codeFile && codeFile.size > 0) {
    // Verifica che sia un ZIP
    if (!codeFile.type.includes('zip') && !codeFile.name.endsWith('.zip')) {
      return new Response(JSON.stringify({ error: 'Code file must be a ZIP archive' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Limite 20MB per code
    if (codeFile.size > 20 * 1024 * 1024) {
      return new Response(JSON.stringify({ error: 'Code archive must be smaller than 20MB' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
    
    // Salva in R2
    codeZipKey = `submissions/${id}-code.zip`;
    await env.PAPERS.put(codeZipKey, codeFile.stream(), {
      httpMetadata: { contentType: 'application/zip' }
    });
    hasCode = true;
  }
  
  // Record submission for rate limiting AFTER validation but BEFORE saving
  // This way invalid submissions don't count against the limit
  await recordSubmission(env, clientIP);
  
  // Costruisci oggetto submission
  const submission = {
    id,
    paperToken,
    confirmToken,
    track,
    authorName: formData.get('authorName'),
    authorEmail: authorEmail,
    authorAffiliation: formData.get('authorAffiliation') || '',
    coAuthors: formData.get('coAuthors') || '',
    title: formData.get('title'),
    abstract: formData.get('abstract'),
    aiModels: formData.get('aiModels'),
    notes: formData.get('notes') || '',
    pdfKey,
    codeZipKey,
    hasCode,
    submittedAt,
    submittedFromIP: clientIP,  // Track IP for debugging
    status: 'unconfirmed'
  };
  
  // Salva in KV (ma NON nell'indice - solo dopo conferma)
  await env.SUBMISSIONS.put(id, JSON.stringify(submission));
  
  // Salva mapping token -> id con TTL 24 ore
  await env.SUBMISSIONS.put(`confirm:${confirmToken}`, id, { 
    expirationTtl: 24 * 60 * 60 
  });
  
  // Invia email di conferma
  const confirmUrl = `https://ai-theoretical.org/api/confirm/${confirmToken}`;
  await sendConfirmationEmail(env, authorEmail, formData.get('authorName'), formData.get('title'), track, confirmUrl);
  
  return new Response(JSON.stringify({ 
    success: true, 
    id,
    track,
    hasCode,
    requiresConfirmation: true,
    message: 'Please check your email to confirm your submission.'
  }), {
    status: 201,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * GET /api/confirm/:token
 * Conferma email e attiva la submission
 */
async function handleConfirm(token, env) {
  // Cerca submission ID dal token
  const submissionId = await env.SUBMISSIONS.get(`confirm:${token}`);
  
  if (!submissionId) {
    return new Response(renderConfirmPage(false, null, null, 'expired'), {
      status: 400,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  // Recupera submission
  const data = await env.SUBMISSIONS.get(submissionId);
  if (!data) {
    return new Response(renderConfirmPage(false, null, null, 'not_found'), {
      status: 404,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  const submission = JSON.parse(data);
  
  // Già confermata?
  if (submission.status !== 'unconfirmed') {
    return new Response(renderConfirmPage(true, submission.title, submission.track, 'already'), {
      status: 200,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  // Conferma: cambia status e aggiungi all'indice
  submission.status = 'pending';
  submission.confirmedAt = new Date().toISOString();
  delete submission.confirmToken;
  
  await env.SUBMISSIONS.put(submissionId, JSON.stringify(submission));
  await addToIndex(env, submissionId);
  
  // Elimina token di conferma
  await env.SUBMISSIONS.delete(`confirm:${token}`);
  
  return new Response(renderConfirmPage(true, submission.title, submission.track, 'success'), {
    status: 200,
    headers: { 'Content-Type': 'text/html; charset=utf-8' }
  });
}

/**
 * Genera pagina HTML di conferma (styled version from v4)
 */
function renderConfirmPage(success, title, track, reason) {
  const trackDisplay = track ? TRACK_DISPLAY_NAMES[track] || track : '';
  
  const messages = {
    success: {
      icon: '✓',
      title: 'Submission Confirmed!',
      body: `Your paper <strong>"${title}"</strong> has been confirmed and is now under review.<br><br>
             <span style="color:#666;font-size:14px;">Track: <strong>${trackDisplay}</strong></span><br><br>
             You will receive an email when a decision has been made.`,
      color: '#4CAF50'
    },
    already: {
      icon: 'ℹ',
      title: 'Already Confirmed',
      body: `Your paper <strong>"${title}"</strong> was already confirmed and is under review.`,
      color: '#2196F3'
    },
    expired: {
      icon: '⏰',
      title: 'Link Expired',
      body: 'This confirmation link has expired.<br><br>Confirmation links are valid for <strong>24 hours</strong>.<br>Please submit your paper again.',
      color: '#f44336'
    },
    not_found: {
      icon: '?',
      title: 'Not Found',
      body: 'We could not find a submission for this link.<br>It may have been deleted or the link is invalid.',
      color: '#f44336'
    }
  };
  
  const msg = messages[reason] || messages.not_found;
  
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${msg.title} — AI-Theoretical</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .card {
      background: white;
      border-radius: 16px;
      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
      max-width: 440px;
      width: 100%;
      padding: 48px 40px;
      text-align: center;
    }
    .icon {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: ${msg.color};
      color: white;
      font-size: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
    }
    h1 {
      color: #1a1a1a;
      font-size: 24px;
      font-weight: 600;
      margin-bottom: 16px;
    }
    p {
      color: #666;
      font-size: 15px;
      line-height: 1.7;
      margin-bottom: 32px;
    }
    .btn {
      display: inline-block;
      background: #1a1a1a;
      color: white;
      padding: 14px 36px;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 500;
      font-size: 15px;
      transition: background 0.2s;
    }
    .btn:hover { background: #333; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">${msg.icon}</div>
    <h1>${msg.title}</h1>
    <p>${msg.body}</p>
    <a href="https://ai-theoretical.org" class="btn">Go to AI-Theoretical</a>
  </div>
</body>
</html>`;
}

/**
 * Invia email di conferma via Resend (styled version from v4)
 */
async function sendConfirmationEmail(env, to, authorName, title, track, confirmUrl) {
  const trackDisplay = TRACK_DISPLAY_NAMES[track] || track;
  
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;">
  <div style="max-width:600px;margin:0 auto;padding:40px 20px;">
    <div style="background:white;border-radius:12px;box-shadow:0 2px 10px rgba(0,0,0,0.1);padding:40px;">
      
      <h1 style="color:#1a1a1a;font-size:24px;margin:0 0 24px;text-align:center;">
        Confirm Your Submission
      </h1>
      
      <p style="color:#333;font-size:16px;line-height:1.6;margin:0 0 16px;">
        Dear ${authorName},
      </p>
      
      <p style="color:#333;font-size:16px;line-height:1.6;margin:0 0 24px;">
        Thank you for submitting to AI-Theoretical. Please confirm your email address to complete your submission.
      </p>
      
      <div style="background:#f8f9fa;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#666;font-size:14px;margin:0 0 4px;">Paper title:</p>
        <p style="color:#1a1a1a;font-size:16px;font-weight:600;margin:0 0 12px;">${title}</p>
        <p style="color:#666;font-size:14px;margin:0 0 4px;">Submission track:</p>
        <p style="color:#2563eb;font-size:14px;font-weight:600;margin:0;">${trackDisplay}</p>
      </div>
      
      <div style="text-align:center;margin:0 0 24px;">
        <a href="${confirmUrl}" style="display:inline-block;background:#2563eb;color:white;padding:16px 48px;border-radius:8px;text-decoration:none;font-weight:600;font-size:16px;">
          Confirm Submission
        </a>
      </div>
      
      <p style="color:#666;font-size:14px;line-height:1.6;margin:0 0 8px;">
        Or copy and paste this link:
      </p>
      <p style="background:#f8f9fa;padding:12px;border-radius:6px;font-size:13px;color:#2563eb;word-break:break-all;margin:0 0 24px;">
        ${confirmUrl}
      </p>
      
      <div style="background:#fff3cd;border:1px solid #ffc107;border-radius:8px;padding:16px;margin:0 0 24px;">
        <p style="color:#856404;font-size:14px;margin:0;">
          <strong>⏰ This link expires in 24 hours.</strong><br>
          If you did not submit a paper, please ignore this email.
        </p>
      </div>
      
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;">
      
      <p style="color:#999;font-size:12px;text-align:center;margin:0;">
        AI-Theoretical — A preprint server for AI-assisted theoretical writing<br>
        <a href="https://ai-theoretical.org" style="color:#2563eb;">ai-theoretical.org</a>
      </p>
      
    </div>
  </div>
</body>
</html>`;

  await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: 'AI-Theoretical <noreply@ai-theoretical.org>',
      to: [to],
      subject: `Please confirm your submission: ${title}`,
      html: emailHtml
    })
  });
}

// ============================================================================
// LIST AND GET SUBMISSIONS
// ============================================================================

/**
 * GET /api/submissions
 * Restituisce tutte le submission pending (solo confermate)
 */
async function handleList(env, corsHeaders) {
  const index = await getIndex(env);
  const submissions = [];
  
  for (const id of index) {
    const data = await env.SUBMISSIONS.get(id);
    if (data) {
      const sub = JSON.parse(data);
      // Solo pending (confermate), non unconfirmed
      if (sub.status === 'pending') {
        submissions.push(sub);
      }
    }
  }
  
  return new Response(JSON.stringify(submissions), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * GET /api/submission/:id
 * Recupera singola submission con tutti i dettagli
 */
async function handleGet(id, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  return new Response(data, {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// ============================================================================
// FILE DOWNLOADS
// ============================================================================

/**
 * GET /api/submission/:id/pdf
 * Download PDF file
 */
async function handleDownloadPdf(id, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(data);
  
  if (!submission.pdfKey) {
    return new Response(JSON.stringify({ error: 'No PDF attached' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const pdfObject = await env.PAPERS.get(submission.pdfKey);
  
  if (!pdfObject) {
    return new Response(JSON.stringify({ error: 'PDF file not found in storage' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  return new Response(pdfObject.body, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${id}.pdf"`
    }
  });
}

/**
 * GET /api/submission/:id/code
 * Download code ZIP file
 */
async function handleDownloadCode(id, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(data);
  
  if (!submission.codeZipKey) {
    return new Response(JSON.stringify({ error: 'No code attached' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const codeObject = await env.PAPERS.get(submission.codeZipKey);
  
  if (!codeObject) {
    return new Response(JSON.stringify({ error: 'Code file not found in storage' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  return new Response(codeObject.body, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/zip',
      'Content-Disposition': `attachment; filename="${id}-code.zip"`
    }
  });
}

// ============================================================================
// STATUS AND DELETE
// ============================================================================

/**
 * POST /api/submission/:id/status
 * Body: { "status": "accepted" | "rejected" }
 */
async function handleStatusUpdate(id, request, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const body = await request.json();
  const newStatus = body.status;
  
  if (!['accepted', 'rejected', 'pending'].includes(newStatus)) {
    return new Response(JSON.stringify({ error: 'Invalid status' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(data);
  submission.status = newStatus;
  submission.statusUpdatedAt = new Date().toISOString();
  
  await env.SUBMISSIONS.put(id, JSON.stringify(submission));
  
  // Se non più pending, rimuovi dall'indice
  if (newStatus !== 'pending') {
    await removeFromIndex(env, id);
  }
  
  return new Response(JSON.stringify({ success: true, submission }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * DELETE /api/submission/:id
 */
async function handleDelete(id, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(data);
  
  // Elimina PDF da R2 se esiste
  if (submission.pdfKey) {
    await env.PAPERS.delete(submission.pdfKey);
  }
  
  // Elimina code ZIP da R2 se esiste
  if (submission.codeZipKey) {
    await env.PAPERS.delete(submission.codeZipKey);
  }
  
  // Elimina da KV
  await env.SUBMISSIONS.delete(id);
  
  // Rimuovi dall'indice
  await removeFromIndex(env, id);
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// ============================================================================
// EMAIL
// ============================================================================

/**
 * POST /api/send-email
 * Invia email via Resend
 * Body: { "to": "email", "subject": "...", "textBody": "...", "htmlBody": "..." }
 */
async function handleSendEmail(request, env, corsHeaders) {
  const { to, subject, textBody, htmlBody } = await request.json();
  
  if (!to || !subject || (!textBody && !htmlBody)) {
    return new Response(JSON.stringify({ error: 'Missing required fields: to, subject, and textBody or htmlBody' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const emailRequest = new Request('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.RESEND_API_KEY}`
    },
    body: JSON.stringify({
      to: [to],
      from: 'AI-Theoretical <noreply@ai-theoretical.org>',
      subject: subject,
      text: textBody || '',
      html: htmlBody || undefined
    })
  });
  
  const emailResponse = await fetch(emailRequest);
  
  if (emailResponse.ok) {
    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } else {
    const errorText = await emailResponse.text();
    return new Response(JSON.stringify({ 
      error: 'Email sending failed', 
      details: errorText,
      status: emailResponse.status
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
}

// ============================================================================
// TOKEN VERIFICATION
// ============================================================================

/**
 * POST /api/verify-token
 * Verifica email + paperToken per gestione paper
 * Body: { "email": "...", "paperToken": "..." }
 */
async function handleVerifyToken(request, env, corsHeaders) {
  const { email, paperToken } = await request.json();
  
  if (!email || !paperToken) {
    return new Response(JSON.stringify({ error: 'Missing email or paperToken' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Cerca tra tutte le submission (incluse le accettate)
  const allKeys = await env.SUBMISSIONS.list();
  
  for (const key of allKeys.keys) {
    if (key.name === '__index__') continue;
    if (key.name.startsWith('confirm:')) continue;
    if (key.name.startsWith('__rate_limit')) continue;
    if (key.name.startsWith('__author_access')) continue;
    if (key.name.startsWith('author-access:')) continue;
    
    const data = await env.SUBMISSIONS.get(key.name);
    if (data) {
      const sub = JSON.parse(data);
      if (sub.authorEmail === email && sub.paperToken === paperToken && sub.status === 'accepted') {
        // Genera token di conferma temporaneo
        const confirmToken = crypto.randomUUID();
        await env.SUBMISSIONS.put(`confirm:${confirmToken}`, JSON.stringify({
          submissionId: sub.id,
          action: 'manage',
          expires: Date.now() + 3600000 // 1 ora
        }), { expirationTtl: 3600 });
        
        return new Response(JSON.stringify({ 
          success: true,
          confirmToken,
          title: sub.title,
          track: sub.track,
          paperId: sub.id
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
    }
  }
  
  return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
    status: 401,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// ============================================================================
// INDEX MANAGEMENT
// ============================================================================

/**
 * Gestione indice delle submission pending
 * Usiamo una chiave speciale in KV per tenere la lista degli ID
 */
async function getIndex(env) {
  const data = await env.SUBMISSIONS.get('__index__');
  return data ? JSON.parse(data) : [];
}

async function addToIndex(env, id) {
  const index = await getIndex(env);
  if (!index.includes(id)) {
    index.push(id);
    await env.SUBMISSIONS.put('__index__', JSON.stringify(index));
  }
}

async function removeFromIndex(env, id) {
  const index = await getIndex(env);
  const newIndex = index.filter(i => i !== id);
  await env.SUBMISSIONS.put('__index__', JSON.stringify(newIndex));
}

