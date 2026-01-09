# Git Commit Agent - 使用示例集

本文档提供 Git Commit Agent 的详细使用示例，涵盖从简单到复杂的各种场景。

## 目录

- [基础示例](#基础示例)
- [进阶示例](#进阶示例)
- [实战场景](#实战场景)
- [常见问题处理](#常见问题处理)

---

## 基础示例

### 示例 1: 简单功能（单个 commit）

**场景**: 添加用户登录功能

**用户输入**:
```bash
/commit 添加了用户登录功能
```

**Staged 文件**:
```
A backend/service/AuthService.java
A backend/controller/AuthController.java
A frontend/src/components/LoginForm.tsx
```

**执行流程**:
1. ✅ 检测到 3 个 staged 文件
2. ✅ 未检测到敏感信息
3. ✅ 单个意图（feat）跨越相关模块 → 单个提交

**生成的 Commit**:
```
feat(auth): add user login functionality

- Implement JWT authentication service
- Add login API endpoints
- Create login form component
- Integrate frontend with backend
```

**执行命令**:
```bash
git commit -m 'feat(auth): add user login functionality

- Implement JWT authentication service
- Add login API endpoints
- Create login form component
- Integrate frontend with backend'
```

---

### 示例 2: Bug 修复

**场景**: 修复空指针异常

**用户输入**:
```bash
/commit 修复了 UserService 的空指针异常
```

**Staged 文件**:
```
M backend/service/UserService.java
```

**执行流程**:
1. ✅ 检测到 1 个文件变更
2. ✅ 分析 diff → 修复 null check

**生成的 Commit**:
```
fix(user): resolve null pointer in UserService

- Add null check for user object
- Fix crash when user ID is invalid
- Add defensive programming for edge cases
```

---

### 示例 3: 文档更新

**场景**: 更新 API 文档

**用户输入**:
```bash
/commit 更新了 API 文档
```

**Staged 文件**:
```
M docs/api/authentication.md
M docs/api/endpoints.md
```

**生成的 Commit**:
```
docs(api): update authentication and endpoints documentation

- Clarify JWT authentication flow
- Add missing endpoint descriptions
- Update examples with new response format
```

---

### 示例 4: 重构

**场景**: 重构 Service 层代码结构

**用户输入**:
```bash
/commit 重构了 Service 层
```

**Staged 文件**:
```
M backend/service/UserService.java
M backend/service/OrderService.java
M backend/service/ProductService.java
```

**生成的 Commit**:
```
refactor(service): simplify service layer architecture

- Extract common logic to BaseService
- Reduce code duplication across services
- Improve error handling consistency
- Update unit tests
```

---

## 进阶示例

### 示例 5: 多意图拆分

**场景**: 同时有功能开发和文档更新

**用户输入**:
```bash
/commit 添加了用户功能并更新了文档
```

**Staged 文件**:
```
A backend/service/UserService.java
A backend/controller/UserController.java
M docs/api/users.md
M README.md
```

**Skill 分析**:
```
⚠️  检测到多个意图:
- feat: backend/* (功能开发)
- docs: docs/*, README.md (文档更新)

建议拆分为 2 个提交:

Commit 1: feat(user): add user management feature
  Files: 2
  - backend/service/UserService.java
  - backend/controller/UserController.java

Commit 2: docs: update user documentation
  Files: 2
  - docs/api/users.md
  - README.md

选项:
1. 确认拆分
2. 合并为单个
3. 调整方案
```

**用户选择**: 1 (确认拆分)

**执行**:
```bash
# Commit 1
git commit --only \
  backend/service/UserService.java \
  backend/controller/UserController.java \
  -m 'feat(user): add user management feature

- Implement CRUD operations for users
- Add validation and error handling
- Create RESTful API endpoints'

# Commit 2
git commit -m 'docs: update user documentation

- Add API endpoint documentation
- Update README with new features
- Include usage examples'
```

---

### 示例 6: 多模块拆分

**场景**: 同时修改 frontend 和 backend

**用户输入**:
```bash
/commit 更新了用户界面和 API
```

**Staged 文件**:
```
M backend/api/UserAPI.java
M frontend/src/components/UserList.tsx
M frontend/src/services/userService.ts
```

**Skill 分析**:
```
✅ 同一意图（feat），2 个相关模块（backend + frontend）

backend 变更依赖 frontend 调用新 API
→ 建议: 单个提交以保持一致性

如果确认拆分:
Commit 1: feat(api): update user endpoints
Commit 2: feat(frontend): update user UI

选项:
1. 单个提交（推荐）
2. 拆分为 2 个
```

---

### 示例 7: Breaking Change

**场景**: API 接口不兼容变更

**用户输入**:
```bash
/commit 修改了 API 响应格式
```

**Staged 文件**:
```
M backend/api/UserAPI.java
M frontend/src/services/userService.ts
```

**Skill 检测**:
```
⚠️  检测到 Breaking Change:
- 删除了旧的响应字段
- 修改了响应结构

确认这是 breaking change 吗？
1. 是，添加 '!' 标记
2. 否，普通提交
```

**用户选择**: 1

**生成的 Commit**:
```
feat(api)!: change user response format to camelCase

BREAKING CHANGE: UserAPI now returns camelCase instead of snake_case.
Frontend consumers must update accordingly.

- Rename all response fields to camelCase
- Update API documentation
- Add migration guide for frontend developers
```

---

### 示例 8: 层面拆分（应用层 + 基础设施层）

**场景**: 同时修改应用代码和 Docker 配置

**用户输入**:
```bash
/commit 优化了健康检查和日志
```

**Staged 文件**:
```
M backend/service/CommandExecutionService.java
M Dockerfile
M docker-compose.yml
M .dockerignore
```

**Skill 分析**:
```
⚠️  检测到多个层面:

应用层:
- backend/service/CommandExecutionService.java

基础设施层:
- Dockerfile
- docker-compose.yml
- .dockerignore

建议: 按层面拆分为 2 个提交

Commit 1: refactor(service): add logCommand parameter
  - backend/service/CommandExecutionService.java

Commit 2: refactor(docker): optimize health check configuration
  - Dockerfile
  - docker-compose.yml
  - .dockerignore

选项:
1. 确认拆分（推荐）
2. 单个提交
```

**用户选择**: 1

**Commit 1**:
```bash
git commit --only backend/service/CommandExecutionService.java \
  -m 'refactor(service): add logCommand parameter

- Add logCommand parameter to control log level
- Use DEBUG level for health checks to reduce noise
- Support flexible logging strategy'
```

**Commit 2**:
```bash
git commit -m 'refactor(docker): optimize health check configuration

- Move health check from Dockerfile to docker-compose.yml
- Update health check endpoint to http://127.0.0.1:80/
- Reduce start_period from 10s to 5s
- Add Dockerfile to .dockerignore to avoid accidental copy'
```

---

## 实战场景

### 场景 1: 完整功能开发（多次提交）

**项目**: 电商网站 - 购物车功能

**Session 1: 数据模型**
```bash
/commit 添加了购物车数据模型

# Staged:
M backend/model/Cart.java
M backend/model/CartItem.java

# Commit:
feat(model): add shopping cart data models

- Define Cart and CartItem entities
- Add relationships with User and Product
- Include validation rules
```

**Session 2: API 实现**
```bash
/commit 实现了购物车 API

# Staged:
M backend/controller/CartController.java
M backend/service/CartService.java

# Commit:
feat(api): implement shopping cart endpoints

- Add POST /cart/items (add item)
- Add DELETE /cart/items/:id (remove item)
- Add PUT /cart/items/:id (update quantity)
- Add GET /cart (get cart)
```

**Session 3: 前端 UI**
```bash
/commit 实现了购物车 UI

# Staged:
M frontend/src/components/Cart.tsx
M frontend/src/components/CartItem.tsx
M frontend/src/services/cartService.ts

# Commit:
feat(frontend): implement shopping cart UI

- Create cart component with item list
- Add add/remove/update quantity actions
- Integrate with backend API
- Show real-time total price
```

**Session 4: 测试**
```bash
/commit 添加了购物车测试

# Staged:
A backend/test/CartServiceTest.java
A frontend/test/Cart.test.tsx

# Commit:
test(cart): add shopping cart tests

- Backend: unit tests for CartService
- Frontend: component tests for Cart
- Cover add/remove/update operations
- Test edge cases (empty cart, max quantity)
```

---

### 场景 2: 紧急修复（快速提交）

**场景**: 生产环境 bug，需要紧急修复

```bash
# 1. 快速修复
vim backend/service/PaymentService.java

# 2. 立即提交
/commit 修复了支付金额计算错误的 bug

# Staged:
M backend/service/PaymentService.java

# Commit:
fix(payment): correct amount calculation bug

Hotfix for production issue where total amount was
calculated incorrectly when multiple items present.

- Fix decimal precision in amount calculation
- Add test case to prevent regression
```

**发布流程**:
```bash
# 3. 创建 hotfix 分支
git checkout -b hotfix/payment-calculation

# 4. 提交到远程
git push origin hotfix/payment-calculation

# 5. 创建 PR 合并到 main
```

---

### 场景 3: 大型重构（分步提交）

**项目**: 重构认证系统

**Phase 1: 提取公共代码**
```bash
/commit 提取认证公共逻辑到 BaseService

# Commit:
refactor(auth): extract common logic to BaseService

- Move token validation to base class
- Extract error handling patterns
- Reduce code duplication
```

**Phase 2: 重构 JWT 处理**
```bash
/commit 重构 JWT token 处理逻辑

# Commit:
refactor(auth): improve JWT token handling

- Centralize token generation in TokenService
- Add token refresh mechanism
- Improve error messages for invalid tokens
```

**Phase 3: 更新 API**
```bash
/commit 更新认证 API 接口

# Commit:
refactor(auth): update authentication endpoints

- Standardize response format
- Add more detailed error codes
- Update API documentation
```

**Phase 4: 更新测试**
```bash
/commit 更新认证相关测试

# Commit:
test(auth): update tests for refactored authentication

- Update unit tests for new structure
- Add integration tests for token refresh
- Increase test coverage to 90%
```

**Phase 5: 更新文档**
```bash
/commit 更新认证系统文档

# Commit:
docs(auth): update authentication documentation

- Document new authentication flow
- Add migration guide
- Update examples in README
```

---

### 场景 4: 协作开发（避免冲突）

**场景**: 多人协作同一功能

**Developer A**:
```bash
# 1. 创建功能分支
git checkout -b feature/user-profile

# 2. 开发 backend
/commit 实现了用户 profile backend API

# Commit:
feat(user): implement user profile backend

- Add GET /users/:id/profile endpoint
- Implement profile update logic
- Add validation for profile fields
```

**Developer B**:
```bash
# 1. 创建功能分支
git checkout -b feature/user-profile-ui

# 2. 开发 frontend
/commit 实现了用户 profile frontend UI

# Commit:
feat(frontend): implement user profile UI

- Create profile form component
- Add avatar upload functionality
- Integrate with backend API
```

**集成**:
```bash
# 3. 合并时自动拆分
git merge feature/user-profile-ui
git merge feature/user-profile

# 4. 如果有冲突，解决后
/commit 解决了合并冲突

# Commit:
chore: resolve merge conflicts in user profile

- Resolve conflicts in service layer
- Update imports after merge
- Ensure tests pass
```

---

## 常见问题处理

### 问题 1: 检测到敏感信息

**场景**: Commit 时触发敏感信息检测

```
🚨 强规则命中 - 检测到敏感信息！

文件: config/app.env:3
  DATABASE_URL=postgresql://user:password@localhost/db

处理建议:
1. 撤回 staged: git restore --staged config/app.env
2. 替换为环境变量
3. 添加到 .gitignore

选项:
1. 强制继续（不推荐）
2. 取消提交
3. 查看上下文
```

**解决步骤**:
```bash
# 1. 取消提交
2

# 2. 撤回 staged 文件
git restore --staged config/app.env

# 3. 修改文件，使用环境变量
vim config/app.env
# DATABASE_URL=${DATABASE_URL}

# 4. 重新添加
git add config/app.env

# 5. 再次提交
/commit 添加了环境变量配置模板
```

---

### 问题 2: 没有 staged 变更

**场景**: 忘记 `git add`

```
❌ 没有检测到 staged 变更

检测到以下未暂存的变更:
M backend/service/UserService.java
M frontend/src/App.tsx

是否自动 git add .?
1. 是，添加所有变更
2. 否，手动选择
```

**解决**:
```bash
# 选择 1，自动添加
# 或手动添加
git add backend/service/UserService.java
git add frontend/src/App.tsx
```

---

### 问题 3: Commit Message 过长

**场景**: Subject 超过 50 字符

```
❌ Subject 长度超过限制 (54/50)

当前: fix(user): resolve null pointer exception in UserService
建议: fix(user): resolve null pointer in UserService

选项:
1. 使用建议的版本
2. 手动修改
```

**解决**:
```bash
# 选择 1，自动缩短
```

---

### 问题 4: 需要拆分但用户不想拆

**场景**: Skill 建议拆分，但用户想合并

```
⚠️  建议拆分为 2 个提交...

选项:
1. 确认拆分
2. 合并为单个 ← 选择这个
```

**选择 2**:
```bash
# 会生成单个 commit，包含所有变更
feat(all): add user feature and update documentation

- Implement user management
- Add API endpoints
- Create frontend components
- Update documentation
```

---

## Dry-Run 模式

### 预览 Commit

**场景**: 想看会怎么提交，但不实际执行

```bash
/commit --dry-run 添加了新功能
```

**输出**:
```
🔍 Dry-Run Mode - 不会实际执行提交

=== 计划的提交 ===

Commit 1: feat(auth): add user authentication
  Files: 3
  - backend/service/AuthService.java
  - backend/controller/AuthController.java
  - frontend/src/components/LoginForm.tsx

  Message:
    feat(auth): add user authentication

    - Implement JWT authentication
    - Add login API endpoints
    - Create login form component

  将执行: git commit --only <files> -m "<message>"

=== 敏感信息检测 ===
✅ 未检测到敏感信息

=== 拆分建议 ===
✅ 单个提交

=== 质量检查 ===
✅ 格式正确
✅ Type 有效
✅ Subject 长度符合 (34/50)
✅ 无结尾句号

选项:
1. 确认执行
2. 调整方案
3. 取消
```

---

## 最佳实践

### 1. 频繁提交，小步快跑

❌ **不推荐**:
```bash
# 一次性提交大量变更
git add .
/commit 实现了整个用户系统（包含 50 个文件）
```

✅ **推荐**:
```bash
# 分阶段提交
/commit 添加了用户数据模型
/commit 实现了用户 API
/commit 实现了用户 UI
/commit 添加了用户测试
```

### 2. 每个Commit做一件事

❌ **不推荐**:
```bash
# 混合多个意图
git add backend/test frontend/docs
/commit 修复了bug并更新了文档
```

✅ **推荐**:
```bash
# 按意图拆分
git add backend
/commit 修复了用户验证bug

git add frontend
/commit 更新了登录UI

git add docs
/commit 更新了API文档
```

### 3. 写清晰的 Subject

❌ **不推荐**:
```
fix bug
update stuff
work on feature
```

✅ **推荐**:
```
fix(auth): resolve token validation error
feat(user): add password reset functionality
docs(api): update authentication endpoints
```

### 4. 使用 Body 解释"为什么"

❌ **不推荐**:
```
fix(user): fix null pointer

- Fix line 42
- Add check
```

✅ **推荐**:
```
fix(user): resolve null pointer in UserService

User object could be null when ID doesn't exist in database.
This caused crashes when fetching user profile with invalid ID.

- Add null check after database query
- Return 404 error when user not found
- Add unit test for edge case
```

---

## 相关文档

- [SKILL.md](../SKILL.md) - 核心工作流
- [CONFIGURATION.md](CONFIGURATION.md) - 配置说明
- [SENSITIVE_RULES.md](SENSITIVE_RULES.md) - 敏感信息检测
- [DECISION_TREE.md](DECISION_TREE.md) - 拆分决策树

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
