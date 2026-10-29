import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.2.2';

const JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
);

export interface FirebaseUser {
  uid: string;
  email?: string;
  email_verified?: boolean;
}

export async function verifyFirebaseToken(authHeader: string | null): Promise<FirebaseUser> {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new Error('Missing or invalid Authorization header');
  }

  const token = authHeader.split(' ')[1];
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
  if (!projectId) {
    throw new Error('Server configuration error: FIREBASE_PROJECT_ID missing');
  }

  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });

    return {
      uid: payload.sub as string,
      email: payload.email as string | undefined,
      email_verified: payload.email_verified as boolean | undefined,
    };
  } catch (err) {
    // Log internal JWT error on server side and avoid leaking details to client
    console.error('Firebase token verification error:', err);
    throw new Error('Invalid or expired authentication token');
  }
}
