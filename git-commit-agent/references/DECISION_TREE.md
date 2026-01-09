# Commit 拆分决策树

本文档详细说明 Git Commit Agent 的 commit 拆分决策逻辑和场景。

## 核心原则

**Intent-First Splitting** - 按意图优先分组

主要拆分标准：`commit type` (feat/fix/docs/etc.)
次要拆分标准：`module` 和 `layer`

---

## 完整决策树

### 决策流程图

```
┌─────────────────────────────────────┐
│   1. 分析所有 Staged 变更            │
│   - 扫描文件列表                     │
│   - 检测敏感信息                     │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│   2. 按 Intent (Type) 分组          │
│   - feat, fix, docs, test, etc.     │
└──────────┬──────────────────────────┘
           │
     ┌─────┴─────┐
     │           │
  单意图       多意图 ← 必须拆分
     │           │
     ▼           ▼
  继续判断   按意图拆分
     │
     ▼
┌─────────────────────────────────────┐
│   3. 检查变更层面 (Layer)           │
│   - 应用层 / 基础设施层               │
│   - 配置层 / 文档层                  │
└──────────┬──────────────────────────┘
           │
     ┌─────┴─────┐
     │           │
  单层面       多层面
     │           │
     ▼           ▼
  继续判断   检查依赖关系
                    │
              ┌─────┴─────┐
              │           │
            有依赖      无依赖
              │           │
              ▼           ▼
            合并      按层面拆分
              │
              ▼
     ┌────────────────┐
     │ 4. 检查模块    │
     │ - 单模块       │
     │ - 多模块       │
     └───────┬────────┘
             │
       ┌─────┴─────┐
       │           │
    单模块       多模块
       │           │
       ▼       ┌───┴────┐
   单个提交  相关    不相关
              │        │
              ▼        ▼
            合并    按模块拆分
```

---

## 拆分标准详解

### 1. Intent (Type) 拆分

#### Commit Type 分类

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | 添加用户登录 |
| `fix` | Bug 修复 | 修复空指针异常 |
| `docs` | 文档变更 | 更新 API 文档 |
| `test` | 测试变更 | 添加单元测试 |
| `ci` | CI 配置 | 更新 GitHub Actions |
| `build` | 构建系统 | 更新 Maven 配置 |
| `refactor` | 代码重构 | 提取公共逻辑 |
| `chore` | 其他杂项 | 更新依赖版本 |

#### 拆分规则

**✅ 必须拆分**:
- `feat` + `fix` → 2 个 commits
- `docs` + `feat` → 2 个 commits
- `test` + `fix` → 2 个 commits（通常 test 和 fix 一起）

**⚠️ 可以合并**:
- `feat` + `refactor`（如果 refactor 支持同一个 feature）
- `test` + `feat`（如果是新功能的测试）

**❌ 不应该拆分**:
- `chore` + `chore` → 合并
- 同一 type 的紧密相关变更 → 合并

---

### 2. Layer (层面) 拆分

#### 层面定义

**1. 应用层 (Application Layer)**

- **文件类型**: `.java`, `.py`, `.ts`, `.js`, `.go`, `.rs`, `.c`, `.cpp`, `.h`, `.cs`
- **内容**: 业务逻辑、API 实现、数据处理
- **变更性质**: 功能实现、bug 修复、代码重构

**2. 基础设施层 (Infrastructure Layer)**

- **文件类型**: `Dockerfile`, `docker-compose.yml`, `.dockerignore`, `.github/`, `.gitlab-ci.yml`
- **内容**: Docker 配置、CI/CD 配置
- **变更性质**: 部署配置、构建配置、环境配置

**3. 配置层 (Configuration Layer)**

- **文件类型**: `*.yml`, `*.yaml`, `*.toml`, `*.json`, `config/`
- **内容**: 应用配置、环境变量
- **变更性质**: 配置参数调整

**4. 文档层 (Documentation Layer)**

- **文件类型**: `*.md`, `*.txt`, `*.rst`, `docs/`
- **内容**: 文档、说明
- **变更性质**: 文档更新

#### 检测命令

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
  fi
done
```

#### 拆分规则

**For detailed dependency determination criteria**: See [DEPENDENCY_CRITERIA.md](DEPENDENCY_CRITERIA.md)

**场景 1: 应用层 + 基础设施层** → 通常拆分

**示例**:
```
应用层:
  - CommandExecutionService.java (新增 logCommand 参数)

基础设施层:
  - Dockerfile
  - docker-compose.yml
  - .dockerignore

判断:
  ✅ 应用层可以独立运行
  ✅ 基础设施层可以独立存在

建议拆分:
  Commit 1: refactor(service): add logCommand parameter
  Commit 2: refactor(docker): optimize health check configuration
```

**场景 2: 应用层 + 配置层** → 检查依赖

**示例**:
```
应用层:
  - UserService.java (新增数据库连接参数)

配置层:
  - application.yml (添加数据库连接字符串)

判断:
  ⚠️  配置层变更依赖应用层代码
  ❌ 代码需要新配置才能运行

建议合并:
  Commit 1: feat(user): add database connection with configuration
```

**依赖检测**:
```bash
# 检查代码是否引用新配置
git diff --cached | grep -E '(@Value|@Property|Configuration|getConfig|getenv)'

# 检查是否有配置文件变更
git diff --cached --name-only | grep -E '(\.yml|\.yaml|\.properties|\.env)'

# 如果代码引用新配置，且配置文件有变更 → 合并
```

**场景 3: 基础设施层 + 配置层** → 通常拆分

**示例**:
```
基础设施层:
  - Dockerfile (更新基础镜像)

配置层:
  - application.yml (调整日志级别)

判断:
  ✅ 两者独立

建议拆分:
  Commit 1: refactor(docker): upgrade base image
  Commit 2: chore(config): adjust log level
```

---

### 3. Module (模块) 拆分

#### 模块识别

**使用 `module_map` 配置**:

```yaml
module_map:
  backend: ["backend/", "src/main/"]
  frontend: ["frontend/", "web/"]
  docs: ["docs/", "*.md"]
  test: ["tests/", "test/"]
```

#### 拆分规则

**单模块** → 单个 commit

**多模块相关**（同一功能） → 合并

**示例**:
```
Files:
  - backend/service/AuthService.java
  - backend/controller/AuthController.java
  - frontend/src/components/LoginForm.tsx

Analysis:
  - 同一功能: 用户登录
  - backend + frontend 协作
  - frontend 依赖 backend API

Decision: 合并为单个 commit

Commit: feat(auth): add user login functionality
```

**多模块不相关** → 拆分

**示例**:
```
Files:
  - backend/service/UserService.java
  - backend/service/OrderService.java
  - frontend/src/components/Settings.tsx

Analysis:
  - UserService.java: 用户功能
  - OrderService.java: 订单功能
  - Settings.tsx: 设置页面

  不同功能，无依赖

Decision: 拆分为 3 个 commits

Commit 1: feat(user): add user profile feature
Commit 2: feat(order): implement order processing
Commit 3: feat(frontend): add settings page
```

---

### 4. Dependency (依赖) 检测

#### MERGE 倾向（避免破坏 commits）

**场景 1: API/Interface 文件同时变更**

```
Files:
  - backend/api/UserAPI.java (添加新端点)
  - backend/service/UserService.java (实现新端点)
  - frontend/src/api/user.ts (调用新端点)

Analysis:
  - API 变更需要同步到 frontend
  - 拆分会破坏功能完整性

Decision: 合并

Commit: feat(user): add user profile API
```

**场景 2: Schema 变更**

```
Files:
  - backend/model/User.java (添加字段)
  - backend/service/UserService.java (使用新字段)
  - backend/mapper/UserMapper.java (更新查询)

Analysis:
  - Schema 变更影响多层
  - 拆分会破坏数据库结构

Decision: 合并

Commit: feat(user): add email field to user model
```

**场景 3: Rename + Usage**

```
Files:
  - backend/service/UserService.java (重命名方法)
  - backend/controller/UserController.java (更新调用)
  - frontend/src/api/user.ts (更新调用)

Analysis:
  - 重命名需要同步所有使用方
  - 拆分会导致编译错误

Decision: 合并

Commit: refactor(user): rename getUserId to getId
```

#### SPLIT 倾向

**场景 1: 独立功能**

```
Files:
  - backend/service/AuthService.java
  - backend/service/UserService.java

Analysis:
  - AuthService: 认证功能
  - UserService: 用户管理
  - 无依赖关系

Decision: 拆分

Commit 1: feat(auth): implement JWT authentication
Commit 2: feat(user): add user CRUD operations
```

**场景 2: 文档独立**

```
Files:
  - backend/service/UserService.java
  - docs/api/users.md

Analysis:
  - 代码已实现
  - 文档是补充说明

Decision: 拆分（通常先提交代码，再更新文档）

Commit 1: feat(user): add user management
Commit 2: docs: update user API documentation
```

---

## 实战场景

### 场景 1: 完整拆分（多意图 + 多层面）

**Input**:
```
Staged files:
  - backend/service/UserService.java (feat, 应用层)
  - backend/service/AuthService.java (feat, 应用层)
  - Dockerfile (chore, 基础设施层)
  - docker-compose.yml (chore, 基础设施层)
  - docs/api.md (docs, 文档层)
```

**Decision Tree**:
```
1. 按 Intent 分组:
   - feat: UserService.java, AuthService.java
   - chore: Dockerfile, docker-compose.yml
   - docs: docs/api.md

2. feat 组 (应用层):
   - UserService: user 功能
   - AuthService: auth 功能
   - 无依赖 → 按模块拆分

3. chore 组 (基础设施层):
   - Docker 配置
   - 单个 commit

4. docs 组:
   - 单独 commit

最终: 4 个 commits
```

**Output**:
```
Commit 1: feat(user): add user CRUD operations
Commit 2: feat(auth): implement JWT authentication
Commit 3: chore(docker): optimize Docker configuration
Commit 4: docs: update API documentation
```

---

### 场景 2: 合并（有依赖）

**Input**:
```
Staged files:
  - backend/model/User.java (feat, 应用层)
  - backend/service/UserService.java (feat, 应用层)
  - backend/config/database.yml (feat, 配置层)
```

**Decision Tree**:
```
1. 按 Intent 分组:
   - feat: 所有文件 (同一意图)

2. 检查层面:
   - 应用层: User.java, UserService.java
   - 配置层: database.yml

3. 检查依赖:
   - UserService.java 引用新数据库配置
   - 代码依赖配置 → 必须合并

4. 检查模块:
   - 都在 backend 模块
   - 相关功能

最终: 1 个 commit
```

**Output**:
```
Commit 1: feat(user): add user database integration

- Add User entity with JPA mapping
- Implement UserService with CRUD operations
- Configure PostgreSQL data source
```

---

### 场景 3: 用户真实案例（层面拆分）

**Input**:
```
Staged files:
  - slurm-agent/.../CommandExecutionService.java (refactor, 应用层)
  - Dockerfile (refactor, 基础设施层)
  - docker-compose.yml (refactor, 基础设施层)
  - slurm-agent/.dockerignore (refactor, 基础设施层)
  - backend/.dockerignore (refactor, 基础设施层)
```

**Decision Tree**:
```
1. 按 Intent 分组:
   - refactor: 所有文件 (同一意图)

2. 检查层面:
   - 应用层: CommandExecutionService.java
   - 基础设施层: Dockerfile, docker-compose.yml, *.dockerignore

3. 检查依赖:
   - 应用层: 新增 logCommand 参数（代码逻辑变更）
   - 基础设施层: 优化健康检查（部署配置变更）
   - 无依赖 → 可以拆分

4. 检查模块:
   - 应用层: slurm-agent 模块
   - 基础设施层: 项目根级别（跨模块）

最终: 2 个 commits
```

**Output**:
```
Commit 1: refactor(service): add logCommand parameter

- Add logCommand parameter to executeLocal()
- Support INFO and DEBUG logging levels
- Apply DEBUG level for health checks to reduce log noise
- Files: CommandExecutionService.java (2 个文件)

Commit 2: refactor(docker): optimize health check configuration

- Move health check from Dockerfile to docker-compose.yml
- Update health check endpoint to http://127.0.0.1:80/
- Reduce start_period from 10s to 5s
- Add Dockerfile to .dockerignore to avoid accidental copy
- Files: Dockerfile, docker-compose.yml, *.dockerignore (5 个文件)
```

---

## 决策辅助命令

### 检测变更层面

```bash
#!/bin/bash
# analyze_layers.sh

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

### 检测代码依赖配置

```bash
# 检查是否引用新配置
git diff --cached | grep -E '(@Value|@Property|Configuration|getConfig|getenv)'

# 检查是否有配置文件变更
git diff --cached --name-only | grep -E '(\.yml|\.yaml|\.properties|\.env)'
```

### 统计各层面文件数

```bash
echo "应用层: $(git diff --cached --name-only | grep -E '\.(java|py|ts|js)$' | wc -l)"
echo "基础设施层: $(git diff --cached --name-only | grep -E '(Dockerfile|docker-compose)' | wc -l)"
echo "配置层: $(git diff --cached --name-only | grep -E '\.(yml|yaml)$' | wc -l)"
echo "文档层: $(git diff --cached --name-only | grep -E '\.md$' | wc -l)"
```

---

## 最佳实践

### 1. 优先按 Intent 拆分

不同 intent 必须拆分，保持 commit 原子性。

### 2. 层面拆分要谨慎

只有确认无依赖时才按层面拆分，避免破坏功能。

### 3. 模块拆分看相关性

相关功能的多个模块可以合并，不相关的才拆分。

### 4. 依赖检查很重要

拆分前务必检查依赖关系，避免不可用的 commit。

### 5. 用户有最终决定权

Skill 只提供建议，用户可以根据实际情况调整。

### 6. 不确定时询问用户

当满足以下任一条件时，应该使用 AskUserQuestion 询问用户：
- **肯定度 < 85%**：对是否拆分、如何拆分不够确定
- **边界情况**：既不算明显有依赖，也不算明显无依赖
- **复杂场景**：涉及3个以上层面或模块的混合变更
- **缺乏先例**：没有明确的参考案例可以遵循

**关键原则**：宁可询问用户，也不要自行猜测并做出错误的拆分决策。

**For detailed failure case analysis**: See [DEPENDENCY_CRITERIA.md#失败案例分析](DEPENDENCY_CRITERIA.md#失败案例分析)

---

## 相关文档

- [SKILL.md](../SKILL.md) - 核心工作流
- [DEPENDENCY_CRITERIA.md](DEPENDENCY_CRITERIA.md) - 依赖判定标准
- [INTERACTION_PATTERNS.md](INTERACTION_PATTERNS.md) - 用户交互模式
- [CONFIGURATION.md](CONFIGURATION.md) - 配置说明（拆分策略）
- [EXAMPLES.md](EXAMPLES.md) - 使用示例
- [SENSITIVE_RULES.md](SENSITIVE_RULES.md) - 敏感信息检测

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
