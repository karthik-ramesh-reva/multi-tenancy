// src/app/login/page.tsx

import { redirect } from 'next/navigation';
import { headers } from 'next/headers';
import { customerConfigs } from '@/utils/customerConfig';

export default async function LoginPage() {
    const headersList = await headers();
    const subdomain = headersList.get('x-subdomain')?.split('.')[0]; // Extract subdomain

    console.log('Subdomain:', subdomain);

    if (!subdomain || !customerConfigs[subdomain]) {
        // Handle missing subdomain or customer config
        return <h1>Customer not found</h1>;
    }

    const { cognitoDomain, clientId, redirectUri } = customerConfigs[subdomain];

    const loginUrl = `https://${cognitoDomain}/login?client_id=${clientId}&response_type=code&scope=email+openid+phone&redirect_uri=${encodeURIComponent(
        redirectUri
    )}&state=${encodeURIComponent(subdomain)}`; // Include subdomain in state

    // Redirect to Cognito Hosted UI
    redirect(loginUrl);

    return null;
}
