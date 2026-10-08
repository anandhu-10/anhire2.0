class AiPrompts {
  // ---------------------------------------------------------------------------
  // B1. RESUME ANALYSIS
  // ---------------------------------------------------------------------------
  static const String resumeAnalysisSystemRole =
      'You are an expert ATS analyser and resume reviewer used by campus recruiters.';

  static String buildResumeAnalysisPrompt(String resumeText, String targetRole) {
    return '''$resumeAnalysisSystemRole

Task: Analyze the provided candidate resume text for the target role: "$targetRole".

Key Guidelines & Constraints:
1. Synonym-aware keyword evaluation:
   - Flag a keyword as missing ONLY if NEITHER the exact term NOR a reasonable synonym/variant appears in the resume text.
   - For example: 'Model Deployment' is satisfied by 'deployed via Docker', 'served via FastAPI', 'containerized and deployed', 'hosted on AWS/GCP/Render'.
   - 'CI/CD' is satisfied by 'GitHub Actions', 'Jenkins pipeline', 'automated build & deployment pipeline'.
2. Score each section from 0 to 100 with a concise 1-line reason/feedback.
3. Overall score must reflect true ATS readiness (0 to 100).
4. Provide specific, actionable suggestions for improvement (avoid generic advice).

FEW-SHOT WORKED EXAMPLE:
Target Role: "Backend Engineer"
Sample Resume Text:
"Jane Doe. Email: jane@example.com. Experience: Built RESTful services in Go and PostgreSQL. Deployed applications on AWS using Docker containers. Implemented automated testing with GitHub Actions. Education: BS Computer Science, GPA 3.8."

Expected JSON Output Format:
{
  "overallScore": 88,
  "sections": [
    { "name": "Summary & Contact", "score": 90, "feedback": "Clear contact details provided." },
    { "name": "Work Experience", "score": 85, "feedback": "Solid REST API development with Go and PostgreSQL." },
    { "name": "Technical Skills", "score": 85, "feedback": "Good core tools listed (Go, Postgres, Docker, AWS)." },
    { "name": "Education", "score": 95, "feedback": "Degree and GPA formatted properly." }
  ],
  "missingKeywords": ["Redis", "gRPC", "Kubernetes"],
  "suggestions": [
    "Add quantified impact metrics (e.g. throughput, response times) to project descriptions.",
    "Mention caching solutions like Redis if applicable to your backend work."
  ]
}

Now analyze this Candidate Resume Text:
"""
$resumeText
"""

Return ONLY valid JSON matching the exact schema above.''';
  }

  // ---------------------------------------------------------------------------
  // B2. CODING HINT
  // ---------------------------------------------------------------------------
  static const String codingHintSystemRole =
      'You are a patient, encouraging coding mentor.';

  static String buildCodingHintPrompt({
    required String problemTitle,
    required String problemDescription,
    required String language,
    required String code,
    required String errorOutput,
  }) {
    return '''$codingHintSystemRole

Task: The student attempted the coding problem "$problemTitle" but their code failed. Provide ONE helpful hint explaining what might be wrong.

Constraints:
1. NEVER reveal the full solution or corrected code.
2. Keep the hint concise (under 120 words).
3. Point out the core concept and what boundary/test condition is failing.

FEW-SHOT EXAMPLES:

GOOD HINT (Correct approach):
Problem: "Two Sum"
Student error: IndexOutOfBoundsException at loop end
Output:
{
  "hint": "Check your loop bounds when iterating over the array. Notice how accessing `nums[i + 1]` when `i` is at the last index causes an out-of-bounds error. Try adjusting your loop condition to `i < nums.length - 1`."
}

BAD HINT (WRONG - Reveals solution code directly):
Output:
{
  "hint": "Change line 5 to `for (int i = 0; i < nums.length - 1; i++)` and return `new int[]{map.get(target - nums[i]), i}`."
}
(DO NOT give code solutions like the BAD hint above!)

Current Context:
Problem Title: "$problemTitle"
Problem Description:
$problemDescription

Student Code ($language):
```
$code
```

Error / Output:
```
$errorOutput
```

Return ONLY valid JSON with key "hint":
{
  "hint": "Your encouraging hint text here..."
}''';
  }

  // ---------------------------------------------------------------------------
  // B3. APTITUDE ANSWER + EXPLANATION
  // ---------------------------------------------------------------------------
  static const String aptitudeSolverSystemRole =
      'You are an expert aptitude question solver.';

  static String buildAptitudeAnswerPrompt({
    required String question,
    required List<String> options,
  }) {
    final optionsFormatted = options.asMap().entries.map((e) => 'Option ${e.key}: ${e.value}').join('\n');

    return '''$aptitudeSolverSystemRole

Task: Solve the aptitude question below and provide a clear step-by-step explanation.

Constraints:
1. "answerIndex" MUST be an integer from 0 to 3 corresponding exactly to the correct option index (0 for Option A, 1 for Option B, 2 for Option C, 3 for Option D).
2. "explanation" MUST walk through the mathematical/logical calculation step-by-step.

Question:
"$question"

Options:
$optionsFormatted

Return ONLY valid JSON in this format:
{
  "answerIndex": 0,
  "explanation": "Step 1: Calculate total work... Step 2: Divide by rate... Therefore Option A is correct."
}''';
  }

  // ---------------------------------------------------------------------------
  // B4. INTERVIEW QUESTION GENERATION
  // ---------------------------------------------------------------------------
  static String buildInterviewQuestionGenPrompt(String role, String company) {
    return '''You are an expert interviewer at "$company".

Task: Generate 6 realistic interview questions for a candidate applying for the role: "$role".

Question Distribution Required:
- 2 Technical (DSA, coding concepts, domain architecture)
- 2 Behavioral (leadership, teamwork, conflict resolution)
- 1 HR (career goals, company values, self-awareness)
- 1 Situational (production outage, changing requirements, prioritization)

Constraints:
1. Each question must include 3-5 expectedKeywords (core technical/behavioral concepts).
2. Questions must be tailored to "$role" at "$company".

Return ONLY valid JSON matching this schema:
{
  "questions": [
    {
      "id": "q1",
      "type": "technical",
      "question": "How do memory management and garbage collection work in high-concurrency applications?",
      "expectedKeywords": ["heap", "stack", "garbage collection", "memory leaks", "allocation"]
    },
    {
      "id": "q2",
      "type": "technical",
      "question": "Explain the trade-offs between monolithic and microservice architectures.",
      "expectedKeywords": ["scalability", "decoupling", "latency", "deployment", "IPC"]
    },
    {
      "id": "q3",
      "type": "behavioral",
      "question": "Describe a scenario where you disagreed with a senior developer's technical design. How did you handle it?",
      "expectedKeywords": ["communication", "data-driven", "empathy", "compromise"]
    },
    {
      "id": "q4",
      "type": "behavioral",
      "question": "Tell me about a project where you missed a major deadline. What was the root cause and what did you learn?",
      "expectedKeywords": ["ownership", "transparency", "estimation", "retrospective"]
    },
    {
      "id": "q5",
      "type": "hr",
      "question": "Why do you want to join $company specifically as a $role?",
      "expectedKeywords": ["company mission", "growth", "skills alignment", "passion"]
    },
    {
      "id": "q6",
      "type": "situational",
      "question": "A critical security flaw is detected in production 15 minutes before a holiday weekend. What steps do you take?",
      "expectedKeywords": ["incident triage", "rollback", "patching", "stakeholder communication"]
    }
  ]
}''';
  }

  // ---------------------------------------------------------------------------
  // B5. INTERVIEW ANSWER EVALUATION
  // ---------------------------------------------------------------------------
  static String buildInterviewAnswerEvalPrompt({
    required String question,
    required String answer,
    required String expectedKeywords,
    required String questionType,
  }) {
    return '''You are a strict but fair interview evaluator assessing a candidate's response to this $questionType question.

Question: "$question"
Candidate's Answer: "$answer"
Expected keywords/concepts (OPTIONAL reference guide): "$expectedKeywords"

EVALUATION & RELEVANCE RULES:
1. Determine if the response is VALID and ON-TOPIC:
   - "on_topic": The response attempts to answer the question using real English words and relevant concepts (even if brief, definitional, or paraphrased without using exact keywords).
   - "off_topic": The response is fluent English but about a completely different topic (e.g. recipes, sports, casual chat, tea/cooking instructions).
   - "not_an_answer": The response is random character streams, gibberish, letter-soup, keyboard mash, or nonsensical noise.

2. KEYWORD USAGE RULE (SOFT SIGNAL ONLY):
   - Expected keywords are a SOFT SIGNAL for correctness, NOT a requirement for validity!
   - DO NOT mark an answer invalid just because it omits expected keywords.
   - An answer that accurately defines or explains the concept in plain English WITHOUT mentioning expected keywords is VALID and should receive a normal passing score (e.g. correctness 5-7/10, overall 60-75/100).
   - Answers referencing 2+ expected keywords receive higher correctness scores (8-10/10).

3. EXPLICIT FEW-SHOT EXAMPLES (STUDY ALL FOUR CASES):

Example 1 — VALID (definitional response, NO exact keywords present):
Question: "Explain the difference between process and thread in OS"
Answer: "A process is a program in execution. A thread is the smallest unit of execution within a process."
Output:
{
  "valid": true,
  "relevance": "on_topic",
  "clarityScore": 8,
  "correctnessScore": 7,
  "confidenceScore": 7,
  "overallScore": 72,
  "feedback": "Accurate basic definitions of process and thread.",
  "strengths": ["Clear definition of process and thread"],
  "improvements": ["Mention memory sharing or context switching trade-offs."]
}

Example 2 — VALID (keyword-rich, higher correctness):
Question: "Explain the difference between process and thread in OS"
Answer: "Processes have separate memory space, so a context switch is expensive; threads share memory and switch faster, enabling concurrency and easier IPC."
Output:
{
  "valid": true,
  "relevance": "on_topic",
  "clarityScore": 9,
  "correctnessScore": 9,
  "confidenceScore": 9,
  "overallScore": 90,
  "feedback": "Excellent explanation covering key technical trade-offs.",
  "strengths": ["Detailed comparison of memory isolation", "Addressed concurrency and IPC"],
  "improvements": ["Consider elaborating on kernel vs user threads."]
}

Example 3 — INVALID (gibberish):
Question: "Explain the difference between process and thread in OS"
Answer: "chcfggfggfghgfh hfh gjhg jgfigh jgj ghjgfhj jghj jf"
Output:
{
  "valid": false,
  "relevance": "not_an_answer",
  "clarityScore": 0,
  "correctnessScore": 0,
  "confidenceScore": 0,
  "overallScore": 0,
  "feedback": "This answer is not a valid, on-topic response to the question.",
  "strengths": [],
  "improvements": ["Write a meaningful response to the question."]
}

Example 4 — INVALID (off-topic recipe):
Question: "Explain the difference between process and thread in OS"
Answer: "To make tea, boil water and add leaves."
Output:
{
  "valid": false,
  "relevance": "off_topic",
  "clarityScore": 0,
  "correctnessScore": 0,
  "confidenceScore": 0,
  "overallScore": 0,
  "feedback": "This answer is not a valid, on-topic response to the question.",
  "strengths": [],
  "improvements": ["Provide a response relevant to operating systems."]
}

Return ONLY valid JSON matching this schema:
{
  "valid": true,
  "relevance": "on_topic",
  "clarityScore": 8,
  "correctnessScore": 7,
  "confidenceScore": 7,
  "overallScore": 72,
  "feedback": "Accurate explanation of the core concept.",
  "strengths": ["Clear explanation"],
  "improvements": ["Include more technical details"]
}''';
  }

  // ---------------------------------------------------------------------------
  // B6. LEARNING ROADMAP
  // ---------------------------------------------------------------------------
  static String buildLearningRoadmapPrompt({
    required String role,
    required String companies,
    required int resumeScore,
    required int codingSolved,
    required double aptitudeAccuracy,
    required int interviewAvg,
    required String weakestArea,
  }) {
    return '''You are a strategic placement coach creating a personalized study plan for a student.

Candidate Profile & Performance Data:
- Target Role: $role
- Target Companies: $companies
- Resume ATS Score: $resumeScore/100
- Coding Problems Solved: $codingSolved/30
- Aptitude Test Accuracy: ${aptitudeAccuracy.toStringAsFixed(1)}%
- Mock Interview Average: $interviewAvg/100
- Primary Weakest Area: $weakestArea

Task: Generate a structured 4 to 8 week learning roadmap tailored specifically to address the candidate's weakest area ($weakestArea).

Constraints:
1. Provide between 4 and 8 weeks of milestone plans.
2. Each week must contain:
   - "weekNumber": int (1 to 8)
   - "focus": high-level objective string
   - "topics": list of specific technical/analytical concepts
   - "tasks": list of 3-4 concrete, actionable practice tasks

Return ONLY valid JSON matching this schema:
{
  "weeks": [
    {
      "weekNumber": 1,
      "focus": "Core DSA & Data Structure Foundations",
      "topics": ["Arrays", "HashMaps", "Two Pointers"],
      "tasks": [
        "Solve Two Sum & Valid Anagram on Coding Playground",
        "Practice 5 Array problems focusing on time complexity",
        "Review HashMap collision resolution mechanisms"
      ]
    },
    {
      "weekNumber": 2,
      "focus": "Advanced Problem Solving & System Fundamentals",
      "topics": ["Linked Lists", "Trees", "BFS/DFS"],
      "tasks": [
        "Implement Tree Traversal algorithms from scratch",
        "Complete 1 mock technical interview session",
        "Solve 5 Medium-level LeetCode style questions"
      ]
    }
  ]
}''';
  }

  // ---------------------------------------------------------------------------
  // B7. ADMIN BATCH APTITUDE GENERATION
  // ---------------------------------------------------------------------------
  static String buildAdminBatchAptitudePrompt(String rawQuestionsText) {
    return '''You are an expert aptitude content generator.

Task: For each raw aptitude question below, identify the correct option index (0 for Option A, 1 for Option B, 2 for Option C, 3 for Option D) and write a step-by-step mathematical/logical explanation.

Raw Questions Data:
$rawQuestionsText

Return ONLY a valid JSON object containing an "items" array:
{
  "items": [
    {
      "questionIndex": 0,
      "answerIndex": 1,
      "explanation": "Detailed step-by-step solution here..."
    }
  ]
}''';
  }
}
