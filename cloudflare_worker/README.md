# ANHIRE AI Cloudflare Worker Deployment Guide

Worker Name: `anhire-ai`  
Worker URL: `https://anhire-ai.anandhuanil101225.workers.dev`

## Environment Variables / Secrets Required

1. **`GROQ_API_KEY`**: Secret key for Groq API (`https://api.groq.com/openai/v1/chat/completions`) using model `openai/gpt-oss-120b`.
2. **`FIREBASE_WEB_API_KEY`**: Web API key for verifying Firebase ID tokens via Google Identity Toolkit API.

## Deployment Options

### Option A: Cloudflare Dashboard Manual Update
1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Navigate to **Workers & Pages** -> select **`anhire-ai`**.
3. Click **Edit Code** or **Quick Edit**.
4. Copy and paste the entire contents of [`cloudflare_worker/index.js`](./index.js) into the Cloudflare Worker editor.
5. Click **Save and Deploy**.
6. Ensure secret environment variables `GROQ_API_KEY` and `FIREBASE_WEB_API_KEY` are configured under **Settings** -> **Variables**.

### Option B: Deploy using Wrangler CLI
```bash
cd cloudflare_worker
npx wrangler deploy
```

## Supported AI Operations
- `resume_analysis`
- `coding_hint`
- `aptitude_explanation`
- `aptitude_answer_generation` / `admin_batch_aptitude`
- `interview_question_generation`
- `interview_answer_evaluation`
- `roadmap_generation`
