import { corsHeaders } from './cors.ts';

export function errorResponse(message: string, status = 400, code = 'BAD_REQUEST') {
  return new Response(
    JSON.stringify({ error: { code, message } }),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
