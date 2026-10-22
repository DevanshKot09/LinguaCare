import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';
import { corsHeaders } from '../_shared/cors.ts';
import { errorResponse } from '../_shared/error.ts';
import { verifyFirebaseToken } from '../_shared/firebase_auth.ts';
import { SignJWT, importPKCS8 } from 'npm:jose@5.2.2';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    const user = await verifyFirebaseToken(authHeader);

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    await supabase.from('profiles').delete().eq('uid', user.uid);
    await supabase.from('email_verifications').delete().eq('uid', user.uid);
    await supabase.from('otp_codes').delete().eq('uid', user.uid);

    await supabase.from('access_audit').insert({
      actor_uid: user.uid,
      action: 'DELETE_ACCOUNT',
      table_name: 'profiles',
      record_id: user.uid,
    });

    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (serviceAccountJson) {
      try {
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
        if (tokenRes.ok) {
          const accessToken = tokenData.access_token;
          await fetch(
            `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:delete`,
            {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${accessToken}`,
              },
              body: JSON.stringify({ localId: user.uid }),
            }
          );
        }
      } catch (err) {
        console.error('Firebase user deletion warning:', err);
      }
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Account deleted successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    return errorResponse((err as Error).message, 401, 'UNAUTHORIZED');
  }
});
