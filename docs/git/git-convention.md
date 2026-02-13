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
- Write the subject/body in **Korean**.
- Keep the subject concise and clearly describe the intent of the change.

Examples:
- `feat: 프로필 수정 기능 추가`
- `fix: 로그인 실패 시 누락된 에러 메시지 처리`
- `refactor: 프로필 유효성 검사 로직 분리`

---

## 3) PR Convention & Workflow

### Before Creating a PR
1. Review the entire commit history (don’t only look at the latest commit).
2. Review all changes:
   - `git diff [base-branch]...HEAD`

### PR Writing Rules
- Write the PR title and description in **Korean**.
- Recommended: use the same format as commit messages for the PR title  
  Example: `feat: 프로필 수정 기능 추가`

### Must Include in PR Description
- **Summary**: what changed and why (3–5 key lines)
- **Test Plan**: how you verified it / results (local, simulator, unit tests, etc.)
- **TODO / Follow-ups**: remaining work and next PR plan

### Branch Push Rule
- For the first push of a new branch, set upstream:
  - `git push -u origin <branch-name>`
