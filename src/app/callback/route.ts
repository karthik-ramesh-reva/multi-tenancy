import { NextRequest, NextResponse } from 'next/server';
import { customerConfigs } from '@/utils/customerConfig';
import axios from 'axios';

export async function GET(request: NextRequest) {
    const { searchParams } = new URL(request.url);

    const code = searchParams.get('code');

    // Access headers to get the subdomain
    const headersList = request.headers;
    const subdomain = headersList.get('x-subdomain');

    if (!code || !subdomain || !customerConfigs[subdomain]) {
        return new NextResponse('Authentication error', { status: 400 });
    }

    const { clientId, redirectUri, cognitoDomain } = customerConfigs[subdomain];

    const tokenUrl = `https://${cognitoDomain}/oauth2/token`;
    const paramsObj = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: clientId,
        redirect_uri: redirectUri,
        code,
    });

    try {
        const response = await axios.post(tokenUrl, paramsObj.toString(), {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        });

        const { id_token, access_token, refresh_token } = response.data;

        // Set tokens in cookies
        const responseCookies = NextResponse.redirect('/');
        responseCookies.cookies.set('idToken', id_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            path: '/',
        });
        responseCookies.cookies.set('accessToken', access_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            path: '/',
        });
        responseCookies.cookies.set('refreshToken', refresh_token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            path: '/',
        });

        return responseCookies;
    } catch (error) {
        console.error('Authentication error:', error);
        return new NextResponse('Authentication error', { status: 500 });
    }
}
