import { NextRequest, NextResponse } from "next/server";
import { badRequest, jsonError } from "@/lib/api";
import { getPlaidClient } from "@/lib/plaid";

export const runtime = "nodejs";

function accountType(type: string) {
  switch (type) {
    case "credit":
      return "card";
    case "investment":
      return "crypto";
    case "cash":
      return "cash";
    default:
      return "bank";
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const publicToken = typeof body.public_token === "string" ? body.public_token : "";
    const scope = typeof body.scope === "string" ? body.scope : "Personal";

    if (!publicToken) {
      return badRequest("Missing public_token.");
    }

    const plaidClient = getPlaidClient();
    const response = await plaidClient.itemPublicTokenExchange({
      public_token: publicToken
    });

    const { access_token, item_id, request_id } = response.data;

    // TODO: Save access_token to your database here, tied to the signed-in user.
    // Never send access_token to the frontend in production. The iOS app should call
    // your backend, and this backend should load the saved token server-side.
    const [balancesResponse, transactionsResponse] = await Promise.all([
      plaidClient.accountsBalanceGet({ access_token }),
      plaidClient.transactionsSync({ access_token, count: 100 })
    ]);

    const accounts = balancesResponse.data.accounts.map((account) => ({
      id: account.account_id,
      name: account.official_name || account.name,
      mask: account.mask,
      type: accountType(account.type),
      balance: account.balances.current || 0,
      scope
    }));

    const accountsById = new Map(accounts.map((account) => [account.id, account]));
    const transactions = transactionsResponse.data.added.map((transaction) => {
      const account = accountsById.get(transaction.account_id);

      return {
        id: transaction.transaction_id,
        name: transaction.merchant_name || transaction.name,
        amount: transaction.amount,
        date: `${transaction.date}T12:00:00Z`,
        category:
          transaction.personal_finance_category?.primary ||
          transaction.category?.[0] ||
          "Other",
        account_type: account?.type || "bank",
        account_name: account?.name,
        scope
      };
    });

    return NextResponse.json({
      accounts,
      transactions,
      item_id,
      request_id,
      saved: false,
      cursor: transactionsResponse.data.next_cursor,
      message: "Public token exchanged. Add database storage where marked in this route."
    });
  } catch (error) {
    return jsonError(error, "Unable to exchange Plaid public token.");
  }
}

export function GET() {
  return badRequest("Use POST /api/exchange_public_token.");
}
