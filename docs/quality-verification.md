# Participant journey quality verification

Run the deterministic quality suite with:

```bash
npm run test:quality
```

The suite uses Node's existing test runner and disposable in-memory values only. It makes no database writes, creates no shared accounts, and calls no real integrations. It covers protected-route policy, safe auth return destinations, profile validation, Build Guide route/source integrity, neutral dashboard copy, recoverable states, and static keyboard/responsive contracts across the authenticated shell, dashboard, profile, and guides. `npm run verify` includes this suite.

## Browser automation gap

This repository does not currently include an end-to-end browser framework. The focused suite therefore cannot claim browser-executed signup, session-cookie, focus-order, or viewport-layout evidence. Per the repository constraint, this task does not silently add a second test framework. Until the project explicitly adopts one, verify the fresh-account journey locally with a unique throwaway address and remove that account afterward:

1. Start from a migrated disposable local database with `npm run dev`.
2. Open `/dashboard` while signed out; confirm `/sign-in?callbackUrl=%2Fdashboard` and safe recovery from invalid credentials.
3. Follow **Sign up**, create a unique account, and confirm return to the dashboard with no invented project or activity data.
4. Use Tab, Shift+Tab, Enter, and Space through shell navigation, dashboard links, profile fields/save, Build Guide cards/details, retry actions, and sign out. Confirm visible focus and logical order.
5. Update the profile, reload it, visit `/resources` and a guide detail, then sign out. Confirm protected URLs return to sign-in.
6. Repeat shell, dashboard, profile, and guides at 320 px, 768 px, and 1280 px widths; confirm no horizontal overflow, overlap, clipping, or unreachable controls.

Never use a shared demo account, staging/production database, or enabled third-party integration for this check.
