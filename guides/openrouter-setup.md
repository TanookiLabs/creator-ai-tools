# OpenRouter setup

Use this guide to add a first AI-powered text feature to this Next.js,
TypeScript, Better Auth, Prisma, and PostgreSQL application. OpenRouter is a
single API that provides access to many AI models. Your application sends a
server-side request to OpenRouter; OpenRouter routes it to the model you chose
and returns the response.

This guide shows one small, non-streaming text request. It does not create an
account, add billing, generate an API key, install a dependency, or change this
application for you.

## What you will build

A signed-in user can send a short question to a server endpoint. The endpoint
calls a selected OpenRouter text model and returns the reply to the app. The
browser never receives the OpenRouter API key.

This is a good first building block for:

| Use case | Example |
| --- | --- |
| Chat assistant | Answer a participant’s question in a chat panel. |
| Writing helper | Turn a few notes into a first draft or summary. |
| Product helper | Explain an account setting or suggest a next step. |

Image, audio, tool use, and background-agent workflows need additional design
and safety decisions. Start with a small text request so you can understand
the request, model cost, and response before expanding the feature.

## Before you begin

- Use an OpenRouter account owned by the person or organization responsible for
  model usage and billing.
- Decide which authenticated users may make requests and what they may send.
  Treat user prompts as untrusted input.
- Choose a current text-capable model from the [OpenRouter model
  catalog](https://openrouter.ai/models). Record the model slug in reviewed
  server configuration; do not use a floating “latest” alias for a product
  feature whose behavior or cost needs to stay predictable.
- Keep your Git worktree clean and do not put API keys in source code, commits,
  screenshots, or chat.

OpenRouter’s [quickstart](https://openrouter.ai/docs/quickstart) documents its
single API endpoint and model catalog. A request requires an API key in the
`Authorization` bearer header; `HTTP-Referer` and `X-OpenRouter-Title` are
optional attribution headers, not authentication.

## 1. Create an OpenRouter account and API key

1. Visit [openrouter.ai](https://openrouter.ai) and create or sign in to the
   account that will own this application’s usage.
2. Complete any required account, billing, or provider steps in the OpenRouter
   dashboard. Review the selected model’s pricing and availability before
   building a user-facing feature.
3. Open the [API keys page](https://openrouter.ai/settings/keys), create a key
   for this application and environment, and give it a recognizable name such
   as `my-app-local-development` or `my-app-production`.
4. Copy the key only into the secret store for the environment where it will be
   used. It may be shown only once.

Use separate keys for local development and production when practical. If a key
is exposed, revoke it in OpenRouter and replace it in the appropriate secret
store; do not try to remove it from Git history as the only response.

## 2. Store the key safely

For local development, add the key and your chosen model slug to the ignored
`.env` file:

```dotenv
OPENROUTER_API_KEY=<your key, kept only in this local secret file>
OPENROUTER_MODEL=<a reviewed OpenRouter text-model slug>
```

For production, add the same names in the Vercel project’s **Production**
environment variables. Mark `OPENROUTER_API_KEY` sensitive/write-only when
available. Do not use a `NEXT_PUBLIC_` prefix: that would make the key available
to browser code. Do not pull production variables into `.env.local`; see
[Manual Vercel deployment](manual-vercel-deployment.md) for the production
workflow.

`OPENROUTER_MODEL` is not a secret, but keeping it as configuration lets you
review and change the selected model without editing request logic.

## 3. Add a server-only request helper

Create `lib/openrouter.ts`. This uses the platform `fetch` already available in
Next.js, so no new package is needed for the first request.

```ts
type OpenRouterResponse = {
  choices?: Array<{
    message?: { content?: string | null }
  }>
}

export async function askOpenRouter(question: string) {
  const apiKey = process.env.OPENROUTER_API_KEY
  const model = process.env.OPENROUTER_MODEL

  if (!apiKey || !model) {
    throw new Error("OpenRouter is not configured")
  }

  const response = await fetch(
    "https://openrouter.ai/api/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        messages: [
          {
            role: "system",
            content: "Answer clearly and concisely.",
          },
          { role: "user", content: question },
        ],
        max_tokens: 250,
      }),
    },
  )

  if (!response.ok) {
    throw new Error("OpenRouter request failed")
  }

  const result = (await response.json()) as OpenRouterResponse
  const answer = result.choices?.[0]?.message?.content?.trim()

  if (!answer) {
    throw new Error("OpenRouter returned no text response")
  }

  return answer
}
```

Do not import this file from a client component. It reads a secret and must run
only on the server. Do not log the key, authorization header, raw prompt, or
complete provider response.

The request shape follows OpenRouter’s [chat-completion
reference](https://openrouter.ai/docs/api/api-reference/chat/create-a-chat-completion):
the model and at least one message are required, and the result contains a
model-generated message when the request succeeds.

## 4. Expose one protected route

Add a route such as `app/api/ai/answer/route.ts`. Reuse the application’s
existing Better Auth server helpers to require a signed-in participant before
calling the provider. Validate and bound the input before sending it upstream.

```ts
import { NextResponse } from "next/server"
import { askOpenRouter } from "@/lib/openrouter"
// Import the existing server-side Better Auth helper used by this application.

export async function POST(request: Request) {
  // Require the existing Better Auth session here before processing input.

  const body = (await request.json()) as { question?: unknown }
  const question = typeof body.question === "string" ? body.question.trim() : ""

  if (!question || question.length > 2_000) {
    return NextResponse.json({ error: "Enter a question up to 2,000 characters." }, { status: 400 })
  }

  try {
    const answer = await askOpenRouter(question)
    return NextResponse.json({ answer })
  } catch {
    return NextResponse.json(
      { error: "The AI response is unavailable. Please try again later." },
      { status: 502 },
    )
  }
}
```

The comment is deliberate: connect the route to the established Better Auth
session pattern rather than inventing a second authentication mechanism. Do not
return provider diagnostics, model keys, or raw errors to the browser.

## 5. Make a simple request

From a signed-in UI, send a short JSON request to the route:

```ts
const response = await fetch("/api/ai/answer", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ question: "Give me one idea for a friendly welcome message." }),
})

const result = (await response.json()) as { answer?: string; error?: string }
```

Render `result.answer` as plain text first. Do not pass model output directly to
`dangerouslySetInnerHTML`, execute it as code, or treat it as authorization,
financial, legal, or health advice. A model response is content—not a trusted
instruction or a database command.

## 6. Verify before you expand

1. Run the application locally with `npm run dev`.
2. Sign in using the existing Better Auth flow.
3. Send one short, harmless test question through the protected route.
4. Confirm the browser receives text but never an API key, provider error body,
   or server environment value.
5. Check the OpenRouter dashboard for the expected request and usage. Review
   the selected model, latency, and cost before allowing repeated or automated
   requests.
6. Add a test for unauthenticated access, empty/oversized input, provider
   failure, and a successful response before wiring a full chat UI.

For a production release, put the production key in Vercel, confirm the
production domain is the canonical Better Auth URL, and follow the reviewed
deployment process. Do not copy the local `.env` file to production.

## Where to go next

- Build a chat UI with streaming only after this single request has a clear
  authenticated user journey. See [Vercel AI chat](vercel-ai-chat.md) for the
  application-level chat guide.
- Add images or other modalities only after choosing the model, input policy,
  output display rules, and cost limits for that specific feature.
- Use a durable background-job system for long-running or retryable AI work;
  do not hold a browser request open for it. See
  [Background agents with Inngest](background-agents-with-inngest.md).
