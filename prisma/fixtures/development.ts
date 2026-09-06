import { randomUUID } from "node:crypto"

import { PrismaClient } from "@prisma/client"
import { betterAuth } from "better-auth"
import { prismaAdapter } from "better-auth/adapters/prisma"

if (process.env.NODE_ENV !== "development" || process.env.ALLOW_LOCAL_FIXTURES !== "true") {
  throw new Error(
    "Local fixtures are disabled. Run `npm run db:seed:local` only against a local development database.",
  )
}

const prisma = new PrismaClient()

const auth = betterAuth({
  database: prismaAdapter(prisma, { provider: "postgresql" }),
  emailAndPassword: { enabled: true },
})

const fixtures = [
  { name: "Local Fixture One", email: "local-fixture-one@example.test" },
  { name: "Local Fixture Two", email: "local-fixture-two@example.test" },
]

async function main() {
  let created = 0

  for (const fixture of fixtures) {
    const existing = await prisma.user.findUnique({ where: { email: fixture.email } })

    if (existing) {
      continue
    }

    const password = randomUUID()
    await auth.api.signUpEmail({ body: { ...fixture, password } })
    created += 1
    console.log(`Created ${fixture.email} with a generated local-only password: ${password}`)
  }

  console.log(created === 0 ? "Local fixtures already exist; no changes made." : "Local fixtures created.")
}

main()
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
