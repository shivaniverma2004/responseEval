import "@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type AITask =
  | "explain_word"
  | "simplify_text"
  | "summarize_text"
  | "generate_quiz"
  | "explain_grammar";

type AIRequest = {
  task: AITask;
  word?: string;
  text?: string;
  sentence?: string;
  level?: "beginner" | "intermediate" | "advanced";
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const apiKey = Deno.env.get("OPENAI_API_KEY");

    if (!apiKey) {
      return jsonResponse(
        { error: "OPENAI_API_KEY is not configured in Supabase secrets." },
        500
      );
    }

    const body = (await req.json()) as AIRequest;
    const level = body.level ?? "beginner";
    const prompt = buildPrompt(body, level);

    const openAIResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-5-mini",
        instructions:
          "You are SpeakEasy, a friendly English-learning tutor. Keep answers clear, concise, practical, and appropriate for the learner level. Avoid long paragraphs unless the user asks for details.",
        input: prompt,
      }),
    });

    const data = await openAIResponse.json();

    if (!openAIResponse.ok) {
      return jsonResponse(
        {
          error: "OpenAI request failed.",
          details: data,
        },
        openAIResponse.status
      );
    }

    const outputText =
      data.output_text ??
      data.output
        ?.flatMap((item: { content?: Array<{ text?: string }> }) => item.content ?? [])
        ?.map((content: { text?: string }) => content.text ?? "")
        ?.join("")
        ?.trim();

    if (!outputText) {
      return jsonResponse({ error: "OpenAI returned an empty response." }, 502);
    }

    return jsonResponse({ result: outputText });
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : "Unexpected server error.",
      },
      500
    );
  }
});

function buildPrompt(body: AIRequest, level: string): string {
  switch (body.task) {
    case "explain_word":
      if (!body.word) throw new Error("Missing word.");
      return `
Explain the English word "${body.word}" for a ${level} learner.

Return:
- Short meaning
- Simple example sentence
- 2 synonyms if useful
- Common mistake or usage tip if useful

Keep it brief.
`.trim();

    case "simplify_text":
      if (!body.text) throw new Error("Missing text.");
      return `
Simplify this text for a ${level} English learner.
Keep the original meaning.

Text:
${body.text}
`.trim();

    case "summarize_text":
      if (!body.text) throw new Error("Missing text.");
      return `
Summarize this text for a ${level} English learner.

Return:
- One sentence summary
- 3 key points

Text:
${body.text}
`.trim();

    case "generate_quiz":
      if (!body.text) throw new Error("Missing text.");
      return `
Create a short English-learning quiz from this text for a ${level} learner.

Return:
- 5 multiple-choice questions
- 4 options each
- answer key at the end

Text:
${body.text}
`.trim();

    case "explain_grammar":
      if (!body.sentence && !body.text) throw new Error("Missing sentence or text.");
      return `
Explain the grammar in this sentence/text for a ${level} English learner.

Focus on:
- tense
- sentence structure
- useful phrases
- one corrected or simplified version if needed

Text:
${body.sentence ?? body.text}
`.trim();

    default:
      throw new Error("Unsupported AI task.");
  }
}

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
