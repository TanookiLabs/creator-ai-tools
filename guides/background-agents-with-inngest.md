# Run agents in the background with Inngest

Use this guide when an AI task should continue after the participant receives a
response: research, multi-step analysis, document processing, delayed work, or
a retryable call to an external service. It adds durable background execution
to this Next.js 16, Prisma, PostgreSQL application with Inngest. It does
**not** create an Inngest account, install packages, add credentials, start a
worker, or run an agent for you.

For an interactive streaming chat, first use [Vercel AI chat with server-side
tools](vercel-ai-chat.md). Inngest is the durable execution layer behind a
tool—not a replacement for the chat interface.

## What you are building

```text
Participant asks chat to start work
  → authenticated server tool creates a job record and emits an event
  → Inngest function runs durable, bounded steps in the background
  → Prisma records safe status and result for the participant to view
```

The chat route returns quickly with a job ID and “in progress” state. The
background function owns retries and durable steps. The browser polls or
subscribes to its own job status; it never holds an AI or Inngest credential.

## 1. Decide whether the task belongs in the background

Use a normal server-side tool when the work is small, read-only, and should
finish while the participant waits. Use Inngest when it needs one or more of:

- a request that may outlive a Vercel function or browser connection;
- a retry after a transient provider failure;
- separate durable steps, delay, schedule, concurrency limit, or audit trail;
- a human approval or a participant action before the next step; or
- fan-out/fan-in processing of multiple inputs.

Do not queue a task simply to bypass authorization, approval, rate limits, or
cost limits. The same user ownership and tool allowlist rules apply in a
background function.

## 2. Create the Inngest project and configuration

1. Create an Inngest project owned by the participant or organization that
   owns the app.
2. Create the project keys and store them as server-only local/Vercel
   environment variables by name. Never paste them in source, chat, or a
   browser variable.

   ```dotenv
   INNGEST_EVENT_KEY=<store only in the chosen secret store>
   INNGEST_SIGNING_KEY=<store only in the chosen secret store>
   ```

3. Install the reviewed packages. If the chat guide is already implemented,
   `ai` and `zod` will already be present.

   ```bash
   npm install inngest ai zod
   ```

4. During local development, run the Inngest Dev Server according to the
   project’s current Inngest dashboard instructions. Configure its endpoint to
   the local Next.js route added below. Do not expose a local dev server to the
   public internet to make this work.

The [Inngest Next.js quickstart](https://www.inngest.com/docs/getting-started/nextjs-quick-start)
covers the current App Router connection flow.

## 3. Add a user-owned job record

Before emitting an event, create a Prisma record that the participant owns.
This gives the UI a stable ID and prevents the event payload from becoming the
source of truth. A minimal reviewed model could look like:

```prisma
model AgentJob {
  id        String   @id @default(cuid())
  userId    String
  type      String
  status    String   @default("queued")
  input     Json
  result    Json?
  errorCode String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId, createdAt])
}
```

Make the migration with `npm run db:migrate:dev -- --name add_agent_jobs`,
review it, and commit it before applying it to production. Keep `input` and
`result` deliberately small and free of tokens, raw credentials, connection
URLs, and unrelated participant data.

## 4. Emit a typed event from an authenticated tool

Create `lib/inngest/client.ts` and define the event names and payload shape in
one place. The event contains only the stable job ID and authenticated owner
ID; load authoritative input from Prisma in the function.

```ts
import { EventSchemas, Inngest } from "inngest"

export const inngest = new Inngest({
  id: "<your-app-id>",
  schemas: new EventSchemas().fromRecord<{
    "agent/job.requested": {
      data: { jobId: string; userId: string }
    }
  }>(),
})
```

The chat’s server-side tool should validate the participant’s request, create
the `AgentJob`, and send `agent/job.requested`. It must not accept `userId`
from the model or browser as authority. Return `{ jobId, status: "queued" }`
to the chat instead of waiting for the work to complete.

## 5. Run the agent in bounded durable steps

Define an Inngest function with an explicit concurrency limit and bounded
agent/model calls. Load the job by both `id` and `userId`, update its status,
and record only a safe result or error category.

```ts
export const runAgentJob = inngest.createFunction(
  {
    id: "run-agent-job",
    concurrency: [{ limit: 2 }],
    retries: 2,
  },
  { event: "agent/job.requested" },
  async ({ event, step }) => {
    const job = await step.run("load-owned-job", () =>
      prisma.agentJob.findFirstOrThrow({
        where: { id: event.data.jobId, userId: event.data.userId },
      }),
    )

    await step.run("mark-running", () =>
      prisma.agentJob.update({ where: { id: job.id }, data: { status: "running" } }),
    )

    const result = await step.run("run-bounded-agent", async () => {
      // Invoke the AI SDK agent with an allowlisted tool set and a strict
      // step/token/time budget. Never provide shell or unrestricted DB access.
      return { summary: "<safe, participant-visible result>" }
    })

    await step.run("save-result", () =>
      prisma.agentJob.update({
        where: { id: job.id },
        data: { status: "completed", result },
      }),
    )
  },
)
```

Put provider calls, expensive external calls, and state-changing operations in
separate named `step.run` steps. Make every external mutation idempotent with a
job-derived key, because durable execution can retry after a failure. Do not
use “retry until it works”; choose a small retry count, clear terminal states,
and a participant-visible recovery path.

Inngest functions preserve step state and resume after failures, so a retry can
continue from the last completed step rather than start the entire task again.
See [Inngest Functions](https://www.inngest.com/docs/learn/inngest-functions).

## 6. Expose the function to Next.js

Create an App Router route handler such as `app/api/inngest/route.ts` and pass
the client and exported functions to Inngest’s `serve` adapter. Keep this route
for Inngest’s signed protocol; do not turn it into a public “run any job” API.

```ts
import { serve } from "inngest/next"
import { inngest } from "@/lib/inngest/client"
import { runAgentJob } from "@/lib/inngest/functions"

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [runAgentJob],
})
```

Register the deployed `/api/inngest` endpoint in Inngest, then confirm that
Inngest can discover the function before allowing participants to enqueue
work. The participant-facing chat continues to use its own authenticated route.

## 7. Display job status safely

Add a server route or server-rendered page that queries `AgentJob` only with
the current session’s `userId`. Show `queued`, `running`, `completed`, or
`failed`; show a generic error and a safe retry action for failures. Never
return Inngest keys, full provider errors, model prompts, tool traces, or data
belonging to another participant.

For an agent that proposes an external action—send email, publish content,
change a Shopify product, or create a charge—use an `awaiting_approval` status.
Display the exact proposed action, target, and consequences; create a separate
authenticated approval route; then emit a separate approved event. Do not
allow the queued agent event itself to carry approval.

## 8. Verify and operate

Before release:

1. Enqueue one job with an authenticated test account and confirm it appears in
   the Inngest dashboard and reaches a terminal state.
2. Confirm another account cannot read or trigger that job by guessing its ID.
3. Cause one safe transient failure and confirm the configured bounded retry
   resumes from the appropriate step.
4. Confirm an unrecoverable failure leaves `failed` with a safe recovery
   message—not a silent loop.
5. Confirm duplicate events cannot duplicate an external action.
6. Run `npm run lint`, `npm run typecheck`, `npm run test:quality`, then use
   the normal reviewed production deployment workflow.

Set per-user concurrency and cost limits before launch. For AI-specific durable
patterns, see [Inngest’s AI agent and RAG examples](https://www.inngest.com/docs/examples/ai-agents-and-rag).
