# Vercel AI chat with server-side tools

Use this guide to add a small, streaming chat experience to this Next.js 16,
React 19, Better Auth, Prisma, and PostgreSQL application. It uses the Vercel
AI SDK with Vercel AI Gateway and gives the model a deliberately small set of
server-side tools. It does **not** install packages, create a Vercel account,
create an AI Gateway key, or change this application.

## What you are building

```text
Authenticated browser chat
  → Next.js route handler at /api/chat
  → Vercel AI SDK streaming response
  → allowlisted, server-side tool functions
  → Prisma, external APIs, or a queued job
```

The browser sends messages and renders streamed results. The model, API key,
authorization checks, and tool implementations stay on the server. A tool is
not an API endpoint the browser can invoke directly.

Start with a narrow assistant: help the signed-in participant understand their
own project data, draft a piece of text, or start a reviewed background task.
Do not begin with arbitrary shell access, unrestricted database writes, web
publishing, purchases, or cross-user data access.

## 1. Set up Vercel AI Gateway

1. Create or sign in to the Vercel account that owns the application.
2. In Vercel AI Gateway, create an API key for this application and choose a
   model available to that account.
3. Store the key by name only in the selected environment:

   ```dotenv
   AI_GATEWAY_API_KEY=<store only in the local or Vercel secret store>
   ```

4. For production, add `AI_GATEWAY_API_KEY` to the Vercel project’s
   **Production** environment as a sensitive value. Do not put it in Git,
   browser code, chat transcripts, or a `NEXT_PUBLIC_` variable.

Vercel AI Gateway authenticates the AI SDK with `AI_GATEWAY_API_KEY`; on Vercel
deployments it can also use the Vercel OIDC token. See [Vercel AI Gateway
authentication](https://vercel.com/docs/ai-gateway/authentication-and-byok).

## 2. Add the reviewed dependencies

After reviewing the feature and its cost boundary, install the SDK and the
React hook package:

```bash
npm install ai @ai-sdk/react zod
```

The `ai` package includes the AI Gateway provider. `zod` defines and validates
tool input on the server. Do not add a model-provider package unless you are
intentionally bypassing AI Gateway. The [AI SDK App Router quickstart](https://ai-sdk.dev/docs/getting-started/nextjs-app-router)
uses this same package set.

## 3. Define safe tools on the server

Create a server-only module such as `lib/ai/tools.ts`. Every tool should:

- receive the authenticated user ID from the route, not from model-generated
  input;
- query or change only data owned by that user;
- validate model-supplied arguments with a narrow schema;
- return the smallest useful result;
- reject side effects unless the user approved the exact action; and
- avoid returning secrets, sessions, tokens, connection URLs, or data from
  another participant.

For example, a read-only tool can load the participant’s own profile summary:

```ts
import { tool } from "ai"
import { z } from "zod"
import { prisma } from "@/lib/db/prisma"

export function createParticipantTools(userId: string) {
  return {
    getMyProfile: tool({
      description: "Get a concise summary of the signed-in participant's profile.",
      inputSchema: z.object({}),
      execute: async () => {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { name: true, email: true },
        })

        return user ? { name: user.name, email: user.email } : { found: false }
      },
    }),
  }
}
```

This starter’s Prisma schema currently contains the Better Auth user records.
When adding new application data, scope it by the authenticated user in the
schema and review the migration before exposing it through a tool.

## 4. Add an authenticated chat route

Use an App Router route handler such as `app/api/chat/route.ts`. Resolve the
session with the existing `auth` helper first, reject unauthenticated requests,
and convert only the submitted UI messages into model messages. The model name
below is an example: choose a currently available model in your Vercel account.

```ts
import { auth } from "@/lib/auth"
import { createParticipantTools } from "@/lib/ai/tools"
import { convertToModelMessages, gateway, streamText } from "ai"

export async function POST(request: Request) {
  const session = await auth.api.getSession({ headers: request.headers })

  if (!session?.user) {
    return new Response("Unauthorized", { status: 401 })
  }

  const { messages } = await request.json()

  const result = streamText({
    model: gateway("<provider>/<model>"),
    system: "You are a concise assistant. Use tools only when useful.",
    messages: await convertToModelMessages(messages),
    tools: createParticipantTools(session.user.id),
  })

  return result.toUIMessageStreamResponse()
}
```

Put rate limiting, a per-user usage budget, request-size limits, and an
explicit maximum tool-step count around this route before making it available
to more than a small set of people. The SDK’s [tool documentation](https://ai-sdk.dev/docs/foundations/tools)
explains how `inputSchema` and `execute` constrain and run tools.

## 5. Add the chat UI

Create a client component inside an authenticated route, for example
`app/(authenticated)/chat/page.tsx`. The AI SDK React `useChat` hook streams
messages from `/api/chat` and maintains chat UI state:

```tsx
"use client"

import { useState } from "react"
import { useChat } from "@ai-sdk/react"

export default function ChatPage() {
  const { messages, sendMessage, status, error } = useChat()
  const [input, setInput] = useState("")

  return (
    <main>
      {messages.map((message) => (
        <div key={message.id}>
          <strong>{message.role === "user" ? "You" : "Assistant"}</strong>
          {message.parts.map((part, index) =>
            part.type === "text" ? <p key={index}>{part.text}</p> : null,
          )}
        </div>
      ))}
      <form onSubmit={(event) => {
        event.preventDefault()
        if (!input.trim()) return
        sendMessage({ text: input })
        setInput("")
      }}>
        <label htmlFor="chat-message">Message</label>
        <input id="chat-message" value={input} onChange={(event) => setInput(event.target.value)} />
        <button disabled={status !== "ready"} type="submit">Send</button>
      </form>
      {error ? <p role="alert">The chat could not respond. Try again.</p> : null}
    </main>
  )
}
```

Present tool activity clearly when it matters, but do not expose hidden system
instructions, private tool output, or error diagnostics to the browser. The
[AI SDK `useChat` reference](https://ai-sdk.dev/docs/reference/ai-sdk-ui/use-chat)
documents its message and streaming API.

## 6. Decide what to persist

For a short prototype, keeping messages only in browser state is reasonable.
For a real participant chat history, add reviewed Prisma models for a
conversation and messages, each scoped to `userId`. Store user-visible content
and safe model metadata only. Do not store API keys, complete tool payloads,
or confidential data merely because it appeared in a prompt.

If a tool starts work that can outlive the HTTP request—research, file
processing, a multi-step agent, a scheduled action, or retryable external API
work—make it create a background job rather than trying to finish inside this
route. Follow [Run agents in the background with Inngest](background-agents-with-inngest.md).

## 7. Verify and release

Before release:

1. Confirm anonymous requests to `/api/chat` receive `401`.
2. Test a signed-in participant’s read-only tool and confirm it cannot return
   another participant’s data.
3. Confirm a side-effecting tool displays and receives explicit user approval
   before it acts.
4. Trigger a tool failure and show a generic recovery message, without
   returning credentials or provider diagnostics.
5. Run `npm run lint`, `npm run typecheck`, `npm run test:quality`, and the
   normal reviewed production deployment workflow.

Set a spend alert and review Gateway usage before broadening the model, tool
set, or audience. Vercel AI Gateway provides provider-agnostic model access and
usage monitoring; see [its SDK overview](https://vercel.com/docs/ai-gateway/sdks-and-apis).
