import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';
import { corsHeaders } from '../_shared/cors.ts';
import { errorResponse } from '../_shared/error.ts';
import { verifyFirebaseToken } from '../_shared/firebase_auth.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await verifyFirebaseToken(req.headers.get('Authorization'));
    const body = await req.json().catch(() => ({}));
    const { code } = body;

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Idempotency check: if user is already verified, return success
    const { data: existingVerif } = await supabase
      .from('email_verifications')
      .select('uid, verified_at')
      .eq('uid', user.uid)
      .maybeSingle();

    if (existingVerif && existingVerif.verified_at) {
      return new Response(
        JSON.stringify({ success: true, message: 'Already verified' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Auto-verify if user's token is already email_verified (e.g. Google Sign-In)
    if (user.email_verified && user.email) {
      await supabase.from('email_verifications').upsert({
        uid: user.uid,
        email: user.email,
        verified_at: new Date().toISOString(),
      }, { onConflict: 'uid' });

      return new Response(
        JSON.stringify({ success: true, message: 'OAuth verified successfully' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const cleanCode = typeof code === 'string' ? code.trim() : '';
    if (!cleanCode || cleanCode.length !== 6) {
      return errorResponse('Valid 6-digit code is required', 400, 'INVALID_CODE');
    }

    const { data: codes, error: fetchErr } = await supabase
      .from('otp_codes')
      .select('*')
      .eq('uid', user.uid)
      .eq('consumed', false)
      .order('created_at', { ascending: false })
      .limit(1);

    if (fetchErr || !codes || codes.length === 0) {
      return errorResponse('This code expired or was replaced: request a new one', 400, 'INVALID_OR_EXPIRED');
    }

    const record = codes[0];

    const now = new Date();
    const expiresAt = new Date(record.expires_at);
    if (now > expiresAt) {
      await supabase.from('otp_codes').update({ consumed: true }).eq('id', record.id);
      return errorResponse('This code expired or was replaced: request a new one', 400, 'INVALID_OR_EXPIRED');
    }

    if (record.attempts >= 5) {
      await supabase.from('otp_codes').update({ consumed: true }).eq('id', record.id);
      return errorResponse('Too many tries: request a new code', 400, 'MAX_ATTEMPTS');
    }

    const pepper = Deno.env.get('OTP_PEPPER') || 'linguacare-secure-pepper';
    const msgUint8 = new TextEncoder().encode(`${cleanCode}:${pepper}:${user.uid}`);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const inputHash = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');

    if (inputHash !== record.code_hash) {
      await supabase
        .from('otp_codes')
        .update({ attempts: record.attempts + 1 })
        .eq('id', record.id);
      return errorResponse("That code doesn't match", 400, 'INVALID_CODE');
    }

    await supabase.from('otp_codes').update({ consumed: true }).eq('id', record.id);

    const { error: upsertErr } = await supabase.from('email_verifications').upsert({
      uid: user.uid,
      email: record.email,
      verified_at: new Date().toISOString(),
    });

    if (upsertErr) {
      console.error('Email verification record error:', upsertErr);
      return errorResponse('Database error storing verification status', 500, 'DB_ERROR');
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Email verified successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Unhandled error in verify-otp:', err);
    const msg = (err as Error).message || '';
    if (msg.includes('Missing or invalid Authorization header') || msg.includes('Invalid or expired authentication token')) {
      return errorResponse(msg, 401, 'UNAUTHORIZED');
    }
    return errorResponse('An error occurred processing the request', 401, 'UNAUTHORIZED');
  }
});
