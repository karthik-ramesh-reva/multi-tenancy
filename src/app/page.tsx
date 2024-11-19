// src/app/route.ts

import {cookies, headers} from 'next/headers';
import { redirect } from 'next/navigation';
import { customerConfigs } from '@/utils/customerConfig';
import jwt from 'jsonwebtoken';

export default async function Home() {
  const headersList = await headers();
    const cookieStore = await cookies();
  const subdomain = headersList.get('x-subdomain');

  const customerConfig = subdomain ? customerConfigs[subdomain] : null;

  if (!customerConfig) {
    return <h1>Customer not found 3</h1>;
  }
    const idToken = cookieStore.get('idToken')?.value;

    if (!idToken) {
        redirect('/login');
    }

    let claims;
    try {
        claims = jwt.decode(idToken);
    } catch (error) {
        console.error('Error decoding token:', error);
        return <h1>Invalid token</h1>;
    }

  return (
      <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
          <main className="flex flex-col gap-8 row-start-2 items-center sm:items-start">
              Welcome, Below are the token claims
              <pre>{JSON.stringify(claims, null, 2)}</pre>
          </main>
      </div>
  );
}
