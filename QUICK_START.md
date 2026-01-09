# Git Commit Agent Skill - 快速开始

## ✅ 安装已完成！

Skill 已安装到: `~/.claude/skills/git-commit-agent/`

## 🚀 如何使用

### 方式 1: 简单提交

```bash
# 1. 先添加文件到暂存区
git add some_file.py

# 2. 在 Claude Code 中使用
/commit 添加了用户登录功能
```

### 方式 2: Dry-Run 模式（预览）

```bash
# 查看会怎么提交，但不实际执行
/commit --dry-run 修复了 API bug
```

### 方式 3: 提供详细上下文

```bash
/commit
- 实现了异步任务执行
- 添加了任务状态跟踪
- 修复了超时处理 bug
```

## 🎯 主要功能

### 1. 自动添加文件
- 如果没有 staged 文件，会自动 `git add .`
- 检测并建议添加 `.gitignore` 规则
- 当有超过 100 个文件变更时，会提醒检查

### 2. 敏感信息检测
自动检测并阻止：
- AWS Keys、GitHub tokens、GitLab tokens
- PEM 私钥块
- API keys、passwords、secrets

### 3. 智能拆分
- 按意图分组（feat/fix/docs）
- 按模块细分（backend/frontend）
- 检查依赖关系，避免拆出不可用的 commit

### 4. 生成规范 message
遵循 Vue.js Commit Convention：
```
feat(auth): add user login functionality

- Implement JWT authentication
- Add login form component
- Integrate with backend API
```

### 5. Breaking Change 检测
自动检测 API 变更并添加 `!` 标记：
```
feat(api)!: change response format

BREAKING CHANGE: API now uses camelCase
```

## ⚙️ 配置（可选）

在项目根目录创建 `.git-commit-agent.yml`：

```yaml
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
  check_dependencies: true

# 模块映射
module_map:
  backend: ["backend/", "server/", "api/"]
  frontend: ["frontend/", "web/", "ui/"]
  docs: ["docs/", "*.md"]

# 敏感信息检测
sensitive_detection:
  enabled: true
  allowlist:
    - "example"
    - "test"
    - "dummy"
```

## 📝 使用示例

### 示例 1: 新功能

```bash
# 添加代码
git add AuthService.py AuthController.py

# 提交
/commit 添加了用户认证功能

# 生成：
feat(auth): add user authentication functionality

- Implement JWT authentication service
- Add login API endpoints
- Support token refresh mechanism
```

### 示例 2: Bug 修复

```bash
git add UserService.py

/commit 修复了空指针异常

# 生成：
fix(user): resolve null pointer in UserService

- Add null check for user object
- Fix crash when user ID is invalid
```

### 示例 3: 多模块拆分

```bash
git add backend/API.py frontend/api.ts docs/api.md

/commit 更新了 API 接口和文档

# Skill 会询问：
建议拆分为 2 个提交:
1. feat(api): update user endpoints (backend + frontend)
2. docs: update API documentation

选项:
1. 确认拆分
2. 合并为单个
```

### 示例 4: 检测到敏感信息

```bash
git add config.py

/commit 添加配置文件

# Skill 会警告：
🚨 强规则命中 - 检测到敏感信息！
文件: config.py:3
  API_KEY=sk-ant-xxx

处理建议:
1. 撤回 staged: git restore --staged config.py
2. 替换为环境变量
3. 添加到 .gitignore
```

## 🔧 常用命令

| 命令 | 说明 |
|------|------|
| `/commit` | 智能提交当前变更 |
| `/commit --dry-run` | 预览不会实际执行 |
| `/commit --verbose` | 显示详细决策过程 |
| `/commit --lang=en 中文描述` | 强制使用英文 |

## 📚 更多帮助

- 完整文档: [INSTALL.md](INSTALL.md)
- 项目说明: [claude.md](claude.md)
- 开发计划: [TODO.md](TODO.md)

## 🎉 开始使用

现在就可以尝试了！

```bash
# 在你的项目中
cd /path/to/your/project
git add .
/commit 添加了新功能
```

享受智能的 Git 提交体验！
