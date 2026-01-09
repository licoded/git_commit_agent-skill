---
name: git-commit-agent
description: Intelligent Git commit assistant that analyzes staged changes, detects sensitive information, intelligently splits commits, and generates standardized commit messages following Vue.js or Conventional Commits conventions. Use when user asks to commit code with commands like "/commit", "帮我提交", "commit these changes", or any request to create git commits. The skill handles multi-module changes, sensitive data detection, and quality scoring for commit messages.
---

# Git Commit Agent

智能 Git 提交助手，分析代码变更并生成符合规范的 commit message。

## Quick Start

When user invokes this skill (via `/commit`, "帮我提交代码", or similar):

1. Check for staged changes
2. Detect sensitive information
3. Analyze commit structure (split if needed)
4. Generate commit message
5. Execute commit

## Workflow

### Step 1: Check Git Repository

Verify we're in a git repo with staged changes:

```bash
# Check if git repo
git rev-parse --is-inside-work-tree

# Check for staged changes
git diff --cached --quiet
```

If no staged changes:
```
❌ 没有已 staged 的变更
请先使用: git add <files>
```

### Step 2: Analyze Changes

Get staged file info:

```bash
# File list with status
git diff --cached --name-status

# Detailed changes
git diff --cached
```

For each file, identify:
- **Status**: added (A), modified (M), deleted (D), renamed (R)
- **Module**: backend, frontend, docs, test, config, etc.
- **Language**: .java, .py, .ts, .js, .md, etc.

### Step 3: Detect Sensitive Information

Search for sensitive patterns in staged files:

**API Keys**: `sk-xxx`, `AIzaxxx`, `ghp_xxx`, `gho_xxx`, `ghu_xxx`, `glpat-xxx`
**Tokens**: `token:`, `"token":`, bearer, JWT (`xxx.xxx.xxx`)
**Passwords**: `password:`, `passwd:`, `pwd:`
**Secrets**: `secret:`, `private_key`
**Files**: `.env`, `.pem`, `.key`, `.crt`

Use Grep to search patterns, Read to verify.

If found, warn user and ask confirmation via AskUserQuestion:
```
⚠️  检测到敏感信息
是否继续？
1. 继续
2. 取消
```

### Step 4: Plan Commits

**Analyze module distribution**:

Count files per module. Determine if split needed:

**Split when**:
- 3+ different modules
- Mixed feat + fix changes
- Mixed refactor + feat
- Docs + code changes

**Single commit when**:
- Single module with related changes
- Simple bug fix
- Small feature (< 5 files)

If splitting, AskUserQuestion with proposal:
```
建议拆分为 {n} 个提交:
1. {type}({scope}): {subject}
2. {type}({scope}): {subject}

选项:
1. 确认拆分
2. 合并为单个
3. 自定义
```

### Step 5: Generate Commit Message

Use Vue.js Commit Convention (format in [CONVENTIONS.md](references/CONVENTIONS.md)):

```
<type>(<scope>): <subject>

<body>
```

**Type Selection**:

| Condition | Type |
|-----------|------|
| User says "修复/fix/bug" | `fix` |
| User says "重构/refactor" | `refactor` |
| Only .md/.txt files | `docs` |
| Test files only | `test` |
| New files added | `feat` |
| Default | `chore` |

**Scope Selection**:
- Single module → use module name
- Multi modules (single commit) → omit or use most relevant
- Multi modules (split) → each commit uses its module

**Subject Rules**:
- Imperative mood: "add" not "added"
- Lowercase first letter
- Max 50 characters
- No period at end

**Extract from user context**:
```
"添加了用户登录功能" → "add user login feature"
"修复 API 认证 bug" → "fix API authentication bug"
```

**Body** (optional):
- Use for complex features, important fixes, breaking changes
- List format with `-` prefix
- Explain "what" and "why", not "how"

**Footer** (optional):
```
Closes #123
Fixes #456

BREAKING CHANGE: API now uses camelCase
```

**Quality Score** (0-100):
- Format: 20%
- Clarity: 25%
- Completeness: 20%
- Scope: 20%
- History: 15%

If score < 70, improve before committing.

### Step 6: Execute Commit

**Single commit**:
```bash
git commit -m "<message>"
```

**Multiple commits** (split):

```bash
# For each commit
git reset
git add <files-for-commit-1>
git commit -m "<message-1>"

git add <files-for-commit-2>
git commit -m "<message-2>"
```

**Verify**:
```bash
git log -1 --stat
git diff --cached --quiet  # Should be empty
```

### Step 7: Report Result

**Success**:
```
✅ 成功提交 {n} 个 commit!

Commit 1: {hash}
  {type}({scope}): {subject}
```

**Failure**:
```
❌ 提交失败: {error}

可能原因:
1. Git 未配置: git config --global user.name "Your Name"
2. Pre-commit hook 失败
3. 权限问题
```

## Examples

### Example 1: Simple Feature

**User**: `/commit 添加了用户登录功能`

**Files**: `AuthService.java`, `AuthController.java`, `LoginForm.tsx`

**Analysis**:
- 3 files, 2 modules (backend, frontend)
- Related feature → single commit

**Result**:
```
feat(auth): add user login functionality

- Implement JWT authentication
- Add login form component
- Integrate with backend API
```

### Example 2: Multi-Module Split

**User**: `/commit 修复后端 API 并更新文档`

**Files**: `UserService.java`, `api.md`, `README.md`

**Analysis**:
- 3 files, 3 modules → suggest split

**Ask user**:
```
建议拆分为 2 个提交:
1. fix(backend): correct user service API
2. docs: update API documentation

选项:
1. 确认拆分
2. 合并为单个
```

### Example 3: Sensitive Data

**User**: `/commit 添加配置文件`

**Files**: `config/app.env` with `API_KEY=sk-xxx`

**Detect**: Warn user, ask confirmation.

## Configuration

Project-level config file: `.git-commit-agent.yml`

```yaml
convention: vuejs  # vuejs | conventional

split_strategy:
  enabled: true
  max_modules_per_commit: 3

sensitive_detection:
  enabled: true

quality:
  min_score: 70
```

Load if exists to customize behavior.

## Resources

### references/CONVENTIONS.md

Complete commit convention specifications (Vue.js, Conventional Commits), type definitions, scope patterns, and validation rules.

Load when generating commit messages or validating format.

## Error Handling

**Not a git repo**: Direct user to run in git repository

**No staged changes**: Remind to run `git add` first

**Git not configured**:
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

**Hook failure**: Show hook error, suggest fixing or using `--no-verify`

## Important Notes

- **Only commit staged files** - Never auto-add files
- **Ask before splitting** - Always confirm with user
- **Security first** - Err on side of caution with sensitive data
- **Learn from history** - Check `git log` for project style patterns
