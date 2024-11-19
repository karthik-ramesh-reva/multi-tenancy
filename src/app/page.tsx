// src/app/route.ts

import {cookies, headers} from 'next/headers';
import { redirect } from 'next/navigation';
import { customerConfigs } from '@/utils/customerConfig';

export default async function Home() {
  const headersList = await headers();
    const cookieStore = await cookies();
  const subdomain = headersList.get('x-subdomain');

  const customerConfig = subdomain ? customerConfigs[subdomain] : null;

  if (!customerConfig) {
    // Optionally handle missing customer config
    return <h1>Customer not found 3</h1>;
  }

    // Check if the user is authenticated
    const idToken = cookieStore.get('idToken')?.value;

    if (!idToken) {
        // User is not authenticated, redirect to the login page
        redirect('/login');
    }

  return (
      <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20 font-[family-name:var(--font-geist-sans)]">
        <main className="flex flex-col gap-8 row-start-2 items-center sm:items-start">


          Welcome
        </main>
        {/* Footer */}
      </div>
  );
}
