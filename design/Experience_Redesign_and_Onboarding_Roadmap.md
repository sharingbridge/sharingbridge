# Experience redesign and onboarding roadmap

**Purpose:** Capture near-term product priorities before implementation work starts. This roadmap is intentionally UX-first and pushes detailed forecasting to later phases.

**Status:** Planning backlog (not implemented).

**Related docs:** [PRODUCT_MODEL.md](../development/PRODUCT_MODEL.md), [STATUS.md](../development/STATUS.md), [ENGINEERING_PLAN.md](../development/ENGINEERING_PLAN.md)

---

## 1) Priority decision (agreed)

1. **Redesign web and mobile experience first** (information architecture, flow split, role clarity, less scrolling).
2. **Then onboarding for kitchens and suppliers** with transparency acknowledgements and proof artifacts.
3. **Then mentor workflows** for training materials and certification support.
4. **Forecasting last**, or in two stages:
   - **Lite forecast first** (portion-level demand trend from existing demand board data)
   - **Detailed forecast later** (recipe/BOM-based ingredient projection)

---

## 2) Current UX pain points

### Terminology drift

- Product language is moving to **initiator**, but UI/code still contains many **donor** labels and module names.
- This creates trust and comprehension friction for new users.

### Navigation and density

- Web dashboard mixes multiple tasks into one long page and encourages repeated vertical scrolling.
- Actions workflow currently combines multiple operational sections into a single surface.
- Mobile has functional flows but should be split more clearly by step and user intent.

### Recommended UX objective

Move from "single dense dashboard" to "journey-based views":
- one primary task per view,
- fewer stacked panels,
- clear role-aware navigation.

---

## 3) Proposed UX redesign scope

## Web (high priority)

- Split dashboard into route-level areas (for example: Initiations, Actions, Connection, Map).
- Keep Actions focused on operational execution (demand lines, pledges, kitchen commitments).
- Keep Connection as a dedicated lookup and handoff surface.
- Reduce nested scrolling; use stable page chrome with a single content scroll region.
- Replace residual donor-facing copy with initiator-facing copy in user-visible strings.

## Mobile (high priority)

- Keep home simple and role-clear.
- Convert long workflows into step-based pages (route selection, beneficiary details, consent/review).
- Add in-app Connection access (to reduce dependence on web dashboard for this step).
- Align copy and labels with the initiator vocabulary.

---

## 4) Kitchen and supplier onboarding (after UX split)

### Transparency acknowledgements

Onboarding should capture explicit acknowledgements and visible evidence for quality/transparency:

- Ingredient purchase receipts
- Training certificates for food prep, hygiene, and order delivery process
- Recent photos of wastage removal process
- Optional live streaming links for food prep and kitchen environment visibility

### Packaging and menu policy

- Enforce "100% non-plastic packaging" attestation.
- Restrict menu items that require separate liquid packing likely to depend on plastic/polythene covers.
- Examples to exclude as separate packs: rasam, buttermilk, curd.

### Suggested delivery shape

- Onboarding state machine: draft -> submitted -> approved -> active.
- Profile page with transparency artifacts and last-updated indicators.
- Periodic refresh reminders for expiring/aging proofs (certificates, recent process photos).

---

## 5) Mentor role and training materials

Mentors should be able to sign in and manage learning assets for kitchens and suppliers:

- Upload or link training docs/videos.
- Organize materials by audience (kitchen, supplier) and topic (hygiene, preparation, delivery, packaging).
- Optionally require completion evidence during onboarding.

Minimum viable mentor phase:
- basic content publishing,
- assignment by role/type,
- acknowledgement tracking.

---

## 6) Forecasting roadmap (deferred)

### Phase F-lite (earlier, lightweight)

Build a compact dashboard view from existing demand-board data:
- locality-level and offer-level demand trend,
- pledged vs committed portions,
- near-term windows (for example next 24h/72h/7d).

No recipe/BOM dependency in this stage.

### Phase F-full (later)

Add recipe/BOM-aware forecasting:
- map standard offers to ingredients and quantities per portion,
- project ingredient demand for vendors/suppliers,
- support procurement and prep planning views.

This phase should follow UX redesign and onboarding role maturity.

---

## 7) Proposed implementation order

1. UX-A: terminology pass in visible UI copy (`donor` -> `initiator` where appropriate).
2. UX-B: web route split and reduced-scroll layouts.
3. UX-C: mobile step-based flow polish and in-app Connection lookup.
4. O-1: kitchen/supplier onboarding basics with policy acknowledgements.
5. O-2: mentor materials publishing and assignment.
6. F-1: lightweight forecast.
7. F-2: detailed BOM forecast.

---

## 8) Notes for future technical design

- Keep role model explicit (`initiator`, `coordinator`/`configurator`, future `kitchen`, `supplier`, `mentor`).
- Treat transparency artifacts as versioned records with timestamps and reviewer metadata.
- Keep forecast dependencies modular so F-lite can ship before BOM schema work.
