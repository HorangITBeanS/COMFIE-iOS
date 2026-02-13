# Git Convention

## 1) Branch Structure & Rules

### Default Branches
- `main`: Release (production)
- `develop`: Integration (development baseline)

### Working Branch Principles
- Always start new work on a **new branch**.
- Do **not** commit directly to `main`, `develop`, or `dev`.
- Merge all working branches into `develop`.
- Merge releases into `main`.
- When starting implementation (e.g., dev work), if you are on a protected branch (`main` / `develop` / `dev`), **create a working branch immediately**.

### Branch Naming (Recommended)
- `feature/<key>-<short-description>`
- `bugfix/<key>-<short-description>`
- `release/<version>`

Examples:
- `feature/ABC-123-profile-edit`
- `bugfix/ABC-456-login-crash`
- `release/1.2.0`

---

## 2) Commit Convention

### Commit Message Format
```text
<type>: <summary>

<optional body>
```

### Allowed Types
- `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### Rules
- Keep `type` in **English**.
- Write the subject/body in **English**.
- Keep the subject concise and clearly describe the intent of the change.

Examples:
- `feat: add profile edit`
- `fix: handle missing error message on login failure`
- `refactor: extract profile validation logic`

---

## 3) Related Docs

- PR preparation, writing, and review rules are defined in:
  - `./docs/git/pr-convention.md`
