/**
 * AI-Theoretical Submission Worker
 * Version: 2.0
 * Updated: 2026-01-02
 * 
 * Endpoints:
 *   POST /api/submit              - Riceve nuova submission (pubblico)
 *   GET  /api/submissions         - Lista submission pending (protetto)
 *   GET  /api/submission/:id      - Singola submission (protetto)
 *   POST /api/submission/:id/status - Aggiorna status (protetto)
 *   DELETE /api/submission/:id    - Elimina submission (protetto)
 *   POST /api/send-email          - Invia email via Resend (protetto)
 *   POST /api/verify-token        - Verifica paper token per gestione (pubblico)
 *   GET  /api/submission/:id/pdf  - Download PDF (protetto)
 *   GET  /api/submission/:id/code - Download code ZIP (protetto)
 * 
 * Environment bindings richiesti:
 *   - SUBMISSIONS: KV namespace per i metadati
 *   - PAPERS: R2 bucket per i PDF e code
 *   - API_TOKEN: Secret per autenticazione
 *   - RESEND_API_KEY: Secret per Resend email
 */

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
      // POST /api/submit - Nuova submission (pubblico)
      if (path === '/api/submit' && request.method === 'POST') {
        return await handleSubmit(request, env, corsHeaders);
      }
      
      // POST /api/verify-token - Verifica token per gestione paper (pubblico)
      if (path === '/api/verify-token' && request.method === 'POST') {
        return await handleVerifyToken(request, env, corsHeaders);
      }
      
      // Tutti gli altri endpoint richiedono autenticazione
      if (!isAuthenticated(request, env)) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }
      
      // GET /api/submissions - Lista pending
      if (path === '/api/submissions' && request.method === 'GET') {
        return await handleList(env, corsHeaders);
      }
      
      // POST /api/send-email - Invia email (protetto)
      if (path === '/api/send-email' && request.method === 'POST') {
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
 * POST /api/submit
 * Riceve: multipart/form-data con campi + file PDF + file code (opzionale)
 */
async function handleSubmit(request, env, corsHeaders) {
  const formData = await request.formData();
  
  // Validazione campi obbligatori
  const required = ['authorName', 'authorEmail', 'title', 'abstract', 'aiModels', 'acceptTerms'];
  for (const field of required) {
    if (!formData.get(field)) {
      return new Response(JSON.stringify({ error: `Missing required field: ${field}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }
  }
  
  // Verifica accettazione termini
  if (formData.get('acceptTerms') !== 'true') {
    return new Response(JSON.stringify({ error: 'Terms must be accepted' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  // Genera ID univoco e paper token
  const id = crypto.randomUUID();
  const paperToken = crypto.randomUUID().slice(0, 8);
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
  
  // Costruisci oggetto submission
  const submission = {
    id,
    paperToken,
    authorName: formData.get('authorName'),
    authorEmail: formData.get('authorEmail'),
    authorAffiliation: formData.get('authorAffiliation') || '',
    title: formData.get('title'),
    abstract: formData.get('abstract'),
    aiModels: formData.get('aiModels'),
    notes: formData.get('notes') || '',
    pdfKey,
    codeZipKey,
    hasCode,
    submittedAt,
    status: 'pending'
  };
  
  // Salva in KV
  await env.SUBMISSIONS.put(id, JSON.stringify(submission));
  
  // Aggiungi all'indice delle pending
  await addToIndex(env, id);
  
  return new Response(JSON.stringify({ 
    success: true, 
    id,
    hasCode,
    message: 'Submission received. You will be contacted at ' + submission.authorEmail
  }), {
    status: 201,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * GET /api/submissions
 * Restituisce tutte le submission pending
 */
async function handleList(env, corsHeaders) {
  const index = await getIndex(env);
  const submissions = [];
  
  for (const id of index) {
    const data = await env.SUBMISSIONS.get(id);
    if (data) {
      submissions.push(JSON.parse(data));
    }
  }
  
  return new Response(JSON.stringify(submissions), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

/**
 * GET /api/submission/:id
 */
async function handleGet(id, env, corsHeaders) {
  const data = await env.SUBMISSIONS.get(id);
  
  if (!data) {
    return new Response(JSON.stringify({ error: 'Submission not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
  
  const submission = JSON.parse(data);
  
  // Se c'è un PDF, marca come disponibile
  if (submission.pdfKey) {
    const pdfObject = await env.PAPERS.head(submission.pdfKey);
    submission.hasPdf = !!pdfObject;
  }
  
  // Se c'è code, marca come disponibile
  if (submission.codeZipKey) {
    const codeObject = await env.PAPERS.head(submission.codeZipKey);
    submission.hasCode = !!codeObject;
  }
  
  return new Response(JSON.stringify(submission), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

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
