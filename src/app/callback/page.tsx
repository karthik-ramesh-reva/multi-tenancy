// src/app/callback/page.tsx

import { headers, cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { customerConfigs } from '@/utils/customerConfig';
import axios from 'axios';
// import jwtDecode from 'jwt-decode';

export default async function CallbackPage({
                                               searchParams,
                                           }: {
    searchParams: Record<string, string | string[] | undefined>;
}) {
    // Extract the `code` parameter
    const codeParam = searchParams.code;
    const code = Array.isArray(codeParam) ? codeParam[0] : codeParam;

    // Access headers to get the subdomain
    const headersList = await headers();
    const subdomain = headersList.get('x-subdomain');

    if (!code || typeof code !== 'string' || !subdomain || !customerConfigs[subdomain]) {
        return <h1>Authentication error</h1>;
    }

    const { clientId, redirectUri, cognitoDomain } = customerConfigs[subdomain];

    const tokenUrl = `https://${cognitoDomain}/oauth2/token`;
    const params = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: clientId,
        redirect_uri: redirectUri,
        code,
    });

    try {
        const response = await axios.post(tokenUrl, params.toString(), {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });

        const { id_token, access_token, refresh_token } = response.data;

        // Optionally decode the token
        // const decodedToken = jwtDecode(id_token);

        // Set tokens in cookies
        const cookieStore = await cookies();

        cookieStore.set('idToken', id_token, { httpOnly: true, secure: true });
        cookieStore.set('accessToken', access_token, { httpOnly: true, secure: true });
        cookieStore.set('refreshToken', refresh_token, { httpOnly: true, secure: true });

        // Redirect to home page
        redirect('/');
    } catch (error) {
        console.error('Authentication error:', error);
        return <h1>Authentication error</h1>;
    }
}
