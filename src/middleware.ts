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
        // Optionally handle missing or invalid subdomains
        // For example, redirect to a default page or show a 404
        return NextResponse.redirect(new URL('/404', request.url));
    }

    // Pass the subdomain to the request headers so it can be accessed in components
    request.headers.set('x-subdomain', subdomain);

    // Check authentication for protected routes
    const isProtectedRoute = url.pathname.startsWith('/protected');

    if (isProtectedRoute) {
        const idToken = request.cookies.get('idToken');

        if (!idToken) {
            // Redirect to login
            return NextResponse.redirect(new URL('/login', request.url));
        }

        // Optionally verify the token here
    }

    // Continue to the requested page
    return NextResponse.next({
        request: {
            headers: request.headers,
        },
    });
}

// Helper function to extract subdomain
function getSubdomain(hostname: string): string | null {
    const domainParts = hostname.split('.');

    // Handle localhost and development environment
    if (hostname.startsWith('localhost') || hostname.startsWith('127.0.0.1')) {
        // You can set a default subdomain for development
        return 'mt1';
    }

    if (domainParts.length >= 3) {
        return domainParts[0];
    }

    return null;
}

// Specify the paths the middleware should run on
export const config = {
    matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
