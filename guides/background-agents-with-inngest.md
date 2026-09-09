# Run a background AI agent with Inngest

Use this guide when you want an AI agent to keep working after a participant
leaves the page—and keep that participant informed about what it is doing. The
agent can start from a signed-in user action, a trusted system event, or a
schedule. Inngest provides the durable execution and live-update layer for this
Next.js 16, Better Auth, Prisma, and PostgreSQL application.

This is not a guide for “making an agent run a background job.” The agent is
the background-running process: it receives a clearly scoped assignment,
performs bounded steps and allowlisted tool calls, records its outcome, and
reports safe progress updates to its owner.

It does **not** create an Inngest account, install packages, add credentials,
start an agent, or approve an external action for you.

## What you are building

```text
User starts research (or a trusted event/schedule starts it)
  → authenticated server creates an AgentRun owned by that user
  → Inngest runs the agent’s durable, bounded steps
  → agent publishes safe progress updates and saves a final result
  → user sees progress, result, failure, or an approval request
```

For example, a participant can ask: “Research five potential partners and
give me a short comparison.” The app returns immediately with an in-progress
run. The agent researches only through its allowlisted tools, updates the
participant as it moves through the work, and saves a concise final comparison
they can revisit later.

An interactive, token-by-token chat belongs in the request path; start with
[Vercel AI chat with server-side tools](vercel-ai-chat.md) for that. Use this
guide when the work may take time, needs multiple steps or retries, continues
without an open browser, or must report progress outside a chat stream.

## 1. Define one agent and its boundaries

Before adding infrastructure, write down the agent’s:

- **Outcome:** a specific result the participant can review, such as a research
  brief, an import summary, or proposed content.
- **Starter:** an authenticated participant action, a trusted webhook/system
  event, a schedule, or a combination. A schedule is not permission to act on
  every user’s data; define the eligible owner and records explicitly.
- **Inputs:** the small, validated data it needs. Store the authoritative input
  in PostgreSQL; put only stable IDs in events.
- **Tools:** a narrow allowlist, each scoped to the owning participant. Do not
  give a model shell access, unrestricted database access, arbitrary web
  publishing, or permission to spend money.
- **Limits:** maximum model/tool steps, elapsed time, retries, concurrency, and
  spend per participant or run.
- **End states:** `queued`, `running`, `awaiting_approval`, `completed`,
  `failed`, and optionally `cancelled`.

An agent may draft or propose an external action. It must not send email,
publish content, change a Shopify product, make a purchase, or modify an
account until the participant approves the exact proposed action through a
separate authenticated route.

## 2. Create the Inngest project

1. Create an Inngest project owned by the participant or organization that
   owns this application and its operating costs.
2. Store project keys only as server-side local/Vercel environment variables:

   ```dotenv
   INNGEST_EVENT_KEY=<store only in the selected secret store>
   INNGEST_SIGNING_KEY=<store only in the selected secret store>
   ```

3. Install the reviewed packages. `zod` validates the event, tool, and
   realtime-update shapes.

   ```bash
   npm install inngest zod
   ```

4. During local development, use the Inngest Dev Server and connect it to the
   Next.js endpoint added below. Do not expose a local server publicly to make
   this work.

The [Inngest Next.js quickstart](https://www.inngest.com/docs/getting-started/nextjs-quick-start)
shows the current App Router connection pattern. Inngest functions are durable
background logic triggered by events, schedules, or webhooks.

## 3. Record a participant-owned agent run

Create a Prisma model for the run before emitting an event. It gives the UI a
stable run ID, makes ownership enforceable, and keeps the event payload small.

```prisma
model AgentRun {
  id             String   @id @default(cuid())
  userId         String
  agentType      String
  status         String   @default("queued")
  input          Json
  progress       String?
  result         Json?
  errorCode      String?
  createdAt      DateTime @default(now())
  updatedAt      DateTime @updatedAt

  @@index([userId, createdAt])
}
```

Make the migration with `npm run db:migrate:dev -- --name add_agent_runs`,
review it, and commit it before production. Keep `input`, `progress`, and
`result` small and participant-safe. Never store API keys, session data,
connection URLs, hidden prompts, or raw provider diagnostics.

## 4. Start a run from a user, event, or schedule

Create one server-only Inngest client and typed events. The event carries the
run ID and the already-authorized owner ID—not the full prompt or a model-chosen
user ID.

```ts
import { EventSchemas, Inngest } from "inngest"

export const inngest = new Inngest({
  id: "<your-app-id>",
  schemas: new EventSchemas().fromRecord<{
    "agent/run.requested": { data: { runId: string; userId: string } }
    "agent/run.approved": { data: { runId: string; userId: string } }
  }>(),
})
```

For a user-started run, the authenticated Next.js route or server action must:

1. resolve the Better Auth session;
2. validate the assignment and agent type;
3. create `AgentRun` using `session.user.id`;
4. send `agent/run.requested`; and
5. return `{ runId, status: "queued" }` immediately.

For a trusted system event or schedule, first resolve the intended owner and
eligible application record on the server, then create the same `AgentRun`.
Do not make a cron event operate on every participant by default. Inngest also
supports schedule-triggered functions and delayed steps when that timing is a
deliberate product decision.

## 5. Run the agent in durable, bounded steps

Load the run by both ID and owner ID. Split meaningful work into named steps so
Inngest can retry from the last completed checkpoint rather than repeat the
whole agent run.

```ts
export const runResearchAgent = inngest.createFunction(
  {
    id: "run-research-agent",
    concurrency: [{ limit: 2 }],
    retries: 2,
  },
  { event: "agent/run.requested" },
  async ({ event, step }) => {
    const run = await step.run("load-owned-run", () =>
      prisma.agentRun.findFirstOrThrow({
        where: { id: event.data.runId, userId: event.data.userId },
      }),
    )

    await step.run("mark-running", () =>
      prisma.agentRun.update({
        where: { id: run.id },
        data: { status: "running", progress: "Starting research" },
      }),
    )

    const result = await step.run("research-with-allowlisted-tools", async () => {
      // Invoke a model/agent with strict time, tool-call, and cost budgets.
      // Each tool must enforce the owner and its own narrow input schema.
      return { summary: "<safe participant-visible research summary>" }
    })

    await step.run("save-result", () =>
      prisma.agentRun.update({
        where: { id: run.id },
        data: { status: "completed", progress: null, result },
      }),
    )
  },
)
```

Every external mutation must be idempotent with a run-derived key, because a
durable function can retry after an interruption. Use a small retry count and a
clear terminal failure state; never retry forever.

## 6. Report progress to the participant

Save durable status to `AgentRun` for history and recovery. For live updates
while the participant has the app open, use Inngest Realtime with a channel
scoped to the run ID, and mint the subscription token only after checking that
the current Better Auth user owns that run.

Publish safe milestones such as “Gathering sources,” “Comparing options,” or
“Ready for review.” Do not stream secrets, hidden instructions, raw tool
output, provider errors, or private data from another user.

Within a function, prefer `step.realtime.publish()` for important state changes
and final results: it is durable and will not publish the same milestone again
when the function retries. Use non-durable publishes only for deliberately
high-frequency updates such as token or progress ticks.

The client may use a short authenticated poll as a simple first version. For a
live activity panel, use the current Inngest v4 `useRealtime` flow: define a
channel, mint a server-side scoped subscription token, and subscribe only to
the run’s approved topics. See [Inngest Realtime](https://www.inngest.com/docs/features/realtime)
and its [React hooks guide](https://www.inngest.com/docs/features/realtime/react-hooks).

## 7. Support approvals, cancellation, and recovery

When an agent reaches an action that changes an external system:

1. save `awaiting_approval` and the participant-visible proposal;
2. publish that state to the run owner;
3. show the exact action, target, and consequence in the UI;
4. accept a separate authenticated approve/reject request; and
5. emit a separate approved event only after approval.

For cancellation, mark the owned run as `cancelled` and make every subsequent
agent step check that state before acting. For failure, store a safe error code
and recovery message, such as “The research provider was unavailable; try
again.” Keep diagnostic detail in the provider/Inngest dashboard, not the
participant response.

## 8. Expose and verify the function

Add the Inngest App Router handler. It is for Inngest’s signed protocol, not a
public endpoint for running arbitrary agents.

```ts
import { serve } from "inngest/next"
import { inngest } from "@/lib/inngest/client"
import { runResearchAgent } from "@/lib/inngest/functions"

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [runResearchAgent],
})
```

Before release:

1. Start one run from an authenticated test account and confirm it reaches a
   terminal state in both the UI and Inngest dashboard.
2. Confirm another account cannot view, subscribe to, approve, cancel, or
   trigger that run by guessing its ID.
3. Cause one safe transient failure and confirm a bounded retry resumes from
   the appropriate step without duplicating an external action or update.
4. Confirm `awaiting_approval` cannot perform the proposed action before the
   owning participant approves it.
5. Confirm a scheduled/system starter selects only its intended owner and
   records why it started.
6. Run `npm run lint`, `npm run typecheck`, `npm run test:quality`, then use
   the normal reviewed production deployment workflow.

Set per-user concurrency and spending limits before broadening the agent’s
toolset or audience. The [Inngest Functions guide](https://www.inngest.com/docs/learn/inngest-functions)
explains durable triggers and step-level recovery.
