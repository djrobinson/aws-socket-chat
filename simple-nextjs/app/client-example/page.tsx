import { auth } from "auth";
import { SessionProvider } from "next-auth/react";
import ClientExample from "../components/client-example";

export default async function ClientPage() {
  const session = await auth();
  if (session?.user) {
    session.user = {
      name: session.user.name,
      email: session.user.email,
      image: session.user.image,
    };
  }

  return (
    <SessionProvider session={session}>
      <ClientExample />
    </SessionProvider>
  );
}
