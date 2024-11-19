// src/app/logout/route.ts

import { NextRequest, NextResponse } from 'next/server';
import { customerConfigs } from '@/utils/customerConfig';

export async function GET(request: NextRequest) {
    const host = request.headers.get('host') || '';
    const subdomain = host.split('.')[0];

    if (!subdomain || !customerConfigs[subdomain]) {
        // Handle missing subdomain or customer config
        return new NextResponse('Customer not found', { status: 400 });
    }

    const { cognitoDomain, clientId, logoutUri } = customerConfigs[subdomain];

    // Clear the cookies
    const response = NextResponse.redirect(`https://${cognitoDomain}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`);

    response.cookies.set('idToken', '', {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        expires: new Date(0),
    });
    response.cookies.set('accessToken', '', {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        expires: new Date(0),
    });
    response.cookies.set('refreshToken', '', {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        path: '/',
        expires: new Date(0),
    });

    return response;
}
