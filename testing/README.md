# SharingBridge Testing Docs

Living folder for testing direction across the SharingBridge repos. Each
document is scoped so contributors can verify a specific slice of the
system without reading code.

## Index

- [`MANUAL_TESTING_GUIDE.md`](./MANUAL_TESTING_GUIDE.md) — step-by-step
  validation of shipped **donor-setup** modules (integration-service +
  **ai-orchestration** deterministic MVP + mobile + web dashboard): automated
  `pytest` / `npm test` / `flutter test` / Vitest; manual API smoke
  (three-service stack); **§3** mobile E2E; **§4** web coordinator dashboard (Google Sign-In);
  **§6** hosted Render smoke.
- [`../configuration/e2e-deployment-sequence.md`](../configuration/e2e-deployment-sequence.md) —
  configure Google OAuth, `.env`, and Render **before** §4 hosted tests.

## Conventions

- One guide per logical scope (per feature, per cross-cutting concern,
  or per release). Keep guides task-oriented: "do these steps, expect
  this outcome".
- Reflect both **automated** and **manual** validation paths.
- Update the matching guide in the same PR/commit that ships a feature
  change so steps never drift from reality.
- Reference exact file paths and commands; assume PowerShell on
  Windows unless a guide states otherwise.

## Related

- Implementation status & runbook: [`../development/AGENT_SESSION.md`](../development/AGENT_SESSION.md)
- API contracts: [`../design/contracts/donor_setup_suggest_vendors.openapi.yaml`](../design/contracts/donor_setup_suggest_vendors.openapi.yaml) (suggest-vendors)
- AI platform: [`../development/AI_AS_BUILT.md`](../development/AI_AS_BUILT.md)
- End-to-end product workflow (diagrams): [`../design/SharingBridge_End_to_End_Workflow.md`](../design/SharingBridge_End_to_End_Workflow.md)
- Vendor preset setup sequence: [`../design/Donor_Setup_AI_Search_Sequence.md`](../design/Donor_Setup_AI_Search_Sequence.md)
