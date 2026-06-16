import { NextRequest, NextResponse } from "next/server";
import { badRequest, jsonError } from "@/lib/api";
import { plaidClient } from "@/lib/plaid";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const publicToken = typeof body.public_token === "string" ? body.public_token : "";

    if (!publicToken) {
      return badRequest("Missing public_token.");
    }

    const response = await plaidClient.itemPublicTokenExchange({
      public_token: publicToken
    });

    const { access_token, item_id, request_id } = response.data;

    // TODO: Save access_token to your database here, tied to the signed-in user.
    // Never send access_token to the frontend in production. The iOS app should call
    // your backend, and this backend should load the saved token server-side.
    void access_token;

    return NextResponse.json({
      item_id,
      request_id,
      saved: false,
      message: "Public token exchanged. Add database storage where marked in this route."
    });
  } catch (error) {
    return jsonError(error, "Unable to exchange Plaid public token.");
  }
}

export function GET() {
  return badRequest("Use POST /api/exchange_public_token.");
}
