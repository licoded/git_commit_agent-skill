---
name: git-commit-agent
description: When user asks to commit code with commands like "/commit", "/commit --dry-run", "帮我提交", "git commit", or any request to create git commits, analyze staged changes, detect sensitive data, split commits by intent/layer/module, generate Vue.js Convention messages. Supports multi-module changes, breaking changes with '!', dry-run mode, Chinese/English context.
---

# Git Commit Agent

智能 Git 提交助手，分析代码变更并生成符合 Vue.js 规范的 commit message。

## Core Principles

1. **Never破坏用户的 staged** - 使用 `--only` 而非粗暴 `reset`
2. **优先按意图分组** - 先分 feat/fix/docs，再按 module 细分
3. **敏感信息默认阻断** - 强规则直接阻止，弱规则询问确认

## Quick Start

```bash
# 1. Stage changes first
git add <files>

# 2. Invoke skill
/commit 添加了用户登录功能

# 3. Or use dry-run to preview
/commit --dry-run
```

---

## Workflow

### Step 1: Repository & Status Check

**Check environment**:

```bash
# Verify git repository
git rev-parse --is-inside-work-tree

# Get comprehensive status (staged + unstaged)
git status --porcelain=v1

# Get staged files with detailed status
git diff --cached --name-status --diff-filter=ACDMRT
```

**Status analysis**:
- First column: staged status (A/M/D/R/T...)
- Second column: unstaged status (if exists)
- `--diff-filter`: focus on Added/Modified/Deleted/Renamed/Copied/Type-change

**If no staged changes**:

Check for common directories that should be ignored:

```bash
# Detect common ignore dirs
git status --short | grep -E "node_modules|__pycache__|\.pytest_cache|build|dist|target|\.m2|\.venv|venv|\.eggs|coverage|\.tox|\.idea|\.vscode|\.swp|\.DS_Store|Thumbs\.db"

# Count total files
total_files=$(git status --short | wc -l)
```

If `many_files_threshold` exceeded (default: 100), **use AskUserQuestion** to confirm:
- Continue with auto-add (`git add .`)
- Show file list first, then ask again
- Manually select files
- Cancel operation

**Auto-add (if enabled and user confirms)**:
```bash
git add .
```

---

### Step 2: Analyze Staged Changes

**Get detailed diff**:

```bash
# File-level changes
git diff --cached --name-status --diff-filter=ACDMRT

# Detailed diff for analysis (limit context for sensitive data detection)
git diff --cached -U0

# File count per module
git diff --cached --name-only | cut -d'/' -f1 | sort | uniq -c
```

**Analyze**:
- Group by file type / module
- Identify change patterns (new feature vs bug fix vs refactor)
- Count files per module

---

### Step 3: Sensitive Information Detection

**CRITICAL**: Only scan `git diff --cached -U0` (staged changes only), NOT working directory.

**Detection rules**:

- **Strong rules** (BLOCK by default):
  - AWS Keys: `AKIA[0-9A-Z]{16}`
  - PEM blocks: `-----BEGIN.*PRIVATE KEY-----`
  - Service tokens: `sk-ant-`, `xoxb-`, `ghp_`, `glpat-`, etc.

- **Weak rules** (ASK for confirmation):
  - Long base64 strings (≥20 chars)
  - Database URLs, authorization headers
  - API keys patterns

**Allowlist patterns** (auto-skip):
```
example, test, dummy, placeholder, xxxx, YOUR_, <your>
```

**If sensitive data detected**, **use AskUserQuestion**:
- **强规则命中**: Require cancellation or explicit override
- **弱规则命中**: Ask for confirmation, show context

**For detailed rules**: See [references/SENSITIVE_RULES.md](references/SENSITIVE_RULES.md)

**For interaction patterns**: See [references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md#2-敏感信息检测)

---

### Step 4: Plan Commits (Intent-First Splitting)

**Primary split criteria: Intent (type)**

Group changes by commit type first:
- **feat** - New features
- **fix** - Bug fixes
- **docs** - Documentation only
- **test** - Test changes
- **ci** - CI configuration
- **build** - Build system
- **refactor** - Code refactoring (not feat/fix)
- **chore** - Everything else

**Secondary split criteria: Module**

Within each intent group, consider splitting by module:
- Single module → single commit
- Multiple related modules (same feature) → can merge
- Multiple unrelated modules → suggest splitting

**Dependency awareness**:

**MERGE倾向** (avoid breaking commits):
- Same API/interface file changed in multiple commits
- Schema changes (protobuf, OpenAPI, GraphQL)
- Rename + usage updates
- Backend API + frontend API call (same feature)

**SPLIT倾向**:
- Different intents (feat + fix)
- Different features (even within same module)
- Docs + code (unless docs are integral)

**Change layer awareness**:

**检测变更层面**:

```bash
# 分析文件类型层面
for file in $(git diff --cached --name-only); do
  if [[ "$file" =~ \.(java|py|ts|js|go|rs)$ ]]; then
    echo "application: $file"
  elif [[ "$file" =~ (Dockerfile|docker-compose|\.gitignore|\.dockerignore)$ ]]; then
    echo "infrastructure: $file"
  elif [[ "$file" =~ (\.yml|\.yaml|\.toml|\.json|config/)$ ]]; then
    echo "config: $file"
  elif [[ "$file" =~ \.(md|txt|rst)$ ]]; then
    echo "docs: $file"
  fi
done
```

**层面定义**:
1. **应用层** - 源代码 (`.java`, `.py`, `.ts`, `.js`, etc.)
2. **基础设施层** - Docker, CI/CD (`Dockerfile`, `docker-compose.yml`, `.github/`)
3. **配置层** - 应用配置 (`*.yml`, `*.yaml`, `config/`)
4. **文档层** - 文档 (`*.md`, `docs/`)

**按层面拆分规则**:
- 应用层 + 基础设施层（无依赖）→ 拆分
- 应用层 + 配置层（有依赖）→ 合并
- 基础设施层 + 配置层（独立）→ 拆分

**IMPORTANT**: When detecting multiple layers without strong dependencies, **MUST use AskUserQuestion** to ask user:
- Show layer breakdown with file counts
- Provide clear options: split by layer (recommended), merge, or customize
- Support 3+ splits when detecting multiple layers/modules

**For detailed decision tree**: See [references/DECISION_TREE.md](references/DECISION_TREE.md)

**For interaction patterns**: See [references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md#3-拆分决策多层面)

---

### Step 5: Generate Commit Message

Follow Vue.js Commit Convention. See [references/CONVENTIONS.md](references/CONVENTIONS.md) for full spec.

**Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type Selection (Intent-First)

**Priority order**:

1. **User explicit context**:
   - "修复了登录 bug" → fix
   - "重构了 Service 层" → refactor
   - "添加了新功能" → feat

2. **File path analysis**:
   - `docs/`, `*.md` → docs
   - `test/`, `*_test.*` → test
   - `.github/`, `.gitlab/` → ci
   - `pom.xml`, `package.json` → build

3. **Diff semantic analysis**:
   - Only comments/README changed → docs
   - Tests + implementation → feat (test is secondary)
   - Config changes only → chore

4. **Default fallback**: `chore`

**NEVER use "New files added → feat"** - it's unreliable.

#### Scope Selection

Use configured `module_map` (see [references/CONFIGURATION.md](references/CONFIGURATION.md)):

**Strategy**:
- Single module → use module name
- Multiple modules (single commit) → omit scope or use most relevant
- Multiple modules (split) → each commit uses its module
- Unknown → fallback to top-level directory

#### Subject Rules

1. **Imperative mood**: "add" not "added" or "adding"
2. **Lowercase first letter**
3. **Max 50 characters**
4. **No period at end**
5. **Be specific and concise**

**Language strategy** (configurable):
- `follow_user` - Match user input language
- `en` - Force English
- `zh` - Force Chinese

#### Breaking Change Detection

**Breaking indicators**:
- Deleted/renamed public API
- Changed method signature
- Removed config field
- Behavior change affecting users
- Database schema change

**Format**:
```
feat(api)!: change user endpoint response format

BREAKING CHANGE: UserAPI now returns camelCase instead of snake_case.
Frontend consumers must update accordingly.
```

**Detection logic**:
Scan diff for:
- `@Deprecated` annotations with removal
- func/method signature changes
- deleted exports/interfaces
- config schema changes

If breaking change detected → **use AskUserQuestion** to confirm:
- Confirm with ! marker
- Normal commit without !
- Show detected changes first

**For interaction patterns**: See [references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md#6-breaking-change-确认)

#### Body (Optional)

**When to include**:
- Complex features (>3 files)
- Important fixes (security, data loss)
- Breaking changes
- Multi-step implementation

**Format**:
```
- What was changed and why
- Bullet points with "-"
- Max 72 chars per line
- Don't explain "how"
```

#### Footer (Optional)

**Issue references**:
```
Closes #123
Fixes #456
Refs #789
```

**Breaking changes**:
```
BREAKING CHANGE: API now uses camelCase instead of snake_case.
Migration guide: docs/migration.md
```

**Co-authored-by** (if using Claude Code):
```
Co-authored-by: Claude Sonnet 4.5 <noreply@anthropic.com>
```

#### Quality Validation

**Hard validation (must pass)**:

✅ **Format check**: Matches `<type>(<scope>): <subject>` or `<type>: <subject>`
✅ **Type valid**: Type in allowed list (feat/fix/docs/etc.)
✅ **Subject length**: ≤ 50 characters
✅ **No period**: Subject doesn't end with `.`

**Soft validation (warnings)**:

⚠️ **Scope relevance**: Scope matches changed files
⚠️ **Body needed**: Suggest body for complex changes (>3 files, user-facing)
⚠️ **Clarity**: Subject is clear and specific

---

### Step 6: Execute Commit

#### Single Commit

```bash
# Use single quotes to preserve special characters including '!'
git commit -m '<message>'

# Alternative: use double quotes with escaping
git commit -m "<message>"
```

#### Multiple Commits (Split)

**SAFE approach - Use `--only` to preserve other staged files**:

```bash
# Commit 1: Only specific files, keep others staged
# Use single quotes for breaking changes with '!'
git commit --only path1 path2 path3 -m 'message-1'

# Commit 2: Next set of files
git commit --only path4 path5 -m 'message-2'

# Verify all staged are committed
git diff --cached --quiet
```

**ALTERNATIVE - Using `restore --staged`** (more explicit):

```bash
# Commit 1: Exclude some files
git restore --staged -- path4 path5
git commit -m 'message-1'

# Commit 2: Commit the rest
git commit -m 'message-2'
```

**NEVER use粗暴的 `git reset`** - it destroys all staged state

#### Same File, Different Commits (Hunk-Level Split)

If same file needs different commits, **use AskUserQuestion**:
- Guide user through interactive `git add -p` process
- Offer to merge as single commit
- Show file diff first

**For interaction patterns**: See [references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md#7-hunk-level-拆分)

#### Dry-Run Mode

If `--dry-run` flag present, show preview then **use AskUserQuestion**:
- Show complete commit plan (messages, files, commands)
- Show sensitive data detection results
- Show split suggestions
- Show quality validation results

**Options**:
- Execute actual commits
- Adjust plan (modify message, adjust split)
- Cancel without changes

**For interaction patterns**: See [references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md#8-dry-run-预览确认)

#### Verification

After each commit:

```bash
# Show last commit
git log -1 --stat

# Check remaining staged
git diff --cached --name-status
```

---

### Step 7: Report Result

**Success (single commit)**:
```
✅ 提交成功!

Commit: abc1234
  feat(auth): add user login functionality

  - Implement JWT authentication
  - Add login form component
  - Integrate with backend API

变更文件: 3
  + backend/service/AuthService.java
  + backend/controller/AuthController.java
  + frontend/src/components/LoginForm.tsx
```

**Success (multiple commits)**:
```
✅ 成功提交 2 个 commit!

Commit 1: abc1234
  feat(auth): implement login feature
  Files: 2

Commit 2: def5678
  docs: update API documentation
  Files: 1
```

**Failure with remediation**:
```
❌ 提交失败: {error}

可能原因:
1. Git 未配置
   解决: git config --global user.name "Your Name"
          git config --global user.email "your@email.com"

2. Pre-commit hook 失败
   错误: {hook_error}
   解决: 修复问题或使用 git commit --no-verify

3. 权限问题
   解决: 检查仓库权限

当前状态:
  - Staged 文件: {n}
  - 可使用 git status 查看
```

---

## Configuration

Project-level config file: `.git-commit-agent.yml`

### Quick Reference

```yaml
# Commit 规范（固定使用 Vue.js）
convention: vuejs

# 自动添加策略
auto_add:
  enabled: true
  ask_before_add: true
  detect_ignore_dirs: true
  many_files_threshold: 100

# 语言策略
message_language: follow_user  # follow_user | en | zh

# 拆分策略
split_strategy:
  enabled: true
  max_modules_per_intent: 3
  max_files_per_commit: 10
  check_dependencies: true

# 模块映射
module_map:
  backend: ["backend/", "src/main/"]
  frontend: ["frontend/", "web/"]
  docs: ["docs/"]

# 敏感信息检测
sensitive_detection:
  enabled: true
  allowlist:
    - "example"
    - "test"
    - "dummy"

# 质量标准
quality:
  hard_validation:
    format: true
    type_valid: true
    subject_max_length: 50
    no_period: true
```

**For complete configuration**: See [references/CONFIGURATION.md](references/CONFIGURATION.md)

**Load order**: `.git-commit-agent.yml` → if not found, use defaults

---

## Quick Examples

### Example 1: Simple Feature (Single Commit)

**User**: `/commit 添加了用户登录功能`

**Staged files**:
```
A backend/service/AuthService.java
A backend/controller/AuthController.java
A frontend/src/components/LoginForm.tsx
```

**Analysis**:
- All new files (A)
- 2 modules: backend, frontend
- Same intent: feat (new feature)
- Related implementation → single commit

**Result**:
```
✅ 检测到 3 个 staged 文件
✅ 未检测到敏感信息
✅ 单个意图（feat）跨越相关模块 → 单个提交

feat(auth): add user login functionality

- Implement JWT authentication service
- Add login API endpoints
- Create login form component
- Integrate frontend with backend

执行: git commit -m "..."
✅ 提交成功: abc1234
```

### Example 2: Multi-Intent Split

**User**: `/commit 添加了功能并更新了文档`

**Staged files**:
```
A backend/service/UserService.java
M docs/api/users.md
```

**Analysis**:
- Different intents: feat (backend) + docs (docs)
- Should split

**Result**: Use AskUserQuestion to offer:
- Split by intent (recommended): 2 commits (feat → docs)
- Merge as single: 1 commit

If split selected:
```bash
# Commit 1: feat
git commit --only backend/service/UserService.java -m 'feat(user): add user management feature'

# Commit 2: docs
git commit --only docs/api/users.md -m 'docs: update user API documentation'
```

**For more examples**: See [references/EXAMPLES.md](references/EXAMPLES.md)

---

## Troubleshooting

### Issue: Sensitive data detected

**症状**: 提交时提示检测到敏感信息

**解决**:
```bash
# 撤回 staged
git restore --staged <file>

# 替换为环境变量
vim <file>
# 使用 ${VARIABLE_NAME} 而非硬编码

# 重新添加
git add <file>
```

### Issue: No staged changes

**症状**: 提示"没有已 staged 的变更"

**解决**:
```bash
# 添加要提交的文件
git add <files>

# 或添加所有变更
git add .
```

### Issue: Commit message validation failed

**症状**: Subject 过长或格式不正确

**解决**:
- 缩短 subject 到 ≤ 50 字符
- 确保格式为 `<type>(<scope>): <subject>`
- 移除 subject 结尾的句号

---

## Reference Documentation

For detailed information, see:

- **[references/CONVENTIONS.md](references/CONVENTIONS.md)** - Complete Vue.js Commit Convention specification
- **[references/SENSITIVE_RULES.md](references/SENSITIVE_RULES.md)** - Sensitive information detection rules
- **[references/CONFIGURATION.md](references/CONFIGURATION.md)** - Complete configuration guide
- **[references/DECISION_TREE.md](references/DECISION_TREE.md)** - Split decision tree and scenarios
- **[references/EXAMPLES.md](references/EXAMPLES.md)** - Detailed usage examples
- **[references/INTERACTION_PATTERNS.md](references/INTERACTION_PATTERNS.md)** - User interaction patterns and AskUserQuestion usage
