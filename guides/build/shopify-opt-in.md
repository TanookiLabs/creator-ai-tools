# Shopify integration (opt-in example)

Shopify is an optional example, not a starter dependency or an enabled connection. Choose it only when the product requires Shopify data or events and the store owner has approved the specific access.

## Prerequisites

- A documented use case identifying the required store data, actions, and webhook events.
- Approval from the Shopify store owner and an owner-managed development store or test environment.
- Review of Shopify's current official API, authentication, privacy, and app-distribution requirements.

## Ownership

The store owner creates and controls the Shopify app, credentials, scopes, installation, billing, and revocation. The application team owns data minimization, authorization, retention, deletion, monitoring, and support. An agent must not create a Shopify account, app, token, installation, or webhook subscription automatically.

## Workflow

1. Decide whether public storefront data is sufficient. Do not request authenticated Admin API access when it is unnecessary.
2. Document the minimum scopes and events, the data owner, retention period, and uninstall/deletion behavior.
3. Have the owner create the app and provide credentials through approved secret stores. Use placeholder names such as `SHOPIFY_CLIENT_ID` and `SHOPIFY_CLIENT_SECRET` in documentation only.
4. Implement the integration server-side using the current official Shopify documentation. Keep credentials and Admin API responses out of client bundles and logs.
5. For events, follow [APIs and webhooks](apis-and-webhooks.md): verify signatures from the raw request body, acknowledge promptly, process idempotently, and support replay.
6. Test against owner-controlled non-production data before requesting production installation.

## Verify

- The integration remains disabled when its configuration is absent.
- Only approved scopes, stores, and events are used.
- Invalid signatures are rejected; duplicate valid events do not duplicate side effects.
- Removing the installation or credentials stops access, and the documented deletion flow works.

## If it fails

- Disable the optional integration without blocking the core application.
- For authorization or scope errors, have the owner review the app configuration; do not broaden scopes as a shortcut.
- For suspected credential exposure, stop requests, ask the owner to revoke and rotate the credential, and remove sensitive material from logs and history through the repository's incident process.
