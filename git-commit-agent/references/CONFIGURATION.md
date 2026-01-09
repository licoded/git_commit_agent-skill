# Git Commit Agent - 配置详解

本文档详细说明 Git Commit Agent 的所有配置选项。

## 配置文件

### 文件位置

- **项目级配置**: `.git-commit-agent.yml`（项目根目录）
- **全局配置**: `~/.git-commit-agent.yml`（用户主目录）

### 优先级

项目级配置 > 全局配置 > 默认值

### 加载顺序

1. 查找项目根目录的 `.git-commit-agent.yml`
2. 如果未找到，使用全局配置 `~/.git-commit-agent.yml`
3. 如果都未找到，使用内置默认值

---

## 完整配置选项

### 基础配置

#### `convention` - Commit 规范

**类型**: `string`
**默认值**: `vuejs`
**可选值**: `vuejs` | `conventional`

**说明**: Commit message 遵循的规范。

```yaml
# 固定使用 Vue.js Commit Convention
convention: vuejs
```

> **注意**: 当前版本固定使用 `vuejs`，未来可能支持其他规范。

---

### 自动添加策略 (`auto_add`)

控制当没有 staged 变更时的行为。

#### `enabled`

**类型**: `boolean`
**默认值**: `true`

**说明**: 当没有 staged 变更时，是否自动执行 `git add .`

```yaml
auto_add:
  enabled: true  # 自动添加所有变更
```

#### `ask_before_add`

**类型**: `boolean`
**默认值**: `true`

**说明**: 自动添加前是否询问用户确认。

```yaml
auto_add:
  ask_before_add: true  # 添加前显示变更列表，等待确认
```

#### `detect_ignore_dirs`

**类型**: `boolean`
**默认值**: `true`

**说明**: 是否检测常见应该忽略的目录（如 `node_modules`）

```yaml
auto_add:
  detect_ignore_dirs: true  # 检测并警告
```

#### `many_files_threshold`

**类型**: `integer`
**默认值**: `100`

**说明**: 当变更文件数超过此阈值时，提示用户检查 `.gitignore`

```yaml
auto_add:
  many_files_threshold: 100  # 超过 100 个文件时提示
```

#### `common_ignore_dirs`

**类型**: `list[string]`
**默认值**: 预定义的常见忽略目录

**说明**: 常见应该被 `.gitignore` 忽略的目录列表

```yaml
auto_add:
  common_ignore_dirs:
    # Node.js
    - node_modules

    # Python
    - __pycache__
    - .pytest_cache
    - .venv
    - venv
    - *.egg-info
    - .eggs
    - .tox
    - coverage

    # Java
    - target
    - .m2

    # 构建
    - build
    - dist

    # IDE
    - .idea
    - .vscode

    # 编辑器
    - *.swp
    - *.swo

    # 操作系统
    - .DS_Store
    - Thumbs.db
```

**自定义**:

```yaml
auto_add:
  common_ignore_dirs:
    - node_modules
    - .my_custom_cache  # 添加自定义目录
```

---

### 语言策略 (`message_language`)

控制 commit message 的语言。

#### 配置值

**类型**: `string`
**默认值**: `follow_user`
**可选值**:
- `follow_user` - 跟随用户输入的语言
- `en` - 强制使用英文
- `zh` - 强制使用中文

```yaml
message_language: follow_user
```

**行为说明**:

| 配置 | 用户输入 | Commit Message 语言 |
|------|---------|-------------------|
| `follow_user` | "添加了登录功能" | 中文 |
| `follow_user` | "add login feature" | 英文 |
| `en` | "添加了登录功能" | 英文（翻译） |
| `zh` | "add login feature" | 中文（翻译） |

---

### 拆分策略 (`split_strategy`)

控制 commit 拆分的粒度和规则。

#### `enabled`

**类型**: `boolean`
**默认值**: `true`

**说明**: 是否启用智能拆分。

```yaml
split_strategy:
  enabled: true
```

#### `max_modules_per_intent`

**类型**: `integer`
**默认值**: `3`

**说明**: 同一意图内，最多允许的模块数。超过则建议拆分。

```yaml
split_strategy:
  max_modules_per_intent: 3  # 超过 3 个模块时建议拆分
```

**示例**:
- ✅ `backend + frontend` (2 模块) → 单个 commit
- ⚠️ `backend + frontend + docs + test` (4 模块) → 建议拆分

#### `max_files_per_commit`

**类型**: `integer`
**默认值**: `10`

**说明**: 单个 commit 的最大文件数。超过时建议拆分。

```yaml
split_strategy:
  max_files_per_commit: 10
```

#### `check_dependencies`

**类型**: `boolean`
**默认值**: `true`

**说明**: 拆分前检查依赖关系，避免拆出不可用的 commit。

```yaml
split_strategy:
  check_dependencies: true  # 检查模块间依赖
```

**依赖检查规则**:
- Frontend 变更依赖 Backend API → 合并提交
- 共享库变更 + 使用方变更 → 合并提交
- 独立模块（无依赖） → 可以拆分

---

### 模块映射 (`module_map`)

定义项目中的模块，用于自动识别 scope。

#### 默认映射

**类型**: `object`
**默认值**:

```yaml
module_map:
  backend: ["backend/", "server/", "api/", "src/main/"]
  frontend: ["frontend/", "web/", "ui/", "client/"]
  docs: ["docs/", "*.md"]
  test: ["tests/", "test/", "__tests__/", "*_test.go", "*_test.py"]
  ci: [".github/", ".gitlab/"]
  scripts: ["scripts/", "tools/", "bin/"]
  config: ["config/", "*.yml", "*.yaml"]
```

#### 自定义映射

**覆盖默认**:

```yaml
module_map:
  # 覆盖 backend 的路径
  backend: ["src/main/java/", "server/"]

  # 添加自定义模块
  mobile: ["mobile/", "ios/", "android/"]
  infra: ["terraform/", "k8s/"]
```

**通配符支持**:

```yaml
module_map:
  # 使用 * 匹配任意字符
  docs: ["docs/", "*.md", "*.rst"]

  # 使用 ** 匹配多级目录
  test: ["**/test/**", "**/*_test.*"]
```

#### 匹配优先级

1. 完全匹配（如 `backend/`）
2. 前缀匹配（如 `backend/` 匹配 `backend/service/`）
3. 通配符匹配（如 `*.md`）

**示例**:

| 文件路径 | 匹配的模块 |
|---------|-----------|
| `backend/service/UserService.java` | `backend` |
| `frontend/src/components/Button.tsx` | `frontend` |
| `README.md` | `docs` |
| `docs/api.md` | `docs` |
| `.github/workflows/ci.yml` | `ci` |

---

### 敏感信息检测 (`sensitive_detection`)

控制敏感信息检测的规则和行为。

#### `enabled`

**类型**: `boolean`
**默认值**: `true`

**说明**: 是否启用敏感信息检测。

```yaml
sensitive_detection:
  enabled: true
```

#### `strong_patterns`

**类型**: `object`
**默认值**: 预定义的强规则模式

**说明**: 强规则模式（默认阻止）

```yaml
sensitive_detection:
  strong_patterns:
    AWS Keys: "AKIA[0-9A-Z]{16}"
    PEM blocks: "-----BEGIN.*PRIVATE KEY-----"
    GitHub tokens: "ghp_[a-zA-Z0-9]{36}"
    GitLab tokens: "glpat-[a-zA-Z0-9_-]{20,}"
    Slack tokens: "xox[bap]-[a-zA-Z0-9-]{10,}"
    Anthropic keys: "sk-ant-[a-zA-Z0-9_-]{20,}"
```

**自定义模式**:

```yaml
sensitive_detection:
  strong_patterns:
    # 添加公司内部密钥格式
    Company Key: "COMPANY_[A-Z0-9]{32}"
```

#### `weak_patterns`

**类型**: `object`
**默认值**: 预定义的弱规则模式

**说明**: 弱规则模式（询问确认）

```yaml
sensitive_detection:
  weak_patterns:
    Long base64: "[A-Za-z0-9+/]{20,}={0,2}"
    URLs: "(DATABASE_URL|REDIS_URL|MONGODB_URI|postgresql://|mysql://)"
    Authorization: "Authorization: Bearer [a-zA-Z0-9._-]{20,}"
    API keys: "api-key:\\s*[a-zA-Z0-9]{20,}"
```

**自定义模式**:

```yaml
sensitive_detection:
  weak_patterns:
    # 添加自定义模式
    Internal URL: "internal-\\.company\\.com"
```

#### `allowlist`

**类型**: `list[string]`
**默认值**: 预定义的白名单

**说明**: 跳过检测的关键词（误报防护）

```yaml
sensitive_detection:
  allowlist:
    - "example"
    - "test"
    - "dummy"
    - "placeholder"
    - "xxxx"
    - "YOUR_"
    - "<your>"
```

**自定义白名单**:

```yaml
sensitive_detection:
  allowlist:
    - "example"
    - "test"
    - "mycompany_test_"  # 添加自定义
    - "dev_"             # 开发环境标识
```

---

### 质量标准 (`quality`)

控制 commit message 的质量检查。

#### `hard_validation`

**类型**: `object`
**默认值**:

```yaml
quality:
  hard_validation:
    format: true
    type_valid: true
    subject_max_length: 50
    no_period: true
```

**说明**: 强制检查（必须通过）

| 选项 | 说明 | 失败行为 |
|-----|------|---------|
| `format` | 格式是否符合 `<type>(<scope>): <subject>` | 阻止，要求重写 |
| `type_valid` | type 是否在允许列表中 | 阻止，要求重写 |
| `subject_max_length` | subject 最大长度 | 阻止，要求缩短 |
| `no_period` | subject 不以 `.` 结尾 | 阻止，要求删除 |

#### `soft_validation`

**类型**: `object`
**默认值**:

```yaml
quality:
  soft_validation:
    suggest_body_for_complex: true
    suggest_body_for_user_facing: true
    scope_relevance: true
```

**说明**: 软检查（仅建议，不阻止）

| 选项 | 说明 | 触发条件 |
|-----|------|---------|
| `suggest_body_for_complex` | 建议添加 body | 文件数 > 3 |
| `suggest_body_for_user_facing` | 建议添加 body | 用户可见的功能 |
| `scope_relevance` | 建议检查 scope 相关性 | scope 与文件不匹配 |

---

### Preflight 检查 (`preflight_checks`)

提交前执行的自定义命令（可选）。

#### `enabled`

**类型**: `boolean`
**默认值**: `false`

**说明**: 是否启用 preflight 检查。

```yaml
preflight_checks:
  enabled: false
```

#### `commands`

**类型**: `list[string]`
**默认值**: `[]`

**说明**: 提交前执行的命令列表。

```yaml
preflight_checks:
  commands:
    - "npm run lint"
    - "pytest -x"  # 第一个失败就停止
    - "npm run test:unit"
```

#### `timeout`

**类型**: `integer`
**默认值**: `30`

**说明**: 每个命令的超时时间（秒）。

```yaml
preflight_checks:
  timeout: 30  # 30 秒超时
```

**行为说明**:
- 命令按顺序执行
- 任何一个失败 → 阻止提交
- 超时 → 阻止提交
- 所有命令通过 → 继续提交

---

## 配置示例

### 示例 1: 最小配置

```yaml
# .git-commit-agent.yml

convention: vuejs
auto_add:
  enabled: true
```

### 示例 2: 前端项目配置

```yaml
# .git-commit-agent.yml

convention: vuejs

auto_add:
  enabled: true
  ask_before_add: true
  detect_ignore_dirs: true
  many_files_threshold: 50  # 前端项目通常文件较多
  common_ignore_dirs:
    - node_modules
    - .next
    - .nuxt
    - dist
    - build
    - coverage

message_language: follow_user

split_strategy:
  enabled: true
  max_modules_per_intent: 2  # 前端项目模块少
  max_files_per_commit: 15

module_map:
  frontend: ["src/", "components/"]
  styles: ["styles/", "css/", "scss/"]
  assets: ["assets/", "images/", "icons/"]
  config: ["*.config.js", "*.config.ts"]

sensitive_detection:
  enabled: true
  allowlist:
    - "example"
    - "test"
    - "localhost"
```

### 示例 3: 后端项目配置

```yaml
# .git-commit-agent.yml

convention: vuejs

auto_add:
  enabled: true
  detect_ignore_dirs: true
  common_ignore_dirs:
    - target
    - .m2
    - __pycache__
    - .pytest_cache
    - .venv
    - venv

split_strategy:
  enabled: true
  max_modules_per_intent: 3
  max_files_per_commit: 10
  check_dependencies: true

module_map:
  backend: ["src/main/java/", "src/main/"]
  api: ["api/", "controllers/"]
  service: ["service/", "services/"]
  model: ["model/", "models/", "entities/"]
  repository: ["repository/", "repositories/"]
  test: ["src/test/", "**/*Test.java"]

quality:
  hard_validation:
    format: true
    type_valid: true
    subject_max_length: 50
    no_period: true

preflight_checks:
  enabled: true
  commands:
    - "mvn test"  # Maven
    # 或
    # - "pytest -x"  # Python
  timeout: 60
```

### 示例 4: Monorepo 配置

```yaml
# .git-commit-agent.yml (monorepo 根目录)

convention: vuejs

split_strategy:
  enabled: true
  max_modules_per_intent: 4  # Monorepo 模块较多
  max_files_per_commit: 15

module_map:
  # Apps
  app-frontend: ["apps/frontend/", "web/"]
  app-backend: ["apps/backend/", "api/"]
  app-mobile: ["apps/mobile/", "ios/", "android/"]

  # Packages
  pkg-shared: ["packages/shared/", "libs/shared/"]
  pkg-utils: ["packages/utils/", "libs/utils/"]
  pkg-ui: ["packages/ui/", "libs/ui/"]

  # Infra
  infra: ["infra/", "terraform/", "k8s/"]
  docs: ["docs/"]
  ci: [".github/", ".gitlab/"]

sensitive_detection:
  enabled: true
  allowlist:
    - "example"
    - "test"
    - "dev"
    - "staging"
```

### 示例 5: 全局配置

```yaml
# ~/.git-commit-agent.yml

convention: vuejs

message_language: follow_user

split_strategy:
  enabled: true
  max_modules_per_intent: 3
  max_files_per_commit: 10

sensitive_detection:
  enabled: true
  allowlist:
    - "example"
    - "test"
    - "dummy"

quality:
  hard_validation:
    format: true
    type_valid: true
    subject_max_length: 50
    no_period: true
```

---

## 配置验证

### 检查配置是否生效

在项目根目录运行：

```bash
# 查看当前配置
cat .git-commit-agent.yml

# 测试 skill
/commit --dry-run
```

### 常见配置问题

#### 问题 1: 配置未生效

**症状**: 配置文件存在，但行为不符合预期

**排查**:
1. 确认文件名正确：`.git-commit-agent.yml`
2. 确认位置正确：项目根目录
3. 检查 YAML 语法（缩进错误）

```bash
# 检查 YAML 语法
python -c "import yaml; yaml.safe_load(open('.git-commit-agent.yml'))"
```

#### 问题 2: 模块映射不匹配

**症状**: Scope 自动识别不准确

**解决**:
1. 检查文件路径是否匹配 `module_map`
2. 添加自定义模块映射
3. 使用通配符匹配

#### 问题 3: 误报敏感信息

**症状**: 测试数据被识别为敏感信息

**解决**:
1. 添加到 `allowlist`
2. 使用 `example`、`test` 等关键词

---

## 相关文档

- [SKILL.md](../SKILL.md) - 核心工作流
- [SENSITIVE_RULES.md](SENSITIVE_RULES.md) - 敏感信息检测详解
- [DECISION_TREE.md](DECISION_TREE.md) - 拆分决策树
- [EXAMPLES.md](EXAMPLES.md) - 使用示例

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
