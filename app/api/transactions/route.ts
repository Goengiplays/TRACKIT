import { NextRequest, NextResponse } from "next/server";
import { badRequest, jsonError } from "@/lib/api";
import { getPlaidClient } from "@/lib/plaid";

export const runtime = "nodejs";

type TransactionsBody = {
  access_token?: string;
  cursor?: string;
};

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json().catch(() => ({}))) as TransactionsBody;

    // TODO: In production, load access_token from your database using the
    // authenticated user/session instead of accepting it from the request body.
    const accessToken = body.access_token;

    if (!accessToken) {
      return badRequest(
        "Missing access_token. Add database storage in exchange_public_token, then load the saved token here."
      );
    }

    const plaidClient = getPlaidClient();
    const accountsResponse = await plaidClient.accountsBalanceGet({
      access_token: accessToken
    });

    const syncResponse = await plaidClient.transactionsSync({
      access_token: accessToken,
      cursor: body.cursor,
      count: 100
    });

    const accountsById = new Map(
      accountsResponse.data.accounts.map((account) => [account.account_id, account])
    );

    const transactions = syncResponse.data.added.map((transaction) => {
      const account = accountsById.get(transaction.account_id);

      return {
        id: transaction.transaction_id,
        name: transaction.merchant_name || transaction.name,
        amount: transaction.amount,
        date: transaction.date,
        category:
          transaction.personal_finance_category?.primary ||
          transaction.category?.[0] ||
          "Other",
        account_id: transaction.account_id,
        account_name: account?.official_name || account?.name,
        pending: transaction.pending
      };
    });

    return NextResponse.json({
      accounts: accountsResponse.data.accounts,
      transactions,
      cursor: syncResponse.data.next_cursor,
      has_more: syncResponse.data.has_more,
      request_id: syncResponse.data.request_id
    });
  } catch (error) {
    return jsonError(error, "Unable to fetch Plaid transactions.");
  }
}

export function GET() {
  return badRequest("Use POST /api/transactions.");
}
