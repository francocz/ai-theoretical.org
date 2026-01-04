/**
 * AI-Theoretical Submission Worker
 * Version: 3.0
 * Updated: 2026-01-03
 * 
 * Endpoints:
 *   POST /api/submit              - Riceve nuova submission (pubblico) → status: unconfirmed
 *   GET  /api/confirm/:token      - Conferma email (pubblico) → status: pending
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
      
      // GET /api/confirm/:token - Conferma email (pubblico) - NUOVO
      const confirmMatch = path.match(/^\/api\/confirm\/([A-Za-z0-9]+)$/);
      if (confirmMatch && request.method === 'GET') {
        return await handleConfirm(confirmMatch[1], env);
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

/**
 * POST /api/submit
 * Riceve: multipart/form-data con campi + file PDF + file code (opzionale)
 * MODIFICATO: ora salva come "unconfirmed" e invia email di conferma
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
  
  // Costruisci oggetto submission - MODIFICATO: status = unconfirmed
  const submission = {
    id,
    paperToken,
    confirmToken,  // NUOVO
    authorName: formData.get('authorName'),
    authorEmail: authorEmail,
    authorAffiliation: formData.get('authorAffiliation') || '',
    title: formData.get('title'),
    abstract: formData.get('abstract'),
    aiModels: formData.get('aiModels'),
    notes: formData.get('notes') || '',
    pdfKey,
    codeZipKey,
    hasCode,
    submittedAt,
    status: 'unconfirmed'  // MODIFICATO: era 'pending'
  };
  
  // Salva in KV (ma NON nell'indice - solo dopo conferma)
  await env.SUBMISSIONS.put(id, JSON.stringify(submission));
  
  // Salva mapping token -> id con TTL 24 ore
  await env.SUBMISSIONS.put(`confirm:${confirmToken}`, id, { 
    expirationTtl: 24 * 60 * 60 
  });
  
  // Invia email di conferma
  const confirmUrl = `https://ai-theoretical.org/api/confirm/${confirmToken}`;
  await sendConfirmationEmail(env, authorEmail, formData.get('authorName'), formData.get('title'), confirmUrl);
  
  // MODIFICATO: risposta indica che serve conferma
  return new Response(JSON.stringify({ 
    success: true, 
    id,
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
 * NUOVO
 */
async function handleConfirm(token, env) {
  // Cerca submission ID dal token
  const submissionId = await env.SUBMISSIONS.get(`confirm:${token}`);
  
  if (!submissionId) {
    return new Response(renderConfirmPage(false, null, 'expired'), {
      status: 400,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  // Recupera submission
  const data = await env.SUBMISSIONS.get(submissionId);
  if (!data) {
    return new Response(renderConfirmPage(false, null, 'not_found'), {
      status: 404,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  }
  
  const submission = JSON.parse(data);
  
  // Già confermata?
  if (submission.status !== 'unconfirmed') {
    return new Response(renderConfirmPage(true, submission.title, 'already'), {
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
  
  return new Response(renderConfirmPage(true, submission.title, 'success'), {
    status: 200,
    headers: { 'Content-Type': 'text/html; charset=utf-8' }
  });
}

/**
 * Genera pagina HTML di conferma
 * NUOVO
 */
function renderConfirmPage(success, title, reason) {
  const messages = {
    success: {
      icon: '✓',
      title: 'Submission Confirmed!',
      body: `Your paper <strong>"${title}"</strong> has been confirmed and is now under review.<br><br>You will receive an email when a decision has been made.`,
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
  
  const msg = messages[reason];
  
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
 * Invia email di conferma via Resend
 * NUOVO
 */
async function sendConfirmationEmail(env, to, authorName, title, confirmUrl) {
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
        <p style="color:#1a1a1a;font-size:16px;font-weight:600;margin:0;">${title}</p>
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
