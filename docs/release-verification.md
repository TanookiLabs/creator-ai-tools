# Release verification

Run the static release gate from a fresh checkout before requesting an
assistant-led production deployment:

```bash
npm run verify
```

The command runs ESLint, TypeScript, Prisma schema validation, the production
build, and a production dependency audit. It does not modify the database.

The build and this verification command do not modify the database. If a
reviewed migration is needed, the assistant requests a separate fresh
production-migration confirmation after drift and recovery checks, then runs it
once:

```bash
npm run db:migrate
```

## Browser scenario

Use a new browser profile or incognito window at the selected canonical HTTPS
production `BETTER_AUTH_URL`. Use a unique `@example.test` address for the
account-creation step so the scenario is repeatable without affecting a real
user.

1. Visit `/dashboard` while logged out. Confirm the route redirects to
   `/sign-in` with a `callbackUrl` for the requested dashboard URL.
2. On `/sign-in`, submit an unknown email and password. Confirm the page shows
   `Invalid email or password` and remains usable.
3. On `/sign-up`, create an account with a password of at least six characters.
   Confirm the browser reaches `/dashboard`.
4. Submit the same sign-up details again. Confirm the response says the user
   already exists and instructs the visitor to use another email.
5. Open the account menu, select **Sign out**, then revisit `/dashboard`.
   Confirm the logged-out redirect. Sign in with the newly created account and
   confirm the dashboard returns.
6. In DevTools, temporarily make `localStorage.getItem`, `setItem`, and
   `removeItem` throw. Reload `/dashboard`; confirm the Resource hub links are
   present and a build path can still be selected with Tab then Enter.
7. Check the dashboard at 1440x900, 768x1024, and 375x812. Confirm there is no
   horizontal overflow and the header, checklist, and Resource hub remain
   reachable. Review the console and network panels: the completed flow must
   have no console errors or failed application requests.

The dashboard's first-run checklist is deliberately browser-local and optional;
storage errors must never block the resource links or in-session checklist UI.

Report concise, redacted smoke evidence; never include secret values or
connection strings. If any observation fails, stop further mutations. A code-only rollback may redeploy the prior compatible
application artifact with participant direction, but must not alter the
database; database recovery is a separate owner-approved incident.
