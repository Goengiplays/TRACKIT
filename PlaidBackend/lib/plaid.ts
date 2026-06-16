import {
  Configuration,
  CountryCode,
  PlaidApi,
  PlaidEnvironments,
  Products
} from "plaid";

type PlaidEnv = keyof typeof PlaidEnvironments;

const plaidEnv = (process.env.PLAID_ENV || "sandbox").toLowerCase() as PlaidEnv;

if (!PlaidEnvironments[plaidEnv]) {
  throw new Error("Invalid PLAID_ENV. Use sandbox, development, or production.");
}

if (!process.env.PLAID_CLIENT_ID || !process.env.PLAID_SECRET) {
  throw new Error("Missing PLAID_CLIENT_ID or PLAID_SECRET environment variables.");
}

const configuration = new Configuration({
  basePath: PlaidEnvironments[plaidEnv],
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID,
      "PLAID-SECRET": process.env.PLAID_SECRET
    }
  }
});

export const plaidClient = new PlaidApi(configuration);

export const plaidDefaults = {
  clientName: "Track It",
  products: [Products.Transactions],
  countryCodes: [CountryCode.Us],
  language: "en"
} as const;
