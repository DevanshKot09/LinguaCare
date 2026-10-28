import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { errorResponse } from '../_shared/error.ts';
import { verifyFirebaseToken } from '../_shared/firebase_auth.ts';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.2';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await verifyFirebaseToken(req.headers.get('Authorization'));
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      return errorResponse('Server configuration error', 500, 'CONFIG_ERROR');
    }

    const sa = JSON.parse(serviceAccountJson);
    const privateKeyPem = sa.private_key;
    const clientEmail = sa.client_email;
    const projectId = sa.project_id || Deno.env.get('FIREBASE_PROJECT_ID');

    const privateKey = await importPKCS8(privateKeyPem, 'RS256');
    const now = Math.floor(Date.now() / 1000);
    const jwt = await new SignJWT({
      scope: 'https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/cloud-platform',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(clientEmail)
      .setSubject(clientEmail)
      .setAudience('https://oauth2.googleapis.com/token')
      .setIssuedAt(now)
      .setExpirationTime(now + 3600)
      .sign(privateKey);

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    const tokenData = await tokenRes.json();
    if (!tokenRes.ok) {
      console.error('OAuth2 token error:', tokenData);
      return errorResponse('Failed to authenticate with Google API', 500, 'GOOGLE_AUTH_ERROR');
    }

    const accessToken = tokenData.access_token;

    const updateRes = await fetch(
      `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:update`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          localId: user.uid,
          customAttributes: JSON.stringify({ role: 'authenticated' }),
        }),
      }
    );

    const updateData = await updateRes.json();
    if (!updateRes.ok) {
      console.error('Identity Toolkit update error:', updateData);
      return errorResponse('Failed to set custom claims', 500, 'CLAIMS_ERROR');
    }

    // If user's email is verified by OAuth (e.g. Google), ensure email_verifications record exists
    if (user.email_verified && user.email) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
      if (supabaseUrl && supabaseServiceKey) {
        try {
          const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2.39.8');
          const supabase = createClient(supabaseUrl, supabaseServiceKey);
          await supabase.from('email_verifications').upsert({
            uid: user.uid,
            email: user.email,
            verified_at: new Date().toISOString(),
          }, { onConflict: 'uid' });
        } catch (dbErr) {
          console.error('Auto email_verifications sync error:', dbErr);
        }
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Custom claims set successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return errorResponse((err as Error).message, 401, 'UNAUTHORIZED');
  }
});
