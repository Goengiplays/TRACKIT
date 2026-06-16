# Track It Plaid Backend

Next.js App Router backend for Plaid, designed for Vercel.

This backend keeps `PLAID_SECRET` server-side only. Do not expose Plaid secrets to the iOS app or any frontend.

## Required Environment Variables

Set these locally in `.env.local` and in Vercel Project Settings:

```bash
PLAID_CLIENT_ID=your-plaid-client-id
PLAID_SECRET=your-plaid-secret
PLAID_ENV=sandbox
```

Valid `PLAID_ENV` values:

```bash
sandbox
development
production
```

Optional:

```bash
PLAID_REDIRECT_URI=https://your-vercel-app.vercel.app
```

Use `PLAID_REDIRECT_URI` only if your Plaid Link setup needs OAuth redirect support.

Important: never create `NEXT_PUBLIC_PLAID_SECRET`. Anything prefixed with `NEXT_PUBLIC_` can be exposed to the frontend.

## Local Setup

From this folder:

```bash
cd PlaidBackend
npm install
npm run dev
```

Local server:

```bash
http://localhost:3000
```

Local API routes:

```bash
POST http://localhost:3000/api/create_link_token
POST http://localhost:3000/api/exchange_public_token
POST http://localhost:3000/api/transactions
```

Verify production build:

```bash
npm run build
```

## Deploy To Vercel

1. Push this project to GitHub.

2. Go to Vercel:

```bash
https://vercel.com/new
```

3. Import the GitHub repo.

4. Set the Root Directory to:

```bash
PlaidBackend
```

5. Vercel should detect Next.js automatically.

6. Set Build Command:

```bash
npm run build
```

7. Set Install Command:

```bash
npm install
```

8. Set Output Directory:

```bash
.next
```

9. Add environment variables in Vercel:

```bash
PLAID_CLIENT_ID=your-plaid-client-id
PLAID_SECRET=your-sandbox-or-production-secret
PLAID_ENV=sandbox
```

For production Plaid:

```bash
PLAID_ENV=production
PLAID_SECRET=your-production-secret
```

10. Click Deploy.

## Vercel API URLs

After deploy, your API base URL will look like:

```bash
https://your-vercel-app.vercel.app
```

Use these from the iOS app:

```bash
POST https://your-vercel-app.vercel.app/api/create_link_token
POST https://your-vercel-app.vercel.app/api/exchange_public_token
POST https://your-vercel-app.vercel.app/api/transactions
```

## Route Details

### POST `/api/create_link_token`

Creates a Plaid Link token using:

- Product: `transactions`
- Country: `US`
- Client name: `Track It`

Optional body:

```json
{
  "client_user_id": "user_123"
}
```

Response:

```json
{
  "link_token": "link-sandbox-...",
  "expiration": "2026-06-16T...",
  "request_id": "..."
}
```

### POST `/api/exchange_public_token`

Exchanges the Plaid `public_token` from Link for an `access_token`.

Body:

```json
{
  "public_token": "public-sandbox-..."
}
```

Important: the route does not return `access_token` to the frontend. There is a comment in the route showing where to save it to a database later.

### POST `/api/transactions`

Fetches accounts and transactions from Plaid.

Current development body:

```json
{
  "access_token": "access-sandbox-...",
  "cursor": "optional-cursor"
}
```

Production TODO: load `access_token` from your database using the authenticated user/session instead of accepting it from the request body.

## Database TODO

Add database storage in:

```bash
app/api/exchange_public_token/route.ts
```

Look for:

```ts
// TODO: Save access_token to your database here, tied to the signed-in user.
```

Then update:

```bash
app/api/transactions/route.ts
```

Look for:

```ts
// TODO: In production, load access_token from your database using the
// authenticated user/session instead of accepting it from the request body.
```

## Security Notes

- Keep `PLAID_SECRET` only in Vercel env vars or local `.env.local`.
- Do not commit `.env.local`.
- Do not send `access_token` to the iOS app in production.
- Add authentication before storing real users' bank tokens.
- Use HTTPS only in production.

## Useful Commands

```bash
npm run dev
npm run build
npm run start
```
