# 依赖判定标准

本文档定义 Git Commit Agent 在拆分 commit 时使用的依赖关系判定标准。

## 核心原则

**拆分 vs 合并的核心问题**：多个变更是否可以独立存在并分别提交？

**关键判定标准**：
- 拆分后的每个 commit 是否都是**可用的**（usable）
- 拆分后的每个 commit 是否都可以**独立运行和部署**

---

## 依赖关系类型

### 1. 有依赖（应合并）

**定义**：变更之间存在代码级别的依赖关系，拆分会导致编译错误、运行时错误或功能不完整。

#### 判定标准

✅ **代码引用了新配置文件中的配置**
- 示例：Java代码使用 `@Value("${app.feature.enabled}")` 引用新配置
- 示例：Python代码使用 `os.getenv("DATABASE_URL")` 引用环境变量
- 示例：Spring Boot使用 `@ConfigurationProperties` 绑定配置
- **为什么应合并**：没有配置文件，代码无法运行

✅ **API/Schema 变更需要调用方同步更新**
- 示例：修改了 OpenAPI/GraphQL schema（字段类型、结构）
- 示例：修改了 protobuf 定义（消息格式）
- 示例：修改了 REST API 接口（请求/响应格式）
- **为什么应合并**：拆分会导致接口不匹配，调用方无法正确使用

✅ **函数/方法重命名需要所有使用方同步更新**
- 示例：重命名公共方法 `getUserById()` → `getUserId()`
- 示例：重命名函数参数类型
- **为什么应合并**：拆分会导致编译错误（调用方使用旧方法名）

✅ **数据库 schema 变更影响数据兼容性**
- 示例：删除表字段（会导致查询失败）
- 示例：修改字段类型（int → string）
- 示例：修改字段名称（column_a → column_b）
- **为什么应合并**：拆分会导致数据访问层错误

✅ **环境变量变更导致代码依赖**
- 示例：代码新增必需的环境变量（如 `API_KEY`）
- 示例：环境变量格式变更（从下划线改为驼峰）
- **为什么应合并**：没有环境变量，代码无法启动

#### 合并示例

```
Staged files:
  - backend/service/UserService.java (新增 database 连接)
  - backend/config/application.yml (添加 database URL)

分析:
  - UserService.java 引用了新配置中的数据库 URL
  - 没有配置文件，代码无法连接数据库
  - ✅ 有依赖 → 合并

Commit: feat(user): add database connection

- Add UserService with database connectivity
- Configure PostgreSQL data source in application.yml
```

---

### 2. 无依赖（应拆分）

**定义**：变更之间仅在业务逻辑上相关，但没有代码级别的依赖关系。拆分后的每个 commit 都可以独立运行和测试。

#### 判定标准

✅ **应用层可以独立运行和测试**
- 代码变更不依赖其他层面的变更
- 代码可以独立编译、运行、测试
- 不需要配置文件或基础设施的支持

✅ **基础设施层可以独立存在**
- Docker/CI 配置变更不影响代码逻辑
- 部署配置可以独立应用
- 基础设施变更不会导致代码无法运行

✅ **仅有业务关联，无代码依赖**
- 两个变更虽然在业务上相关，但技术上可以独立部署
- 例如：优化日志代码 + 优化 Docker healthcheck
- 例如：添加新功能 + 更新文档

✅ **各层面的变更可以分别提交和部署**
- 拆分后的每个 commit 都是**可用的**
- 每个 commit 都可以通过测试
- 每个 commit 都可以独立部署到生产环境

#### 拆分示例

```
Staged files:
  - backend/service/CommandExecutionService.java (添加 logCommand 参数)
  - backend/Dockerfile (优化 healthcheck)
  - docker-compose.yml (统一 healthcheck 配置)
  - backend/.dockerignore (添加 Dockerfile)
  - frontend/.dockerignore (添加 Dockerfile)

分析:
  - 应用层：代码逻辑变更（新增参数支持灵活日志控制）
  - 基础设施层：部署配置变更（优化 healthcheck 配置）
  - ✅ 应用层可以独立运行和测试
  - ✅ 基础设施层可以独立存在
  - ✅ 仅有业务关联（都是 refactor healthcheck 相关），无代码依赖
  - ✅ 各层面的变更可以分别提交和部署
  - ✅ 无依赖 → 拆分

Commit 1: refactor(service): add logCommand parameter

- Add logCommand parameter to executeLocal()
- Support INFO and DEBUG logging levels
- Apply DEBUG level for health checks to reduce log noise
- Files: CommandExecutionService.java

Commit 2: refactor(docker): optimize health check configuration

- Move health check from Dockerfile to docker-compose.yml
- Update health check endpoint to http://127.0.0.1:80/
- Reduce start_period from 10s to 5s
- Add Dockerfile to .dockerignore
- Files: Dockerfile, docker-compose.yml, .dockerignore
```

---

## 常见误判案例

### 案例 1：误判"支持"为"依赖"

❌ **错误判断**：
```
- Java代码添加了logCommand参数，支持Docker的healthcheck
- "Java changes support Docker changes" → 有依赖 → 合并
```

✅ **正确判断**：
```
- 应用层：代码逻辑变更（添加参数支持灵活日志控制）
- 基础设施层：部署配置变更（优化 healthcheck 配置）
- Java代码的 logCommand 参数虽然用于减少 healthcheck 的日志
  但这只是**业务逻辑上的关联**，不是**代码依赖关系**
- ✅ 应用层可以独立运行
- ✅ 基础设施层可以独立存在
- ✅ 无依赖 → 应该拆分
```

### 案例 2：误判"功能相关"为"依赖"

❌ **错误判断**：
```
- 添加了新功能 + 更新了API文档
- "文档是为新功能写的" → 有依赖 → 合并
```

✅ **正确判断**：
```
- 代码已经实现并可以运行
- 文档是补充说明，不影响代码功能
- ✅ 代码可以独立运行和测试
- ✅ 文档可以独立更新
- ✅ 无依赖 → 应该拆分（先代码，后文档）
```

### 案例 3：误判"同时变更"为"依赖"

❌ **错误判断**：
```
- 同时修改了 UserService.java 和 OrderService.java
- "都是同一个 refactor 任务的一部分" → 有依赖 → 合并
```

✅ **正确判断**：
```
- UserService: 用户功能
- OrderService: 订单功能
- 两者功能不同，无代码依赖
- ✅ 可以独立运行和测试
- ✅ 可以分别提交和部署
- ✅ 无依赖 → 应该拆分
```

---

## 失败案例分析

### 案例：误判"业务关联"为"代码依赖"（真实案例）

**场景背景**:
一个包含应用层和基础设施层混合变更的 refactor 任务，模型错误地判断为"有依赖"而合并提交。

**变更内容**:
```
Staged files:
  - backend/.../CommandExecutionService.java (refactor, 应用层)
  - backend/.../CommandExecutionService.java (refactor, 应用层)
  - backend/.dockerignore (refactor, 基础设施层)
  - backend/Dockerfile (refactor, 基础设施层)
  - frontend/.dockerignore (refactor, 基础设施层)
  - frontend/Dockerfile (refactor, 基础设施层)
  - docker-compose.yml (refactor, 基础设施层)
```

**模型的错误分析**:
```
Looking at the changes more carefully:
  - The Java code changes are minor (just adding a logCommand parameter)
  - The main focus is on Docker configuration (health checks)
  - The Java changes support the Docker changes (conditional logging for health checks)
  → Decision: "应用代码支持 Docker 配置" = 有依赖 = 合并为单个提交
```

**正确的分析**:
```
1. 按 Intent 分组: refactor - 所有文件属于同一意图

2. 检查层面:
   - 应用层: CommandExecutionService.java × 2 (新增 logCommand 参数)
   - 基础设施层: Dockerfile × 2, docker-compose.yml, .dockerignore × 2

3. 检查依赖:
   - 应用层: 代码逻辑变更（添加参数支持灵活日志控制）
   - 基础设施层: 部署配置变更（优化 healthcheck 配置）
   - **依赖判定**:
     ✅ 应用层可以独立运行和测试
     ✅ 基础设施层可以独立存在
     ✅ 仅有业务关联（都是 refactor healthcheck 相关），无代码依赖
     ✅ 各层面的变更可以分别提交和部署
   - **结论**: 无依赖 → 应该拆分

4. 正确的拆分方案:
   Commit 1: refactor(service): add logCommand parameter
   - Add logCommand parameter to executeLocal()
   - Support conditional logging for health checks
   - Files: CommandExecutionService.java (2 个文件)

   Commit 2: refactor(docker): optimize health check configuration
   - Move health check from Dockerfile to docker-compose.yml
   - Update health check endpoint to http://127.0.0.1:80/
   - Reduce start_period from 10s to 5s
   - Add Dockerfile to .dockerignore
   - Files: Dockerfile × 2, docker-compose.yml, .dockerignore × 2 (5 个文件)
```

**错误根源**:
1. **误判"支持"为"依赖"**：Java代码的 logCommand 参数虽然用于减少 healthcheck 的日志，但这只是业务逻辑上的关联，不是代码依赖关系
2. **缺少明确的依赖判定标准**：模型没有使用"应用层可以独立运行"和"基础设施层可以独立存在"这两个关键判定标准
3. **缺少不确定性处理**：当模型判断"Java changes are minor"时，应该意识到这是一个边界情况，肯定度不足85%，应该询问用户而非自行决定

**经验教训**:
- ⚠️ **业务关联 ≠ 代码依赖**：两个变更虽然在业务上相关，但技术上可以独立部署，就应该拆分
- ✅ **使用明确的判定标准**：必须检查"应用层可以独立运行"和"基础设施层可以独立存在"
- ✅ **不确定时询问用户**：当肯定度 < 85% 时，应该使用 AskUserQuestion 让用户决定，而不是猜测
- ✅ **遵循默认原则**：应用层 + 基础设施层，默认倾向于拆分（除非明确有依赖）

**如何避免类似错误**:
1. 使用依赖判定标准清单，逐项检查
2. 评估自己的肯定度，如果 < 85%，立即询问用户
3. 参考 [DECISION_TREE.md](DECISION_TREE.md) 中的场景示例
4. 优先考虑"可以拆分"而非"可以合并"

---

## 依赖检测命令

### 1. 检查代码是否引用新配置

```bash
# Java/Spring
git diff --cached | grep -E '(@Value|@Property|@ConfigurationProperties|@Autowired)'

# Python
git diff --cached | grep -E '(os\.getenv|os\.environ|config\.get)'

# JavaScript/Node.js
git diff --cached | grep -E '(process\.env|config\.get)'
```

### 2. 检查是否有配置文件变更

```bash
git diff --cached --name-only | grep -E '(\.yml|\.yaml|\.toml|\.json|config/|\.env|\.properties)'
```

### 3. 检查 API/Schema 变更

```bash
# OpenAPI/Swagger
git diff --cached --name-only | grep -E '(swagger|openapi)\.(yaml|yml|json)'

# GraphQL
git diff --cached --name-only | grep -E '\.graphql$|\.gql$'

# Protobuf
git diff --cached --name-only | grep -E '\.proto$'
```

### 4. 检查函数/方法重命名

```bash
# 检查是否有定义变更
git diff --cached | grep -E '^\+.*def \w+|^\+.*public \w+ \w+\('

# 检查是否有调用变更
git diff --cached | grep -E '^\-.*\w+\(\)'
```

### 5. 检查数据库 schema 变更

```bash
# SQL migration files
git diff --cached --name-only | grep -E '(migration|schema|sql)/.*\.sql$'

# ORM annotations (Java)
git diff --cached | grep -E '@Column|@Table|@Entity'
```

---

## 判定流程

### Step 1: 检测变更层面

```bash
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

### Step 2: 检查依赖关系

对于每个层面的变更，逐一检查：

1. **应用层 + 配置层**
   - 检查：代码是否引用了新配置？
   - 命令：`git diff --cached | grep -E '(@Value|getenv|config\.get)'`
   - 判断：
     - ✅ 有引用 → 合并
     - ❌ 无引用 → 拆分

2. **应用层 + 基础设施层**
   - 检查：应用层是否可以独立运行？
   - 检查：基础设施层是否可以独立存在？
   - 判断：
     - ✅ 都可以 → 拆分
     - ❌ 有一个不可以 → 合并

3. **应用层 + 文档层**
   - 检查：代码是否已经完整可用？
   - 判断：
     - ✅ 代码完整 → 拆分（先代码，后文档）
     - ❌ 代码不完整，依赖文档说明 → 合并

### Step 3: 评估肯定度

问自己：**我对这个拆分/合并决策的肯定度是多少？**

- **肯定度 ≥ 85%**：执行决策
- **肯定度 < 85%**：使用 AskUserQuestion 询问用户

### Step 4: 执行或询问

- **肯定度 ≥ 85%**：继续执行 Step 5 (Generate Commit Message)
- **肯定度 < 85%**：使用 AskUserQuestion 询问用户如何拆分

---

## 最佳实践

### 1. 优先考虑"可以拆分"

当遇到边界情况时，优先考虑"可以拆分"而非"可以合并"。

**理由**：
- 拆分的 commit 更原子化，更容易 code review
- 拆分的 commit 更容易 revert（回滚）
- 拆分的 commit 更容易 cherry-pick（选择性合并）

### 2. 不确定时询问用户

当肯定度 < 85% 时，应该使用 AskUserQuestion 询问用户。

**关键原则**：宁可询问用户，也不要自行猜测并做出错误的拆分决策。

### 3. 使用判定标准清单

不要凭感觉判断，使用明确的判定标准清单：

- [ ] 代码是否引用了新配置？
- [ ] 是否有 API/Schema 变更？
- [ ] 是否有函数/方法重命名？
- [ ] 是否有数据库 schema 变更？
- [ ] 应用层可以独立运行吗？
- [ ] 基础设施层可以独立存在吗？
- [ ] 各层面可以分别部署吗？

### 4. 参考实际案例

参考 [DECISION_TREE.md](DECISION_TREE.md) 中的实际场景示例，包括：
- 场景 1: 完整拆分（多意图 + 多层面）
- 场景 2: 合并（有依赖）
- 场景 3: 用户真实案例（层面拆分）
- 失败案例分析

---

## 相关文档

- [SKILL.md](../SKILL.md) - 核心工作流
- [DECISION_TREE.md](DECISION_TREE.md) - 完整决策树和场景示例
- [EXAMPLES.md](EXAMPLES.md) - 使用示例
- [INTERACTION_PATTERNS.md](INTERACTION_PATTERNS.md) - 用户交互模式

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
