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

## 3) PR Convention & Workflow

### Before Creating a PR
1. Review the entire commit history (don’t only look at the latest commit).
2. Review all changes:
   - `git diff [base-branch]...HEAD`

### PR Writing Rules
- Write the PR title and description in **Korean**.
- If `.github/pull_request_template.md` exists, use it as the default PR description format.
- If the template file does not exist, use the lightweight format below.
- Recommended: keep commit `type` in English and write the PR title as `<type>: <한글 요약>`  
  Example: `refactor: 메인 홈 독서 흐름 MVVM 전환`

### Lightweight PR Description (Only when template is missing)
- `## 작업 내용`
  - 핵심 변경 사항
  - 변경 이유
- `## 테스트`
  - 수행한 테스트와 결과
- `## 후속 작업` (optional)
- `## 리뷰 포인트` (optional)
- `## 스크린샷` (optional)

### Branch Push Rule
- For the first push of a new branch, set upstream:
  - `git push -u origin <branch-name>`

---

## 4) PR Review Convention

### Rules
- Write review comments in **Korean**.
- Leave all code findings (bugs, regressions, risks) as **inline comments** on PR diff lines.
- Do **not** leave only top-level PR comments for code findings.
- Use one finding per comment with a priority tag: `[P0]`, `[P1]`, `[P2]`, `[P3]`.
- If inline is impossible, leave a top-level comment and explicitly state why inline is not possible.

### Required Inline Command (`gh`)
```bash
gh api -X POST repos/<org>/<repo>/pulls/<pr-number>/comments \
  -f body='[P1] Finding...' \
  -f commit_id=<head-commit-sha> \
  -f path='path/to/file.swift' \
  -F line=<line-number> \
  -f side=RIGHT
```
