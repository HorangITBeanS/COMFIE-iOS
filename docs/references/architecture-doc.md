# ARCHITECTURE doc

> This document is a **reference guide** for writing the project's `ARCHITECTURE.md`.
> It is **not** the architecture document itself.

**Goal**
Help recurring contributors/reviewers quickly answer:
- “Where do I change this?”
- “What does the thing I’m looking at do?”

**Core rules**
- Keep it **short** and write only things that **don’t change often**.
- Do **not** try to keep this in 1:1 sync with code.
- Prefer naming important files/modules/types, but avoid links (links go stale). Use symbol search.
- State **architectural invariants** explicitly (often expressed as “there is no X”).
- Document **boundaries** explicitly (good boundaries are hard to discover by randomly reading code).
- Revisit the doc only occasionally (e.g., a couple of times a year), not on every change.

---

## 0) Scope

### Audience
- Recurring contributors
- Reviewers for large or cross-cutting changes

### Non-goals
- Detailed “how it works internally” for each module
- Tutorials / API reference
- Exhaustive lists of every function/type/file

Rule of thumb:
- This document is a **country map**, not an atlas.

---

## 1) Update policy

- Do not update this doc for every change.
- Revisit on a slow cadence (e.g., twice a year).
- If a section drifts toward fast-changing details, delete/shorten it.
- If in doubt: remove detail and keep only stable constraints and navigation pointers.

---

## 2) Bird’s-eye view

Write a brief high-level overview to anchor the reader’s mental model.

### 2.1 System overview (1–2 paragraphs)
- What is the system at the highest level?
- What does it accept and what does it produce?

### 2.2 Inputs → Outputs (Ground vs Derived)
- **Inputs (ground state):** authoritative facts the system consumes (source of truth)
- **Outputs (derived state):** everything computed from inputs (rebuildable caches/models/artifacts)

Example shape:
- Input: `<input facts / shapes>`
- Output: `<derived state / artifacts>`

### 2.3 Update model
- What constitutes a “small change”?
- How does the system react (incremental? lazy/on-demand?)?

---

## 3) Entry points

List onboarding-friendly starting points to read code.

- Main entry point(s): `<path(s)>`
- Request/command handling entry points: `<path(s)>`
- Main façade API type(s): `<type/module names>`

Guideline:
- Use **real names** (paths/types), not placeholders.

---

## 4) Code map

The code map must answer:
1) “Where is the thing that does X?”
2) “What does the thing I’m looking at do?”

### 4.1 Top-level repository map
List the major directories/modules/packages:

- `/<dir-or-package-1>`: one-line description
- `/<dir-or-package-2>`: one-line description
- `/<dir-or-package-3>`: one-line description

Sanity check:
- Things that should be close conceptually should also be close in the repo layout.

### 4.2 Major components (coarse-grained)

For each major component, keep it short (~3–7 bullets):

#### Component: `<real name>`
- Responsibility: …
- Owns (data/state): …
- Depends on: …
- Must **not** depend on: …
- Boundary status: (Is this an API/boundary surface?)
- Key invariants: …

---

## 5) Architectural invariants

Important invariants are often best expressed as **absence** (“there is no X”).
State them explicitly because they are hard to infer from code.

Use this shape:

**Architecture Invariant:** <rule / forbidden dependency / absence>
- Rationale: <why it matters>
- Enforced by: <module boundary / type system / tests / conventions>
- Violation symptoms: <what breaks if violated>

Guideline:
- Aim for ~3–7 invariants. Keep only the foundational ones.

---

## 6) Boundaries & API surfaces

Document boundaries because they are hard to find by randomly reading files.

### 6.1 Boundary list
- Boundary surface A: `<module/path>`
  - What crosses this boundary?
  - What is forbidden to cross?
- Boundary surface B: `<module/path>`
  - …

### 6.2 Boundary rules (“only here”)
Fill in the places where special rules apply:

- Serialization / DTO conversion happens in: `<module/path>` (only here)
- IO happens in: `<module/path>` (only here)
- Protocol handling happens in: `<module/path>` (only here)

---

## 7) Cross-cutting concerns

After the code map, add cross-cutting concerns as a separate section.
Include only stable, project-defining topics.

Suggested topics (pick only what matters):
- Code generation (what, how, policy)
- Cancellation / stale work handling (if applicable)
- Testing strategy organized by boundaries
- Error handling strategy

Guideline:
- Keep each subsection short; if it grows, move details elsewhere.

---

## 8) Writing constraints (keep it maintainable)

- Prefer naming files/modules/types; avoid links (use symbol search).
- Avoid module-internal implementation details.
- Keep it short and stable; delete detail when it stops being stable.

