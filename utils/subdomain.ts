// utils/subdomain.ts

export function getSubdomain(hostname: string): string | null {
    const domainParts = hostname.split('.');

    // Check for localhost and return a default subdomain
    if (hostname.startsWith('localhost') || hostname === '127.0.0.1') {
        return 'mt1'; // Default customer for local development
    }

    if (domainParts.length >= 3) {
        return domainParts[0];
    }

    return null;
}
