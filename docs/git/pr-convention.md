# PR Convention

## 1) Scope

- This document defines PR preparation, writing, and review rules.
- Branching and commit rules are defined in:
  - `./docs/git/git-convention.md`

---

## 2) PR Preparation Workflow

### Before Creating a PR
1. Review the entire commit history (do not check only the latest commit).
   - `git log --oneline [base-branch]..HEAD`
2. Review all changes.
   - `git diff [base-branch]...HEAD`
3. Verify the working tree does not include unintended files.
   - `git status --short`

### Branch Push Rule
- For the first push of a new branch, set upstream:
  - `git push -u origin <branch-name>`

---

## 3) PR Writing Rules

- Write the PR title and description in **Korean**.
- If `.github/pull_request_template.md` exists, use it as the default PR description format.
- If the template file does not exist, use the lightweight format below.
- Recommended: keep commit `type` in English and write the PR title as `<type>: <한글 요약>`.
  - Example: `refactor: 메인 홈 독서 흐름 MVVM 전환`

### Lightweight PR Description (Only when template is missing)
- `## 작업 내용`
  - 핵심 변경 사항
  - 변경 이유
- `## 테스트`
  - 수행한 테스트와 결과
- `## 후속 작업` (optional)
- `## 리뷰 포인트` (optional)
- `## 스크린샷` (optional)

---

## 4) PR Review Convention

### Mandatory Review Checklist
1. Confirm the review target is the latest `HEAD`.
2. Re-check latest commit and diff right before posting comments.
3. Review entire commit history and all changed files.
4. Verify bug/regression/risk points and test evidence.
5. Leave each finding as an inline comment with priority.

### Rules
- Write review comments in **Korean**.
- Leave all code findings (bugs, regressions, risks) as **inline comments** on PR diff lines.
- Do **not** leave only top-level PR comments for code findings.
- Use one finding per comment with a priority tag: `[P0]`, `[P1]`, `[P2]`, `[P3]`.
- If inline is impossible, leave a top-level comment and explicitly state why inline is not possible.
- When leaving a top-level review comment (summary or fallback), start the first line with `[Agent Review]`.
- If another agent is actively updating the same PR/branch, refresh to latest `HEAD` before final review submission to avoid stale comments.

### Exception: Reviewing Your Own PR
- GitHub does not allow `request-changes` on your own PR.
- In this case, keep all findings as inline comments (same as normal review).
- Use a top-level `--comment` review only as a summary; do not replace inline findings with top-level-only comments.
- If you must use top-level comments for a finding, explicitly explain why inline was not possible.

### Required Inline Command (`gh`)
```bash
gh api -X POST repos/<org>/<repo>/pulls/<pr-number>/comments \
  -f body='[P1] Finding...' \
  -f commit_id=<head-commit-sha> \
  -f path='path/to/file.swift' \
  -F line=<line-number> \
  -f side=RIGHT
```
