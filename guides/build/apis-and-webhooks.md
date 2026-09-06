# APIs and webhooks

Use this workflow for any opt-in, user-owned external API. Prefer the project's existing Server Actions for application operations; add a public route handler only when an external service must call an HTTP endpoint, such as a webhook.

## Prerequisites

- The owner has approved the provider, account, intended data, costs, and minimum permissions.
- Current official API documentation defines authentication, versioning, limits, webhook signing, retries, and test facilities.
- The team has identified data classification, retention, deletion, and an integration-disabled behavior.

## Ownership

The provider account owner provisions and revokes credentials and webhook subscriptions. The application team owns authorization, validation, idempotency, observability, and incident response. Integrations are never implied by a guide and must not be enabled automatically.

## Workflow

1. Define the smallest request/response contract, permissions, timeouts, retry policy, rate-limit behavior, and user-visible failure state.
2. Store provider credentials as described in [Environment variables and secrets](environment-variables-and-secrets.md). Keep calls requiring secrets on the server.
3. Validate outbound inputs and untrusted responses. Set bounded timeouts; retry only transient, idempotent work with backoff.
4. For webhooks, expose the narrowest route, read the raw body, verify the provider signature and timestamp before parsing or acting, and reject invalid requests.
5. Return the provider-required acknowledgement promptly. Move slow work behind a durable mechanism when one already exists; do not introduce infrastructure without approval.
6. Store or derive an event idempotency key before side effects. Handle duplicates, out-of-order delivery, retries, and replay without duplicating work.
7. Log correlation identifiers, outcome, and timing—not credentials, authorization headers, signatures, or sensitive payloads.

## Verify

- Unit tests cover success, timeout, malformed data, unauthorized responses, invalid signatures, duplicates, and out-of-order events.
- Provider-owned test tools or fixtures exercise a non-production account; no real customer data is required.
- The integration can be disabled or credentials revoked without breaking unrelated application paths.
- Monitoring distinguishes provider failure, rejected webhook, retry, and completed processing without leaking sensitive data.

## If it fails

- Disable or isolate the integration, preserve redacted request IDs and timestamps, and keep the core app usable.
- Do not bypass signature verification, broaden permissions, or add unbounded retries to restore service.
- For compromised credentials, ask the account owner to revoke and rotate them. For missed events, use the provider's documented replay or reconciliation process after fixing idempotency.
