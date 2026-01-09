---
name: git-commit-agent
description: Intelligent Git commit assistant that analyzes staged changes, detects sensitive information, intelligently splits commits by intent, and generates standardized commit messages following Vue.js Commit Convention. Use when user asks to commit code with commands like "/commit", "/commit --dry-run", "帮我提交", "commit these changes", or any request to create git commits. The skill handles multi-module changes, sensitive data detection with strong/weak rules, breaking change detection, and dry-run mode. Supports both Chinese and English with configurable language strategy.
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

## Workflow

### Step 1: Repository & Status Check

**Check environment**:

```bash
# Disable bash history expansion to avoid issues with '!' in commit messages
set +H

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

First check for common directories that should be ignored:

```bash
# Check for common ignore directories (from config)
for dir in node_modules __pycache__ .pytest_cache build dist target .m2 .venv venv coverage .idea .vscode .DS_Store Thumbs.db; do
  [ -d "$dir" ] || [ -f "$dir" ] && echo "$dir"
done

# Check if .gitignore exists
test -f .gitignore && echo "exists" || echo "not found"

# Get list of unstaged files
git status --porcelain=v1 | grep "^??" | cut -c4-
```

**If common ignore directories detected**:

Interactive selection using AskUserQuestion:

```
⚠️  检测到常见应该被忽略的目录/文件:

检测到:
  [ ] 1. node_modules/ (npm 依赖包)
  [ ] 2. __pycache__/ (Python 字节码缓存)
  [ ] 3. build/ (构建输出目录)
  [ ] 4. .idea/ (JetBrains IDE 配置)
  ...

建议: 这些通常不应该提交到仓库

选项:
1. 全部添加到 .gitignore
2. 选择性添加（交互式选择）
3. 跳过（我自己处理）
```

**Option 1: Add all to .gitignore**
```bash
# Create or update .gitignore
cat >> .gitignore << 'EOF'

# Added by git-commit-agent
node_modules/
__pycache__/
.pytest_cache/
build/
dist/
target/
.m2/
.venv/
venv/
.eggs/
*.egg-info/
coverage/
.tox/
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db
EOF

echo "✅ 已添加常见忽略规则到 .gitignore"
```

**Option 2: Selective add (interactive)**

For each detected directory, ask user:
```
是否添加 node_modules/ 到 .gitignore？
1. 添加
2. 跳过

是否添加 __pycache__/ 到 .gitignore？
1. 添加
2. 跳过

...
```

Then append only selected items to .gitignore:
```bash
cat >> .gitignore << 'EOF'

# Added by git-commit-agent (user selected)
node_modules/
__pycache__/
coverage/
EOF
```

**After .gitignore update, check for unstaged files again**:
```bash
# Files still unstaged (after .gitignore applied)
git status --porcelain=v1 | grep "^??" | cut -c4-
```

**Now add all changes**:

If `auto_add.enabled: true` and user confirms:
```bash
# Add all unstaged changes (respecting .gitignore)
git add .

# Show what was staged
echo "✅ 已添加所有变更到暂存区"
git status --short --staged
```

**If user prefers manual control**:
```
ℹ️  检测到以下文件可以添加:

{list of unstaged files}

提示: 使用以下命令精确控制
  git add <file>     # 添加特定文件
  git add *.py       # 添加所有 .py 文件
  git add .          # 添加所有文件（已应用 .gitignore）

是否现在添加所有文件？
1. 是，添加所有
2. 否，让我手动选择
```

**If both staged and unstaged exist**:

First check total file count:
```bash
# Count staged files
staged_count=$(git diff --cached --name-only | wc -l)

# Count unstaged files
unstaged_count=$(git status --porcelain=v1 | grep "^??" | wc -l)

# Total changes
total_count=$((staged_count + unstaged_count))
```

**If total changes > 100**:
```
⚠️  检测到大量文件变更: {total_count} 个文件

这可能意味着:
  - 忘记配置 .gitignore
  - 依赖包目录（node_modules, vendor, etc.）未被忽略
  - 构建产物未被忽略

建议检查:

1. 查看是否有常见应该忽略的目录
2. 检查 .gitignore 是否配置正确

是否现在检查并更新 .gitignore？
1. 是，检查并建议
2. 否，继续提交
```

If user chooses to check:
```bash
# Run same detection as "no staged" case
# Show detected directories
# Offer to add to .gitignore
```

**Then ask user preference**:
```
✅ 检测到 {n} 个 staged 文件
⚠️  还有 {m} 个 unstaged 文件未添加

Unstaged 文件:
  {list (or summary if too many)}

选项:
1. 只提交已 staged 的文件
2. 添加所有 unstaged 文件然后一起提交
3. 取消，让我手动选择
```

**Detailed flow for option 2 (add unstaged)**:

```bash
# First check for ignore dirs (same as above)
# Update .gitignore if needed

# Then add all
git add .

# Show result
echo "✅ 已添加所有文件，现在总计 {n} 个 staged 文件"
git status --short
```

### Step 2: Analyze Staged Changes

**Get detailed diff**:

```bash
# Get full diff for analysis
git diff --cached

# For sensitive detection (no context, faster)
git diff --cached -U0
```

**Analyze each file**:
- **Status**: A (added), M (modified), D (deleted), R (renamed), T (type-change)
- **Module**: Determine using [module_map](#configuration) or fallback to top-level directory
- **Language**: .java, .py, .ts, .js, .md, .go, .rs, etc.
- **Intent (初判)**: feat/fix/docs/test/ci/build/refactor/chore

**Module mapping** (configurable via `.git-commit-agent.yml`):

```yaml
module_map:
  backend: ["backend/", "server/", "api/", "src/main/"]
  frontend: ["frontend/", "web/", "ui/", "client/"]
  docs: ["docs/", "*.md"]
  test: ["tests/", "test/", "__tests__/", "*_test.py"]
  ci: [".github/", ".gitlab/", ".gitignore"]
  scripts: ["scripts/", "tools/", "bin/"]
  config: ["config/", "*.yml", "*.yaml", "*.toml"]
```

**Fallback strategy**: If no match → use first directory component as scope

### Step 3: Sensitive Information Detection

**CRITICAL**: Only scan `git diff --cached -U0` (staged changes only), NOT working directory.

#### Strong Rules (Default: BLOCK)

These patterns indicate definite secrets. **Block by default, require explicit user confirmation to continue**:

**AWS Keys**:
```
AKIA[0-9A-Z]{16}
ASIA[0-9A-Z]{16}
[A-Z0-9]{20}  # AWS secret pattern
```

**PEM Private Key Blocks**:
```
-----BEGIN [A-Z]+ PRIVATE KEY-----
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN EC PRIVATE KEY-----
```

**Service Tokens (distinctive prefixes)**:
```
sk-ant-...      (Anthropic)
xoxb-|xoxp-     (Slack)
ghp_|gho_|ghu_  (GitHub)
glpat-          (GitLab)
AKIA...         (AWS)
```

**Detection output**:
```
🚨 强规则命中 - 检测到敏感信息！

文件: config/app.env:3
  AKIAIOSFODNN7EXAMPLE

⚠️  这是高置信度的敏感信息，默认阻止提交

处理建议:
1. 撤回 staged: git restore --staged <file>
2. 删除文件: git rm <file>
3. 替换为环境变量
4. 添加到 .gitignore
5. 如果是测试数据: 添加到 allowlist

选项:
1. 强制继续（不推荐）
2. 取消提交
3. 查看详细上下文
```

#### Weak Rules (Ask for Confirmation)

These patterns might be secrets, require user judgment:

**Long base64-like strings** (≥20 chars, high entropy):
```
[A-Za-z0-9+/]{20,}={0,2}
```

**URL patterns**:
```
DATABASE_URL=
REDIS_URL=
MONGODB_URI=
postgresql://
mysql://
```

**Authorization headers**:
```
Authorization: Bearer [a-zA-Z0-9]{20,}
```

**Detection output**:
```
⚠️  弱规则命中 - 可能的敏感信息

文件: src/api.ts:42
  const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";

这可能是:
- JWT token (敏感)
- 测试用 token (安全)
- 示例代码 (安全)

选项:
1. 继续提交
2. 取消提交
3. 查看上下文 (±3 lines)
```

#### Allowlist Patterns

Skip detection if match:
```
example
test
dummy
placeholder
xxxx
xxxxxxxx
YOUR_
<your>
```

#### Remediation Guidance

When sensitive data detected, provide actionable steps:
```
修复建议:

方法 1: 撤回 staged
  git restore --staged <file>
  git restore <file>  # 如果还要删除工作区改动

方法 2: 替换为环境变量
  - export API_KEY=$(echo $API_KEY)
  - 或使用 .env.example 模板

方法 3: 添加到 .gitignore
  echo "*.env" >> .gitignore

方法 4: 旋转密钥（如果已暴露）
  - 到服务控制台撤销旧密钥
  - 生成新密钥
  - 更新配置
```

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

**Change layer awareness** (NEW - 代码 vs 配置):

**检测变更层面**:

```bash
# 分析文件类型层面
for file in $(git diff --cached --name-only); do
  if [[ "$file" =~ \.(java|py|ts|js|go|rs|c|cpp|h|cs)$ ]]; then
    echo "application: $file"
  elif [[ "$file" =~ (Dockerfile|docker-compose|\.gitignore|\.dockerignore)$ ]]; then
    echo "infrastructure: $file"
  elif [[ "$file" =~ (\.yml|\.yaml|\.toml|\.json|config/)$ ]]; then
    echo "config: $file"
  elif [[ "$file" =~ \.(md|txt|rst)$ ]]; then
    echo "docs: $file"
  else
    echo "other: $file"
  fi
done
```

**层面定义**:

1. **应用层** (Application Layer)
   - 源代码: `.java`, `.py`, `.ts`, `.js`, `.go`, `.rs`, `.c`, `.cpp`, `.h`, `.cs`
   - 业务逻辑、API 实现、数据处理
   - 变更性质: 功能实现、bug 修复、代码重构

2. **基础设施层** (Infrastructure Layer)
   - Docker: `Dockerfile`, `docker-compose.yml`, `.dockerignore`
   - CI/CD: `.github/`, `.gitlab-ci.yml`
   - 构建: `pom.xml`, `package.json`, `build.gradle`
   - 变更性质: 部署配置、构建配置、环境配置

3. **配置层** (Configuration Layer)
   - 应用配置: `config/`, `*.yml`, `*.yaml`, `*.toml`, `*.json`
   - 环境变量: `.env.example`
   - 变更性质: 配置参数调整

4. **文档层** (Documentation Layer)
   - 文档: `*.md`, `*.txt`, `*.rst`, `docs/`
   - 变更性质: 文档更新

**按层面拆分规则**:

```
原则: 如果同时有多个层面的变更，且没有强依赖，则按层面拆分

**场景 1: 应用层 + 基础设施层** (通常应该拆分)

应用层变更:
  - CommandExecutionService.java (新增 logCommand 参数)

基础设施层变更:
  - Dockerfile, docker-compose.yml, .dockerignore

判断:
  ✅ 应用层可以独立运行（不需要新的 Docker 配置）
  ✅ 基础设施层可以独立存在（Docker 配置调整）

建议拆分:
  1. refactor(service): add logCommand parameter for flexible logging
  2. refactor(docker): optimize health check configuration

**场景 2: 应用层 + 配置层** (需要检查依赖)

应用层变更:
  - UserService.java (新增数据库连接配置)

配置层变更:
  - application.yml (添加数据库连接字符串)

判断:
  ⚠️  配置层变更依赖应用层代码
  ❌ 代码需要新配置才能运行

建议合并:
  1. feat(user): add database connection with configuration

**场景 3: 基础设施层 + 配置层** (通常可以拆分)

基础设施层变更:
  - Dockerfile (更新基础镜像)

配置层变更:
  - application.yml (调整日志级别)

判断:
  ✅ 两者独立

建议拆分:
  1. refactor(docker): upgrade base image to node:18
  2. chore(config): adjust log level to WARN
```

**检测依赖关系**:

```bash
# 检查应用层变更是否依赖配置
# 1. 扫描代码中的新增配置项
git diff --cached | grep -E '(@Value|@Property|Configuration|getConfig|getenv)'

# 2. 检查是否有对应配置文件变更
git diff --cached --name-only | grep -E '(\.yml|\.yaml|\.properties|\.env)'

# 如果代码引用新配置，但配置文件没有变更 → 提示用户
# 如果代码和配置都变更 → 合并
```

**决策树（更新版）**:
```
1. 按意图 (intent) 分组:
   ├─ 不同意图 → 必须拆分

2. 每个意图组内:
   ├─ 检查变更层面
   │  ├─ 单一层面 → 继续判断
   │  ├─ 多个层面 → 检查依赖
   │  │  ├─ 有依赖 → 合并
   │  │  └─ 无依赖 → 按层面拆分
   │
   ├─ 检查模块
   │  ├─ 单模块 → 单个 commit
   │  ├─ 多模块相关 → 合并
   │  └─ 多模块不相关 → 拆分
```

**Example: 用户场景**:

```
Files:
- backend/.../CommandExecutionService.java (应用层)
- backend/Dockerfile (基础设施层)
- frontend/Dockerfile (基础设施层)
- docker-compose.yml (基础设施层)
- backend/.dockerignore (基础设施层)
- frontend/.dockerignore (基础设施层)

Analysis:
- Intent: refactor (相同)
- Layers: 应用层 (1 个文件) + 基础设施层 (5 个文件)
- Dependency:
  ✅ 应用层新增 logCommand 功能独立
  ✅ Docker 配置优化独立
  ✅ 没有强依赖关系

Decision: 按层面拆分

Plan:
Commit 1: refactor(service): add logCommand parameter for flexible logging
  Files: CommandExecutionService.java (2 个文件)

  - Add logCommand parameter to executeLocal()
  - Support INFO and DEBUG logging levels
  - Apply DEBUG level for health checks

Commit 2: refactor(docker): optimize health check configuration
  Files: Dockerfile, docker-compose.yml, .dockerignore (5 个文件)

  - Move health check from Dockerfile to docker-compose.yml
  - Add Dockerfile to .dockerignore
  - Unify health check management
```

**Example scenarios**:

**Scenario 1: Same feature across modules (MERGE)**:
```
Files:
- backend/service/AuthService.java (new - feat)
- frontend/src/components/LoginForm.tsx (new - feat)
- docs/api.md (updated - docs)

Analysis:
- Auth feature spans backend + frontend
- Should keep together for atomic feature

Plan:
1. feat(auth): implement login feature (backend + frontend)
2. docs: update API documentation
```

**Scenario 2: Mixed intents (SPLIT)**:
```
Files:
- backend/service/UserService.java (fix bug)
- backend/service/OrderService.java (refactor)
- README.md (docs)

Analysis:
- Different intents in same module
- Should split by intent

Plan:
1. fix(user): resolve null pointer in UserService
2. refactor(order): extract validation logic
3. docs: update README with new features
```

**Scenario 3: Dependency detected (MERGE)**:
```
Files:
- backend/api/UserAPI.java (changed endpoint signature)
- frontend/src/api/user.ts (updated call to match)

Analysis:
- Breaking change in backend + frontend update
- Cannot split (middle state would be broken)

Plan:
1. feat(api)!: change user endpoint signature

   BREAKING CHANGE: UserAPI.getUser() now returns UserDTO
   instead of Map. Frontend updated accordingly.
```

**Scenario 4: Application + Infrastructure layers (SPLIT by layer)**:

```
Files:
- backend/.../CommandExecutionService.java (应用层)
- backend/Dockerfile (基础设施层)
- frontend/Dockerfile (基础设施层)
- docker-compose.yml (基础设施层)
- backend/.dockerignore (基础设施层)
- frontend/.dockerignore (基础设施层)

Analysis:
- Intent: refactor (相同)
- Layers: 应用层 + 基础设施层
- Dependency:
  ✅ 应用层功能独立（logCommand 参数不依赖 Docker 配置）
  ✅ 基础设施层变更独立（Docker 配置优化不依赖代码）
  ✅ 可以独立运行和测试

Decision: 按层面拆分

Plan:
Commit 1: refactor(service): add logCommand parameter for flexible logging
  Files: CommandExecutionService.java (2 个文件)
  Layer: 应用层

  - Add logCommand parameter to executeLocal()
  - Support INFO and DEBUG logging levels
  - Apply DEBUG level for health checks to reduce log noise

Commit 2: refactor(docker): optimize health check configuration
  Files: Dockerfile, docker-compose.yml, .dockerignore (5 个文件)
  Layer: 基础设施层

  - Move health check from Dockerfile to docker-compose.yml
  - Add Dockerfile to .dockerignore to avoid accidental copies
  - Unify health check management across services

💡 拆分原因:
- 应用层和基础设施层变更独立
- 代码功能可以独立测试
- Docker 配置调整不影响应用逻辑
- 更清晰的提交历史
```

**Ask user confirmation**:
```
建议拆分为 {n} 个提交:

Commit 1: {type}({scope}): {subject}
  文件: {files}
  意图: {intent}

Commit 2: {type}({scope}): {subject}
  文件: {files}
  意图: {intent}

💡 拆分原因: {reason}

选项:
1. 确认拆分
2. 合并为单个提交
3. 自定义拆分方案
4. 查看详细变更
```

### Step 5: Generate Commit Message

Follow Vue.js Commit Convention. See [CONVENTIONS.md](references/CONVENTIONS.md) for full spec.

**Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type Selection (Intent-First)

**Priority order**:

1. **User explicit context**:
   ```
   "修复了登录 bug" → fix
   "重构了 Service 层" → refactor
   "添加了新功能" → feat
   ```

2. **File path analysis**:
   ```
   docs/, *.md → docs
   test/, tests/, *_test.* → test
   .github/, .gitlab/ → ci
   pom.xml, package.json, build.gradle → build
   ```

3. **Diff semantic analysis**:
   ```
   Only comments/README changed → docs
   Tests + implementation → feat (test is secondary)
   Config changes only → chore
   ```

4. **Default fallback**: `chore`

**NEVER use "New files added → feat"** - it's unreliable.

#### Scope Selection

Use configured [module_map](#configuration):

```yaml
module_map:
  backend: ["backend/", "src/main/"]
  frontend: ["frontend/", "web/"]
  docs: ["docs/"]
```

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

```yaml
message_language: follow_user  # follow_user | en | zh
```

**Examples**:
```
follow_user:
  "添加了用户登录" → "add user login"
  "fix authentication bug" → "fix authentication bug"

en:
  "添加了用户登录" → "add user login"
  "修复 bug" → "fix bug"

zh:
  "add user login" → "添加用户登录"
  "fix bug" → "修复 bug"
```

**Learn from project history**:

```bash
git log --oneline -n 20
```

Analyze:
- Common types used
- Scope naming patterns
- Language (zh/en)
- Body usage frequency

#### Breaking Change Detection

**IMPORTANT**: The `!` character in breaking changes can trigger bash history expansion. Always ensure `set +H` is executed before running git commits with `!` to avoid parsing errors.

Add ! after type/scope if breaking change detected:

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
```
Scan diff for:
- @Deprecated annotations with removal
- func/method signature changes
- deleted exports/interfaces
- config schema changes

If detected → suggest ! + footer
Ask user confirmation: "这看起来是 breaking change，确认吗？"
```

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

**Example**:
```
feat(auth): add JWT token authentication

- Implement JWT generation and validation
- Add login/logout endpoints
- Store tokens in httpOnly cookies
- Support token refresh mechanism

Closes #123
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

**Validation flow**:
```
1. Check hard validations
   Fail → Show error, suggest fixes, retry generation

2. Check soft validations
   Warn → Show suggestions, allow user to accept or regenerate

3. Show final score
   ✅ All checks passed
   ⚠️  Passed with warnings
```

### Step 6: Execute Commit

**Pre-execution check**: Ensure bash history expansion is disabled (`set +H`) to handle breaking changes with `!` character.

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

If same file needs different commits:

```
⚠️  检测到文件 {file} 包含多个意图的变更

建议手动交互式拆分:

方法 1: 按块撤出
  git reset -p <file>
  # 选择要撤出的 hunk

方法 2: 按块添加
  git add -p <file>
  # 先提交部分，再添加剩余

是否现在进行交互式拆分？
1. 是，指导我操作
2. 否，合并为单个提交
```

#### Dry-Run Mode

If `--dry-run` flag present:

```
🔍 Dry-Run Mode - 不会实际执行提交

=== 计划的提交 ===

Commit 1: {type}({scope}): {subject}
  文件: {files}
  Message:
    {full_message}

  将执行: git commit --only {files} -m "{message}"

=== 敏感信息检测 ===
{detection_results}

=== 拆分建议 ===
{split_suggestion}

=== 质量检查 ===
{validation_results}

选项:
1. 确认执行
2. 调整方案
3. 取消
```

#### Verification

After each commit:

```bash
# Show last commit
git log -1 --stat

# Check remaining staged
git diff --cached --name-status
```

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
✅ 成功提交 3 个 commit!

Commit 1: abc1234
  feat(auth): implement login feature
  Files: 4

Commit 2: def5678
  docs: update API documentation
  Files: 2

Commit 3: ghi9012
  test(auth): add authentication tests
  Files: 3
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

4. 合并冲突
   解决: 先解决冲突，再提交

当前状态:
  - Staged 文件: {n}
  - 可使用 git status 查看
```

## Configuration

Project-level config file: `.git-commit-agent.yml`

```yaml
# Commit 规范（固定使用 Vue.js）
convention: vuejs

# 自动添加策略
auto_add:
  enabled: true  # 当没有 staged 时自动 git add .
  ask_before_add: true  # 添加前询问用户
  # 检测并建议添加到 .gitignore 的目录
  detect_ignore_dirs: true
  # 当总变更数超过此阈值时，提示检查 .gitignore
  many_files_threshold: 100
  # 常见应该忽略的目录（可自定义）
  common_ignore_dirs:
    - node_modules      # npm 依赖
    - __pycache__       # Python 缓存
    - .pytest_cache     # pytest 缓存
    - build             # 构建输出
    - dist              # 分发目录
    - target            # Maven 构建
    - .m2               # Maven 本地仓库
    - .venv             # Python 虚拟环境
    - venv              # Python 虚拟环境
    - .eggs             # Python eggs
    - *.egg-info        # Python egg 信息
    - coverage          # 覆盖率报告
    - .tox              # tox 测试环境
    - .idea             # JetBrains IDE
    - .vscode           # VS Code
    - *.swp             # Vim 临时文件
    - *.swo             # Vim 临时文件
    - .DS_Store         # macOS
    - Thumbs.db         # Windows

# 语言策略
message_language: follow_user  # follow_user | en | zh

# 拆分策略
split_strategy:
  enabled: true
  # 同一意图内，按模块拆分的阈值
  max_modules_per_intent: 3
  # 文件数阈值（太大了建议拆）
  max_files_per_commit: 10
  # 是否检查依赖关系
  check_dependencies: true

# 模块映射（覆盖默认规则）
module_map:
  backend: ["backend/", "server/", "api/", "src/main/"]
  frontend: ["frontend/", "web/", "ui/", "client/"]
  docs: ["docs/", "*.md"]
  test: ["tests/", "test/", "__tests__/", "*_test.go"]
  ci: [".github/", ".gitlab/"]
  scripts: ["scripts/", "tools/", "bin/"]
  config: ["config/", "*.yml", "*.yaml"]

# 敏感信息检测
sensitive_detection:
  enabled: true
  # 强规则：默认阻断
  strong_patterns:
    - AWS Keys: "AKIA[0-9A-Z]{16}"
    - PEM blocks: "-----BEGIN.*PRIVATE KEY-----"
    - GitHub tokens: "ghp_[a-zA-Z0-9]{36}"
    - GitLab tokens: "glpat-[a-zA-Z0-9]{20}"
    - Slack tokens: "xox[bap]-[a-zA-Z0-9-]{10,}"
  # 弱规则：询问确认
  weak_patterns:
    - Long base64: "[A-Za-z0-9+/]{20,}={0,2}"
    - URLs: "(DATABASE_URL|REDIS_URL|MONGODB_URI|postgresql://|mysql://)"
    - Authorization: "Authorization: Bearer [a-zA-Z0-9]{20,}"
  # Allowlist（跳过检测）
  allowlist:
    - "example"
    - "test"
    - "dummy"
    - "placeholder"
    - "xxxx"
    - "YOUR_"
    - "<your>"

# 质量标准
quality:
  # 强制检查
  hard_validation:
    - format: true
    - type_valid: true
    - subject_max_length: 50
    - no_period: true
  # 软建议
  soft_validation:
    - suggest_body_for_complex: true  # >3 files
    - suggest_body_for_user_facing: true
    - scope_relevance: true

# Preflight 检查（可选）
preflight_checks:
  enabled: false
  commands:
    - "npm run lint"
    - "pytest -x"  # 第一个失败就停止
  # 超时（秒）
  timeout: 30
```

**Load order**: `.git-commit-agent.yml` → if not found, use defaults

## Examples

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

**User**: `/commit 修复了 bug 并更新了文档`

**Staged files**:
```
M backend/service/UserService.java
M docs/api.md
M README.md
```

**Analysis**:
- 3 files, 3 modules
- Two intents: fix (UserService), docs (api.md, README.md)
- Should split by intent

**Ask user**:
```
建议拆分为 2 个提交:

Commit 1: fix(backend): resolve null pointer in UserService
  文件: backend/service/UserService.java
  意图: fix

Commit 2: docs: update API documentation
  文件: docs/api.md, README.md
  意图: docs

拆分原因: 不同意图（修复 bug + 文档）

选项:
1. 确认拆分
2. 合并为单个
3. 自定义
```

### Example 3: Breaking Change

**User**: `/commit 修改了用户 API 接口`

**Diff shows**:
```
- public User getUser(String id)
+ public UserDTO getUser(String id)
```

**Analysis**:
- Public API signature changed
- Breaking change detected

**Suggested message**:
```
feat(api)!: change getUser return type to UserDTO

BREAKING CHANGE: UserAPI.getUser() now returns UserDTO
instead of User. All callers must update to use
UserDTO methods.

⚠️  检测到 breaking change，确认标记吗？
1. 确认
2. 不是 breaking change
```

### Example 4: Sensitive Data Detected

**User**: `/commit 添加配置文件`

**Staged**:
```
A config/app.env
```

**Diff (`git diff --cached -U0`)**:
```
+API_KEY=sk-ant-api03-...
+DATABASE_URL=postgresql://...
```

**Detection**:
```
🚨 强规则命中 - 检测到敏感信息！

文件: config/app.env:1
  API_KEY=sk-ant-api03-...

⚠️  这是高置信度的敏感信息，默认阻止提交

处理建议:
1. 撤回 staged: git restore --staged config/app.env
2. 替换为环境变量: export API_KEY=$API_KEY
3. 添加到 .gitignore: echo "*.env" >> .gitignore

选项:
1. 强制继续（不推荐）
2. 取消提交并查看建议
```

### Example 5: Dry-Run Mode

**User**: `/commit --dry-run 添加了支付功能`

**Output**:
```
🔍 Dry-Run Mode - 不会实际执行提交

=== 变更分析 ===
Staged 文件: 5
  + backend/service/PaymentService.java
  + backend/controller/PaymentController.java
  + frontend/src/components/PaymentForm.tsx
  + docs/payment-api.md
  + config/payment.yml

=== 敏感信息检测 ===
✅ 未检测到敏感信息

=== 拆分建议 ===
建议拆分为 2 个提交:

Commit 1: feat(payment): implement payment functionality
  文件: 3 (PaymentService.java, PaymentController.java, PaymentForm.tsx)
  意图: feat

Commit 2: docs(payment): add payment API documentation
  文件: 2 (payment-api.md, payment.yml)
  意图: docs

=== 生成的 Commit Messages ===

Commit 1:
feat(payment): implement payment functionality

- Add payment service with Stripe integration
- Create payment API endpoints
- Build payment form component
- Support credit card and Alipay

Commit 2:
docs(payment): add payment API documentation

- Document payment endpoints
- Add integration examples
- Update configuration reference

=== 质量检查 ===
✅ Format check passed
✅ Type valid
✅ Subject length OK
✅ No period
⚠️  建议: 考虑添加 breaking change 说明（如果涉及 API 变更）

=== 将执行的命令 ===
git commit --only \
  backend/service/PaymentService.java \
  backend/controller/PaymentController.java \
  frontend/src/components/PaymentForm.tsx \
  -m "feat(payment): implement payment functionality ..."

git commit --only \
  docs/payment-api.md \
  config/payment.yml \
  -m "docs(payment): add payment API documentation ..."

选项:
1. 确认执行
2. 调整方案
3. 取消
```

## Error Handling

### Not a git repository
```
❌ 当前目录不是 Git 仓库
请先初始化仓库: git init
```

### Git not configured
```
❌ Git 未配置用户信息
请运行:
  git config --global user.name "Your Name"
  git config --global user.email "your@email.com"
```

### No staged changes
```
❌ 没有已 staged 的变更
请先添加文件:
  git add <files>
  或 git add . (添加所有)

提示：使用 git status 查看当前状态
```

### Merge conflict
```
❌ 检测到合并冲突
请先解决冲突后再提交

冲突文件:
  - backend/service/UserService.java

使用以下命令解决:
  git status  # 查看冲突
  # 编辑文件，解决冲突
  git add <resolved-files>
  git commit
```

### Hook failure
```
❌ Pre-commit hook 失败

Hook 错误:
  {hook_output}

选项:
1. 修复问题后重试
2. 使用 --no-verify 跳过 hook（不推荐）

当前状态:
  - Staged 文件: {n}
  - 可使用 git diff --cached 查看
```

## Important Notes

1. **Only commit staged files** - Never auto-add, never modify working directory
2. **Preserve staged state** - Use `--only` or `restore --staged`, never `git reset`
3. **Intent-first splitting** - Group by feat/fix/docs, then by module
4. **Security by default** - Strong patterns block, weak patterns ask
5. **Dry-run available** - Use `--dry-run` to preview without executing
6. **Learn project style** - Analyze git log for language/scope patterns
7. **Dependency awareness** - Don't break atomic changes across commits

## Resources

### references/CONVENTIONS.md

Complete Vue.js Commit Convention specification with:
- All commit types (feat/fix/docs/etc.)
- Scope patterns and examples
- Validation rules
- Breaking change guidelines
- Multi-language examples

Load when generating messages or validating format.

### Fallback behavior

If `references/CONVENTIONS.md` missing:
- Use built-in Vue.js convention rules
- Still functional but without detailed examples
- Warning logged (not blocking)

## Advanced Usage

### Custom commit types

Extend allowed types in config:
```yaml
custom_types:
  - name: "hotfix"
    description: "紧急生产修复"
  - name: "release"
    description: "发布版本"
```

### Override language strategy

Temporarily override:
```
/commit --lang=en 添加了用户功能
→ Subject: "add user feature" (force English)

/commit --lang=zh add user feature
→ Subject: "添加用户功能" (force Chinese)
```

### Bypass sensitive detection (not recommended)

```
/commit --no-sensitive-check
⚠️  已禁用敏感信息检测（不推荐）
```

### Verbose mode

```
/commit --verbose
显示详细的决策过程和中间结果
```
