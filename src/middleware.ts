// src/middleware.ts

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { customerConfigs } from '@/utils/customerConfig';

export function middleware(request: NextRequest) {
    const host = request.headers.get('host') || '';
    const url = request.nextUrl.clone();
    const subdomain = getSubdomain(host);

    console.log(`Host: ${host}`);
    console.log(`URL: ${url}`);
    console.log(`Subdomain: ${subdomain}`);

    if (!subdomain || !customerConfigs[subdomain]) {
        return NextResponse.redirect(new URL('/404', request.url));
    }

    request.headers.set('x-subdomain', subdomain);

    const isProtectedRoute = url.pathname.startsWith('/protected');

    if (isProtectedRoute) {
        const idToken = request.cookies.get('idToken');

        if (!idToken) {
            return NextResponse.redirect(new URL('/login', request.url));
        }
    }

    return NextResponse.next({
        request: {
            headers: request.headers,
        },
    });
}

function getSubdomain(hostname: string): string | null {
    const domainParts = hostname.split('.');

    if (hostname.startsWith('localhost') || hostname.startsWith('127.0.0.1') || hostname.startsWith('reva.local')) {
        return 'reva';
    }

    if (domainParts.length >= 3) {
        return domainParts[0];
    }

    return null;
}

export const config = {
    matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
