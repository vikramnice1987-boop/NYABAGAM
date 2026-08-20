// Deploy with `supabase functions deploy ai-memory`.
// Required secret: OPENAI_API_KEY. Optional secret: OPENAI_MODEL (defaults to gpt-5).

const candidateSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['title', 'summary', 'people', 'things', 'events'],
  properties: {
    title: {type: 'string', description: 'A short neutral memory title.'},
    summary: {type: 'string', description: 'A concise factual summary. Do not invent details.'},
    people: {type: 'array', items: {type: 'string'}},
    things: {type: 'array', items: {type: 'string'}},
    events: {type: 'array', items: {type: 'string'}},
  },
};

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', {status: 405});
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) return Response.json({error: 'AI service is not configured.'}, {status: 503});

  const {operation, source_id: sourceId, content} = await request.json();
  if (operation !== 'understand' || typeof sourceId !== 'string' || typeof content !== 'string' || !content.trim()) {
    return Response.json({error: 'Invalid AI request.'}, {status: 400});
  }

  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json'},
    body: JSON.stringify({
      model: Deno.env.get('OPENAI_MODEL') ?? 'gpt-5',
      store: false,
      instructions: 'Extract only information explicitly present in the supplied capture. Never infer or invent facts. Return empty arrays when no entities apply.',
      input: `Untrusted user capture (source ${sourceId}):\n${content}`,
      text: {format: {type: 'json_schema', name: 'memory_candidate', strict: true, schema: candidateSchema}},
    }),
  });
  const payload = await response.json();
  if (!response.ok) return Response.json({error: 'AI request failed.'}, {status: response.status});

  try {
    return Response.json({candidate: JSON.parse(payload.output_text)}, {status: 200});
  } catch (_) {
    return Response.json({error: 'AI returned an invalid candidate.'}, {status: 502});
  }
});
