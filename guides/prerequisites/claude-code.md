# Claude CLI recovery

Claude Desktop Code is the primary interface for this macOS onboarding. See the
[Claude Desktop handoff and recovery guide](claude-desktop.md) for setup,
exact-root confirmation, first prompt, and troubleshooting.

The normal Claude CLI is retained only as a secondary recovery path when
Desktop cannot complete the handoff and the participant's account permits CLI
access:

```bash
cd "/absolute/path/printed/as/Project root verified"
pwd -P
claude
```

Compare `pwd -P` with `FIRST_APP_HANDOFF.md`, read `CLAUDE.md`, and keep normal
permission prompts enabled. Authentication and folder access remain
participant-controlled. This release provides no Windows or Linux parity path.
