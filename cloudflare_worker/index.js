/**
 * ANHIRE Cloudflare Worker - AI Proxy for Groq
 * Worker Name: anhire-ai
 * Worker URL: https://anhire-ai.anandhuanil101225.workers.dev
 *
 * Supported AI Operations for ANHIRE Flutter Application:
 * 1. resume_analysis
 * 2. coding_hint
 * 3. aptitude_explanation
 * 4. aptitude_answer_generation / admin_batch_aptitude
 * 5. interview_question_generation
 * 6. interview_answer_evaluation
 * 7. roadmap_generation
 */

const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "openai/gpt-oss-120b";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// -----------------------------------------------------------------------------
// 1. Firebase Token Verification
// -----------------------------------------------------------------------------
async function verifyFirebaseToken(request, firebaseWebApiKey) {
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { valid: false, error: "Missing or malformed Authorization header" };
  }

  const token = authHeader.substring(7).trim();
  if (!token) {
    return { valid: false, error: "Empty Bearer token" };
  }

  if (!firebaseWebApiKey) {
    console.warn("FIREBASE_WEB_API_KEY binding not found. Skipping token verification for testing.");
    return { valid: true, uid: "unverified" };
  }

  try {
    const response = await fetch(
      `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${firebaseWebApiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken: token }),
      }
    );

    if (!response.ok) {
      const errText = await response.text();
      return { valid: false, error: `Invalid or expired Firebase ID token: ${errText}` };
    }

    const data = await response.json();
    if (data.users && data.users.length > 0) {
      return { valid: true, uid: data.users[0].localId, email: data.users[0].email };
    } else {
      return { valid: false, error: "User not found for provided Firebase token" };
    }
  } catch (err) {
    return { valid: false, error: `Firebase token validation failed: ${err.message}` };
  }
}

// -----------------------------------------------------------------------------
// 2. Helper: Call Groq API
// -----------------------------------------------------------------------------
async function callGroq({ groqApiKey, systemPrompt, userPrompt, temperature = 0.2, maxTokens = 2048 }) {
  if (!groqApiKey) {
    throw new Error("GROQ_API_KEY environment secret is not configured in Cloudflare Worker.");
  }

  const payload = {
    model: GROQ_MODEL,
    messages: [
      { role: "system", content: systemPrompt },
      { role: "user", content: userPrompt },
    ],
    temperature: temperature,
    max_tokens: maxTokens,
    response_format: { type: "json_object" },
  };

  const response = await fetch(GROQ_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${groqApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Groq API returned status ${response.status}: ${errorBody}`);
  }

  const data = await response.json();
  const rawContent = data.choices?.[0]?.message?.content || "{}";

  // Clean JSON response (strip markdown fences if present)
  let cleanJson = rawContent.trim();
  if (cleanJson.startsWith("```json")) {
    cleanJson = cleanJson.substring(7);
  } else if (cleanJson.startsWith("```")) {
    cleanJson = cleanJson.substring(3);
  }
  if (cleanJson.endsWith("```")) {
    cleanJson = cleanJson.substring(0, cleanJson.length - 3);
  }
  cleanJson = cleanJson.trim();

  return JSON.parse(cleanJson);
}

// -----------------------------------------------------------------------------
// 3. Operation Handlers & Prompts
// -----------------------------------------------------------------------------
async function handleOperation(operation, payload, groqApiKey) {
  switch (operation) {
    case "resume_analysis": {
      const { resumeText = "", targetRole = "Software Engineer" } = payload;
      if (!resumeText) throw new Error("Missing resumeText in payload.");

      const systemPrompt = "You are an expert ATS analyser and resume reviewer used by campus recruiters.";
      const userPrompt = `Task: Analyze the provided candidate resume text for target role: "${targetRole}".
Return ONLY valid JSON matching this schema:
{
  "overallScore": 88,
  "sections": [
    { "name": "Summary & Contact", "score": 90, "feedback": "Clear contact details provided." },
    { "name": "Work Experience", "score": 85, "feedback": "Solid REST API development." },
    { "name": "Technical Skills", "score": 85, "feedback": "Good core tools listed." },
    { "name": "Education", "score": 95, "feedback": "Degree formatted properly." }
  ],
  "missingKeywords": ["Docker", "Kubernetes"],
  "suggestions": ["Include quantified impact metrics in project descriptions."]
}

Resume Text:
"""
${resumeText}
"""`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 2048,
      });
    }

    case "coding_hint": {
      const { problemTitle = "", problemDescription = "", language = "python", code = "", errorOutput = "" } = payload;

      const systemPrompt = "You are a patient, encouraging coding mentor.";
      const userPrompt = `Task: Provide ONE helpful hint explaining what might be wrong in candidate's code.
NEVER reveal the full solution or corrected code. Keep hint concise under 120 words.
Return ONLY valid JSON:
{
  "hint": "Encouraging hint text here..."
}

Problem Title: "${problemTitle}"
Description: ${problemDescription}
Language: ${language}
Code:
\`\`\`
${code}
\`\`\`
Error / Test Output:
\`\`\`
${errorOutput}
\`\`\``;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.5,
        maxTokens: 512,
      });
    }

    case "aptitude_explanation": {
      const { question = "", options = [] } = payload;
      const optionsFormatted = options.map((opt, i) => `Option ${i}: ${opt}`).join("\n");

      const systemPrompt = "You are an expert aptitude question solver.";
      const userPrompt = `Task: Solve the aptitude question below and provide a clear step-by-step explanation.
Return ONLY valid JSON:
{
  "answerIndex": 0,
  "explanation": "Step-by-step solution..."
}

Question: "${question}"
Options:
${optionsFormatted}`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 1024,
      });
    }

    case "admin_batch_aptitude":
    case "aptitude_answer_generation": {
      const { rawQuestionsText = "" } = payload;

      const systemPrompt = "You are an expert aptitude content generator.";
      const userPrompt = `Task: For each raw aptitude question below, identify correct option index (0-3) and step-by-step explanation.
Return ONLY valid JSON:
{
  "items": [
    {
      "questionIndex": 0,
      "answerIndex": 1,
      "explanation": "Detailed solution..."
    }
  ]
}

Raw Questions Data:
${rawQuestionsText}`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 4096,
      });
    }

    case "interview_question_generation": {
      const { role = "Software Engineer", company = "Tech Company" } = payload;

      const systemPrompt = `You are an expert interviewer at "${company}".`;
      const userPrompt = `Generate 6 realistic interview questions for a candidate applying for the role: "${role}".
Question Distribution Required:
- 2 Technical
- 2 Behavioral
- 1 HR
- 1 Situational

Return ONLY valid JSON matching schema:
{
  "questions": [
    {
      "id": "q1",
      "type": "technical",
      "question": "Question text...",
      "expectedKeywords": ["keyword1", "keyword2"]
    }
  ]
}`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.7,
        maxTokens: 2048,
      });
    }

    case "interview_answer_evaluation": {
      const { question = "", answer = "", expectedKeywords = "", questionType = "technical" } = payload;

      const systemPrompt = "You are a strict but fair interview evaluator assessing a candidate's response.";
      const userPrompt = `Question (${questionType}): "${question}"
Candidate's Answer: "${answer}"
Expected keywords/concepts reference: "${expectedKeywords}"

EVALUATION RULES:
1. Determine validity: "on_topic", "off_topic", or "not_an_answer".
2. If invalid (gibberish/off_topic), valid: false, scores: 0.
3. If valid, score clarityScore (0-10), correctnessScore (0-10), confidenceScore (0-10 based on text structure and tone), overallScore (0-100), feedback, strengths, improvements.

Return ONLY valid JSON matching schema:
{
  "valid": true,
  "relevance": "on_topic",
  "clarityScore": 8,
  "correctnessScore": 7,
  "confidenceScore": 7,
  "overallScore": 72,
  "feedback": "Feedback text...",
  "strengths": ["Strength 1"],
  "improvements": ["Improvement 1"]
}`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.2,
        maxTokens: 1024,
      });
    }

    case "roadmap_generation": {
      const {
        role = "Software Engineer",
        companies = "Tech Companies",
        resumeScore = 80,
        codingSolved = 10,
        aptitudeAccuracy = 75,
        interviewAvg = 80,
        weakestArea = "Algorithms",
      } = payload;

      const systemPrompt = "You are a strategic placement coach creating a personalized study plan for a student.";
      const userPrompt = `Candidate Profile:
- Target Role: ${role}
- Target Companies: ${companies}
- Resume Score: ${resumeScore}/100
- Coding Solved: ${codingSolved}/30
- Aptitude Accuracy: ${aptitudeAccuracy}%
- Mock Interview Avg: ${interviewAvg}/100
- Weakest Area: ${weakestArea}

Task: Generate a 4 to 8 week learning roadmap.
Return ONLY valid JSON matching schema:
{
  "weeks": [
    {
      "weekNumber": 1,
      "focus": "Focus title",
      "topics": ["Topic 1", "Topic 2"],
      "tasks": ["Task 1", "Task 2"]
    }
  ]
}`;

      return await callGroq({
        groqApiKey,
        systemPrompt,
        userPrompt,
        temperature: 0.7,
        maxTokens: 3072,
      });
    }

    default:
      throw new Error(`Unsupported AI operation: "${operation}"`);
  }
}

// -----------------------------------------------------------------------------
// 4. Main Worker Fetch Handler
// -----------------------------------------------------------------------------
export default {
  async fetch(request, env, ctx) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed. Use POST." }),
        { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    try {
      // 1. Verify Firebase Auth ID Token
      const authResult = await verifyFirebaseToken(request, env.FIREBASE_WEB_API_KEY);
      if (!authResult.valid) {
        return new Response(
          JSON.stringify({ error: authResult.error }),
          { status: 401, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }

      // 2. Parse payload & size check
      const textBody = await request.text();
      if (textBody.length > 100 * 1024) {
        return new Response(
          JSON.stringify({ error: "Payload size limit exceeded (max 100KB)." }),
          { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }

      const body = JSON.parse(textBody || "{}");

      // Backward compatibility check for legacy callers
      let operation = body.operation;
      let payload = body.payload || body;
      if (!operation && body.question && body.answer) {
        operation = "interview_answer_evaluation";
        payload = body;
      }

      if (!operation) {
        return new Response(
          JSON.stringify({ error: "Missing required 'operation' parameter in request body." }),
          { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }

      // 3. Execute requested AI Operation via Groq
      const resultJson = await handleOperation(operation, payload, env.GROQ_API_KEY);

      return new Response(
        JSON.stringify(resultJson),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    } catch (err) {
      console.error("Worker error handling request:", err);
      return new Response(
        JSON.stringify({ error: err.message || "Internal Worker processing error." }),
        { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }
  },
};
