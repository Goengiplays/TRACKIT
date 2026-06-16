# TRACK IT

TRACK IT is a native SwiftUI personal finance dashboard for iPhone. It combines bank, card, crypto, cash, income-source, expense, AI-assisted entry, and transaction tracking in one minimal fintech interface.

## Run

Open `TrackerX.xcodeproj` in Xcode and run the `TrackerX` scheme on an iPhone simulator running iOS 17 or newer.

## Included

- Total net balance across bank, card, cash, and crypto accounts
- Manual income and expense entry with local persistence
- Income sources such as Moxies, Rosa, TikTok Shop, cash jobs, and side hustles
- Searchable and filterable unified activity feed
- Income, spending, net profit, job, and category analytics
- Wallet and connected-account overview
- Track AI assistant for quick natural-language income and expense entry

Live account syncing requires a financial data provider such as Plaid and a backend token exchange. The current build provides the complete local product experience and a connection-ready wallet flow.

## Plaid

The official Plaid LinkKit 7 package is included. A starter server lives in `PlaidBackend`.

1. Copy `PlaidBackend/.env.example` values into your server environment.
2. Add Plaid sandbox or development credentials.
3. Run `npm start` inside `PlaidBackend`.
4. Enter the public HTTPS server URL in TRACK IT under Wallet → Connect a bank with Plaid.

Plaid credentials and access tokens must stay server-side. Replace the starter server's in-memory access-token storage with encrypted database storage before production.
