import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';
import nodemailer from 'npm:nodemailer@6.9.13';
import { corsHeaders } from '../_shared/cors.ts';
import { errorResponse } from '../_shared/error.ts';
import { verifyFirebaseToken } from '../_shared/firebase_auth.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const user = await verifyFirebaseToken(req.headers.get('Authorization'));
    if (!user.email) {
      return errorResponse('User email not found in token', 400, 'EMAIL_REQUIRED');
    }

    const smtpPortStr = Deno.env.get('SMTP_PORT') || '587';
    const smtpPort = Number(smtpPortStr);
    if (smtpPort === 25) {
      return errorResponse('SMTP port 25 is blocked on the platform.', 500, 'CONFIG_ERROR');
    }

    const smtpHost = Deno.env.get('SMTP_HOST');
    const smtpUser = Deno.env.get('SMTP_USER');
    const smtpPassword = Deno.env.get('SMTP_PASSWORD');
    const smtpFromName = Deno.env.get('SMTP_FROM_NAME') || 'LinguaCare';
    const smtpFromEmail = Deno.env.get('SMTP_FROM_EMAIL') || smtpUser;

    if (!smtpHost || !smtpUser || !smtpPassword) {
      return errorResponse('Server configuration error: SMTP credentials missing', 500, 'CONFIG_ERROR');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (user.email_verified) {
      await supabase.from('email_verifications').upsert({
        uid: user.uid,
        email: user.email,
        verified_at: new Date().toISOString(),
      });
      return new Response(
        JSON.stringify({ success: true, verified: true, message: 'Email already verified' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const now = new Date();
    const { data: activeCodes, error: fetchErr } = await supabase
      .from('otp_codes')
      .select('*')
      .eq('uid', user.uid)
      .eq('consumed', false)
      .order('created_at', { ascending: false })
      .limit(1);

    if (fetchErr) {
      console.error('Fetch OTP error:', fetchErr);
      return errorResponse('Database error', 500, 'DB_ERROR');
    }

    let sendCount = 1;
    let windowStart = now.toISOString();

    if (activeCodes && activeCodes.length > 0) {
      const latest = activeCodes[0];
      const createdAt = new Date(latest.created_at);
      const diffSeconds = (now.getTime() - createdAt.getTime()) / 1000;

      if (diffSeconds < 60) {
        return errorResponse('Please wait 60 seconds before requesting another code', 429, 'COOLDOWN_ACTIVE');
      }

      const windowStartDate = new Date(latest.window_start);
      const hoursDiff = (now.getTime() - windowStartDate.getTime()) / (1000 * 60 * 60);
      if (hoursDiff < 1) {
        if (latest.send_count >= 5) {
          return errorResponse('Maximum OTP request limit reached. Please try again later.', 429, 'RATE_LIMIT_EXCEEDED');
        }
        sendCount = latest.send_count + 1;
        windowStart = latest.window_start;
      }
    }

    await supabase
      .from('otp_codes')
      .update({ consumed: true })
      .eq('uid', user.uid)
      .eq('consumed', false);

    const array = new Uint32Array(1);
    crypto.getRandomValues(array);
    const code = String(array[0] % 1000000).padStart(6, '0');

    const pepper = Deno.env.get('OTP_PEPPER') || 'linguacare-secure-pepper';
    const msgUint8 = new TextEncoder().encode(`${code}:${pepper}:${user.uid}`);
    const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const codeHash = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');

    const expiresAt = new Date(now.getTime() + 10 * 60 * 1000).toISOString();

    const { error: insertErr } = await supabase.from('otp_codes').insert({
      uid: user.uid,
      email: user.email,
      code_hash: codeHash,
      expires_at: expiresAt,
      send_count: sendCount,
      window_start: windowStart,
    });

    if (insertErr) {
      console.error('Insert OTP error:', insertErr);
      return errorResponse('Failed to generate verification code', 500, 'DB_ERROR');
    }

    try {
      const transporter = nodemailer.createTransport({
        host: smtpHost,
        port: smtpPort,
        secure: smtpPort === 465,
        auth: {
          user: smtpUser,
          pass: smtpPassword,
        },
      });

      const textBody = `Hello,\n\nWelcome to LinguaCare.\n\nUse the verification code below to verify your email address and continue securely.\n\n${code}\n\nThis code expires in 10 minutes. For your security, do not share this code with anyone.\n\nIf you did not request this verification code, you can safely ignore this email.\n\nWarm regards,\nThe LinguaCare Team\n\nEvery Child Deserves to Be Understood\n\nLinguaCare supports language development. It does not diagnose medical conditions.`;

      const htmlBody = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your LinguaCare Verification Code</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f6f8; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f4f6f8; padding: 24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);">
          <!-- Header -->
          <tr>
            <td style="background-color: #0f766e; padding: 32px 24px; text-align: center;">
              <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px;">LinguaCare</h1>
              <p style="color: #ccfbf1; margin: 8px 0 0 0; font-size: 14px; font-weight: 500;">Every Child Deserves to Be Understood</p>
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding: 40px 32px; color: #334155; font-size: 16px; line-height: 1.6;">
              <p style="margin: 0 0 16px 0;">Hello,</p>
              <p style="margin: 0 0 16px 0;">Welcome to LinguaCare.</p>
              <p style="margin: 0 0 24px 0;">Use the verification code below to verify your email address and continue securely.</p>

              <!-- OTP Box -->
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin: 32px 0;">
                <tr>
                  <td align="center">
                    <div style="background-color: #f0fdfa; border: 2px dashed #14b8a6; border-radius: 8px; padding: 20px 32px; display: inline-block;">
                      <span style="font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #0f766e; font-family: monospace;">${code}</span>
                    </div>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 16px 0; color: #64748b; font-size: 14px; text-align: center;">This code expires in 10 minutes. For your security, do not share this code with anyone.</p>

              <p style="margin: 32px 0 16px 0;">If you did not request this verification code, you can safely ignore this email.</p>

              <p style="margin: 24px 0 0 0;">Warm regards,<br><strong>The LinguaCare Team</strong></p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color: #f8fafc; padding: 24px 32px; text-align: center; border-top: 1px solid #e2e8f0; color: #64748b; font-size: 13px; line-height: 1.5;">
              <p style="margin: 0 0 8px 0; font-weight: 600; color: #475569;">Every Child Deserves to Be Understood</p>
              <p style="margin: 0; color: #94a3b8; font-size: 12px;">LinguaCare supports language development. It does not diagnose medical conditions.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

      await transporter.sendMail({
        from: `"${smtpFromName}" <${smtpFromEmail}>`,
        to: user.email,
        subject: 'Your LinguaCare Verification Code',
        text: textBody,
        html: htmlBody,
      });
    } catch (smtpErr) {
      console.error('SMTP send error:', smtpErr);
      return errorResponse('Failed to send verification email', 500, 'EMAIL_SEND_ERROR');
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Verification code sent successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Unhandled error in send-otp:', err);
    const msg = (err as Error).message || '';
    if (msg.includes('Missing or invalid Authorization header') || msg.includes('Invalid or expired authentication token')) {
      return errorResponse(msg, 401, 'UNAUTHORIZED');
    }
    return errorResponse('An error occurred processing the request', 401, 'UNAUTHORIZED');
  }
});
