# Resend email setup

Use this guide to plan and implement transactional email with Resend in this
Next.js, Better Auth, Prisma, and PostgreSQL application. It covers account
setup, sender identity, secure configuration, and the narrow server-side
integration needed to send email. It does **not** create a Resend account,
change DNS, install a package, add credentials, or send email for you.

## What this app can do today

The starter currently supports Better Auth email/password sign-up and sign-in.
It does not send email yet: `lib/auth.ts` has no `sendVerificationEmail` or
`sendResetPassword` callback, the Resend SDK is not installed, and there is no
password-reset page. Adding `RESEND_API_KEY` alone therefore changes nothing.

Choose the user outcome before adding email. Two good first use cases are:

| Use case | What the recipient receives | Application work required |
| --- | --- | --- |
| Welcome a new participant | A short introduction and a clear next action after account creation | Resend sender, a server mailer, and one reliable post-sign-up trigger. |
| Verify a new account | A one-time Better Auth verification link | Resend sender, a server mailer, `sendVerificationEmail`, and a tested return path. |
| Reset a password | A one-time Better Auth reset link | The above, `sendResetPassword`, a reset page, and a tested reset flow. |

Welcome messages, invitations, receipts, product notifications, and marketing
campaigns are separate features. Do not add marketing email or contact-list
automation under the guise of authentication mail; those flows need their own
consent, unsubscribe, audience, and retention decisions.

## Before you begin

- Own a domain or subdomain you can edit in DNS. A dedicated sending subdomain,
  such as `updates.example.com`, keeps transactional mail separate from the
  main website’s reputation.
- Decide who owns Resend billing, domain DNS, the production Vercel project,
  and recovery from a failed or compromised email setup.
- Decide the sender users will recognize and can reply to, for example
  `Support <support@updates.example.com>`.
- Keep the worktree clean and review the proposed Better Auth/UI changes before
  adding an email dependency or configuration.

For a local proof of the Resend API, its default test sender may only deliver
to the email address associated with your Resend account. A verified domain is
required before sending to other recipients. See [Resend’s sender guidance](https://resend.com/docs/knowledge-base/403-error-resend-dev-domain).

## 1. Create and verify the Resend sending domain

1. Create or sign in to your Resend account at [resend.com](https://resend.com).
2. In **Domains**, add the domain or sending subdomain chosen above.
3. Copy the exact DNS records Resend shows into the DNS provider for that
   domain. Do not guess record names or overwrite an existing SPF record.
4. Wait until the Resend domain status is **verified** before using it in a
   `from` address.
5. Record only the domain and sender name in your project planning notes—never
   record generated DNS values, API keys, or passwords in Git or chat.

Resend verifies sender domains with SPF and DKIM records and recommends DMARC
as an additional trust signal. It also lets you send from any address at a
verified domain without separately creating every sender address. Read
[Resend’s domain documentation](https://resend.com/docs/dashboard/domains/introduction)
and [sender guidance](https://resend.com/docs/knowledge-base/how-do-I-create-an-email-address-or-sender-in-resend)
before changing DNS.

## 2. Create a least-privilege API key

In Resend, create a new API key for this application and environment. Give it
a clear name such as `my-app-production-send`. Select the narrowest permission
that supports sending email, and scope it to the verified sending domain when
Resend offers that option.

The key is shown only once. Store it directly in the destination environment:

- **Local development:** your ignored `.env` file, only if you are deliberately
  testing email locally.
- **Vercel production:** the Vercel project’s **Production** environment
  variable settings, marked sensitive/write-only when available.

Use these names; they are server-only and must never use a `NEXT_PUBLIC_`
prefix:

```dotenv
RESEND_API_KEY=<store the Resend key only in the selected secret store>
EMAIL_FROM=Support <support@updates.example.com>
```

Do not run `vercel env pull .env.local` to obtain this key. It would leave a
production credential in a local file. For the manual release sequence, see
[Manual Vercel deployment](manual-vercel-deployment.md).

## 3. Add one server-only mailer

After the account, sender, and environment values are ready—and only after the
implementation is reviewed—add the official SDK:

```bash
npm install resend
```

Keep the SDK behind one server-only module, for example `lib/email.ts`. Client
components, browser routes, and `NEXT_PUBLIC_` variables must never import or
receive the API key. The module should accept a recipient, subject, plain-text
body, and HTML body; return only Resend’s message ID or a safe error to its
caller; and never log a key, message body, reset token, or raw recipient list.

The core shape is:

```ts
import { Resend } from "resend"

const resend = new Resend(process.env.RESEND_API_KEY)

export async function sendTransactionalEmail(input: {
  to: string
  subject: string
  text: string
  html: string
}) {
  const { data, error } = await resend.emails.send({
    from: process.env.EMAIL_FROM!,
    to: [input.to],
    subject: input.subject,
    text: input.text,
    html: input.html,
  })

  if (error) throw new Error("Email delivery request failed")
  return data?.id
}
```

Treat the `EMAIL_FROM` value as reviewed configuration, not user input. Resend
requires a sender, recipient, subject, and body; including a plain-text version
alongside HTML improves accessibility and deliverability. Its API returns a
message ID that is safe to retain for diagnostics. See [Resend’s send-email
reference](https://resend.com/docs/api-reference/emails/send-email).

## 4. Connect the chosen Better Auth flow

For account verification, add a Better Auth `emailVerification` callback that
passes the framework-generated URL to the server mailer. For password recovery,
add `emailAndPassword.sendResetPassword` and build the corresponding reset
page before enabling that UI. Use the `url` supplied by Better Auth; do not
assemble tokens or redirects yourself.

Illustrative server configuration:

```ts
emailVerification: {
  sendVerificationEmail: async ({ user, url }) => {
    void sendTransactionalEmail({
      to: user.email,
      subject: "Verify your email address",
      text: `Verify your email address: ${url}`,
      html: `<p><a href="${url}">Verify your email address</a></p>`,
    })
  },
},
emailAndPassword: {
  enabled: true,
  sendResetPassword: async ({ user, url }) => {
    void sendTransactionalEmail({
      to: user.email,
      subject: "Reset your password",
      text: `Reset your password: ${url}`,
      html: `<p><a href="${url}">Reset your password</a></p>`,
    })
  },
},
```

Do not turn on `requireEmailVerification` until verification delivery, the
callback URL, error states, and re-send behavior have been tested. Better Auth
recommends avoiding a synchronous wait for sending verification or reset email
to reduce timing attacks; on serverless infrastructure, use a supported
background-completion mechanism so the work is not discarded. Its [email and
password guide](https://better-auth.com/docs/authentication/email-password)
documents the callback payloads, verification requirement, and reset flow.

## Welcome email example

A welcome email is a good first transactional message because it does not gate
access to the app or carry a security token. Send it only after Better Auth has
created the user record; never trigger it from the browser sign-up component.
The appropriate integration point is `databaseHooks.user.create.after` in
`lib/auth.ts`:

```ts
databaseHooks: {
  user: {
    create: {
      after: async (user) => {
        // Enqueue or dispatch a server-side welcome email for this new user.
      },
    },
  },
},
```

The first version should remain short and useful:

```text
Subject: Welcome to My App

Hi [first name],

Your account is ready. Start by visiting your dashboard to complete your first task.

Need help? Reply to this email.
```

Use the stored account name only after applying safe display handling; do not
include a password, verification/reset token, database data, or a hidden
tracking identifier. Link only to the canonical HTTPS dashboard origin. Make
the sender a monitored reply-capable address when possible.

Before treating the send as reliable, decide its delivery semantics. A simple
best-effort welcome can be dispatched after user creation and record only the
safe Resend message ID. For a promise such as “every new account gets exactly
one welcome,” add a reviewed database-backed outbox or send record keyed by the
user ID, with a committed migration and an idempotency key such as
`welcome:<user-id>`. Do not rely on a client-side flag or an unbounded retry
loop to prevent duplicates. Better Auth documents its post-create database hook
in the [database hooks reference](https://better-auth.com/docs/concepts/database).

## 5. Verify before releasing

Run the ordinary application checks first:

```bash
npm run lint
npm run typecheck
npm run test:quality
```

Then test with accounts you control:

1. Send one verification email and confirm its sender uses the verified domain.
2. Open the link in a private browser window and confirm the expected callback
   page and authentication state.
3. Request one password reset, complete it, and confirm the old password no
   longer works while the new one does.
4. Inspect Resend delivery status and Vercel logs for the message ID and safe
   error category only—not credentials, reset URLs, or recipient values.
5. Confirm production variables are configured by name and that `.env.local`
   was not created or changed by deployment work.

For event-driven transactional messages that may be retried, define an
idempotency key tied to the application event before sending. Resend supports
an `Idempotency-Key` header to prevent duplicate send requests for 24 hours.
Do not add automatic retries to authentication email until failures and user
feedback are designed.

## If something fails

- **Resend reports an unverified domain:** stop and compare the exact SPF,
  DKIM, and MX records in the Resend dashboard with the DNS provider. Do not
  replace unrelated mail-provider records. Resend’s [domain troubleshooting
  guide](https://resend.com/docs/knowledge-base/what-if-my-domain-is-not-verifying)
  explains common record-location issues.
- **A key is exposed or used unexpectedly:** revoke it in Resend, create a
  replacement, update only the intended secret store, and review the incident.
  Do not paste either key into source control or a ticket.
- **A verification or reset email is not delivered:** stop requiring email
  verification, inspect the safe provider status and server error category, and
  confirm the callback origin matches `BETTER_AUTH_URL`.
- **A code rollback is needed:** redeploy compatible application code, but do
  not assume that rolling back code revokes already-issued verification or reset
  links. Treat secrets, recipient data, and authentication recovery as separate
  security decisions.
