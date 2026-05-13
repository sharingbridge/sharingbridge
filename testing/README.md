# ShareBridge Testing Docs

Living folder for testing direction across the ShareBridge repos. Each
document is scoped so contributors can verify a specific slice of the
system without reading code.

## Index

- [`MANUAL_TESTING_GUIDE.md`](./MANUAL_TESTING_GUIDE.md) — step-by-step
  validation of every donor-setup module that has shipped so far:
  automated suites in `sharingbridge-integration-service` and
  `sharingbridge-mobile-app`, manual API smoke tests, and an end-to-end
  walkthrough on Windows desktop / Android emulator.

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

- Implementation status & runbook: [`../development/AGENT_HANDOFF.md`](../development/AGENT_HANDOFF.md)
- API contract: [`../design/contracts/donor_setup_suggest_vendors.openapi.yaml`](../design/contracts/donor_setup_suggest_vendors.openapi.yaml)
- Donor setup sequence: [`../design/Donor_Setup_AI_Search_Sequence.md`](../design/Donor_Setup_AI_Search_Sequence.md)
