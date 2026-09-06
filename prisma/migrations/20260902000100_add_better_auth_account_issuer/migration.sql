-- Better Auth 1.7 records the credential issuer for new accounts.
-- Nullable preserves compatibility with accounts created before this field.
ALTER TABLE "account" ADD COLUMN "issuer" TEXT;
