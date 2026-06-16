import { NextResponse } from "next/server";

type PlaidErrorShape = {
  response?: {
    status?: number;
    data?: {
      error_code?: string;
      error_message?: string;
      request_id?: string;
    };
  };
};

export function jsonError(error: unknown, fallback = "Plaid request failed") {
  if (isPlaidError(error)) {
    return NextResponse.json(
      {
        error: error.response?.data?.error_code || "PLAID_ERROR",
        message: error.response?.data?.error_message || fallback,
        request_id: error.response?.data?.request_id
      },
      { status: error.response?.status || 500 }
    );
  }

  if (error instanceof Error) {
    return NextResponse.json({ error: "SERVER_ERROR", message: error.message }, { status: 500 });
  }

  return NextResponse.json({ error: "SERVER_ERROR", message: fallback }, { status: 500 });
}

export function badRequest(message: string) {
  return NextResponse.json({ error: "BAD_REQUEST", message }, { status: 400 });
}

function isPlaidError(error: unknown): error is PlaidErrorShape {
  return Boolean(
    error &&
      typeof error === "object" &&
      "response" in error &&
      (error as PlaidErrorShape).response?.data
  );
}
