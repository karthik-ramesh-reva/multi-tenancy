// src/app/callback/route.ts

import { NextRequest, NextResponse } from 'next/server';
import { customerConfigs } from '@/utils/customerConfig';
import axios, { AxiosError } from 'axios';

export async function GET(request: NextRequest) {
    const { searchParams } = new URL(request.url);

    const code = searchParams.get('code');
    const subdomain = searchParams.get('state'); // Retrieve subdomain from state

    if (!code || !subdomain || !customerConfigs[subdomain]) {
        console.error('Missing code, subdomain, or customer config');
        return new NextResponse('Authentication error', { status: 400 });
    }

    const { clientId, clientSecret, cognitoDomain } = customerConfigs[subdomain];

    const headersList = request.headers;
    const host = headersList.get('host') || '';

    const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
    const redirectUri = `${protocol}://${host}/callback`;

    const tokenUrl = `https://${cognitoDomain}/oauth2/token`;
    const paramsObj = new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: clientId,
        redirect_uri: redirectUri,
        code,
    });

    const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

    console.log('Token URL:', tokenUrl);
    console.log('Token request parameters:', paramsObj.toString());

    try {
        const response = await axios.post(tokenUrl, paramsObj.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': `Basic ${basicAuth}`,
            },
        });

        const { id_token, access_token, refresh_token } = response.data;

        const redirectUrl = `${protocol}://${host}/`;

        console.log('Redirecting to:', redirectUrl);

        const responseCookies = NextResponse.redirect(redirectUrl);

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
        if (error instanceof AxiosError) {
            console.error('Authentication error:', error.response?.data || error.message);
        } else if (error instanceof Error) {
            console.error('Error:', error.message);
        } else {
            console.error('Unknown error:', error);
        }
        return new NextResponse('Authentication error', { status: 500 });
    }
}
