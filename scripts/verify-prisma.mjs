import { spawnSync } from "node:child_process"

const fixtureUrl = (name) => ["postgresql:", `//validation:fixture@127.0.0.1:5432/${name}`].join("")
const result = spawnSync("npx", ["prisma", "validate"], {
  stdio: "inherit",
  env: {
    ...process.env,
    DATABASE_URL: process.env.DATABASE_URL ?? fixtureUrl("application"),
    DIRECT_URL: process.env.DIRECT_URL ?? fixtureUrl("application_direct"),
  },
})

if (result.error) throw result.error
process.exitCode = result.status ?? 1
