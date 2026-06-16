import { NextRequest, NextResponse } from "next/server";
import { LinkTokenCreateRequest } from "plaid";
import { badRequest, jsonError } from "@/lib/api";
import { plaidClient, plaidDefaults } from "@/lib/plaid";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const clientUserId =
      typeof body.client_user_id === "string" && body.client_user_id.trim()
        ? body.client_user_id.trim()
        : "track-it-user";

    const payload: LinkTokenCreateRequest = {
      user: { client_user_id: clientUserId },
      client_name: plaidDefaults.clientName,
      products: [...plaidDefaults.products],
      country_codes: [...plaidDefaults.countryCodes],
      language: plaidDefaults.language
    };

    if (process.env.PLAID_REDIRECT_URI) {
      payload.redirect_uri = process.env.PLAID_REDIRECT_URI;
    }

    const response = await plaidClient.linkTokenCreate(payload);

    return NextResponse.json({
      link_token: response.data.link_token,
      expiration: response.data.expiration,
      request_id: response.data.request_id
    });
  } catch (error) {
    return jsonError(error, "Unable to create Plaid Link token.");
  }
}

export function GET() {
  return badRequest("Use POST /api/create_link_token.");
}
