# Claude Code 项目说明

## 项目概述

**Git Commit Agent Skill** - 一个智能 Git 提交助手，将 git_commit_agent 转换为 Claude Code Skill，使用户可以通过简单的 `/commit` 命令来智能分析和提交代码。

## 项目目标

创建一个 Claude Code Skill，具备以下能力：
1. 自动分析代码变更
2. 检测敏感信息（API keys、tokens、密码等）
3. 智能拆分不相关的变更
4. 生成符合规范的 commit message（遵循 Vue.js 或 Conventional Commits 规范）
5. 对 commit message 进行质量评分
6. 交互式确认流程

## 技术架构

### 参考实现
本项目基于 `../git_commit_agent` 的功能和逻辑进行转换。

### 核心组件

**git_commit_agent 原始架构**:
```
git_commit_agent/
├── agent.py                 # 主类 GitCommitAgent
├── commit_conventions.py    # Commit 规范定义
├── requirements.txt         # Python 依赖
├── README.md               # 项目说明
└── USAGE.md                # 使用指南
```

**Claude Code Skill 目标架构**:
```
git_commit_agent-skill/
├── skill/                   # Claude Code Skill 目录
│   ├── skill.yaml          # Skill 配置
│   └── skill.md            # Skill 提示词（核心逻辑）
├── src/                     # 可选的辅助代码
│   └── utils.py            # 工具函数
├── examples/                # 使用示例
├── docs/                    # 文档
├── TODO.md                  # 任务清单
└── claude.md                # 本文件
```

## 功能映射

### 从 git_commit_agent 到 Claude Code Skill

| git_commit_agent 功能 | Claude Code Skill 实现 |
|---------------------|----------------------|
| `GitCommitAgent` 类 | Skill 提示词 + Bash/Git 工具 |
| `_analyze_changes()` | `git diff --cached` + 文件分析 |
| `_detect_sensitive_info()` | 正则表达式检测 + 文件扫描 |
| `_plan_commits()` | Claude 分析 + AskUserQuestion |
| `_generate_commit_message()` | Claude LLM 生成 |
| `_score_commit_message()` | Claude 自我评估 |
| `_do_commit()` | `git commit` Bash 命令 |
| `ask_user_callback` | AskUserQuestion 工具 |

## Commit 规范

### Vue.js Commit Convention（默认）

**格式**:
```
<type>(<scope>): <subject>

<body>
```

**Type 类型**:
- `feat`: 新功能 ✨
- `fix`: 修复 bug 🐛
- `docs`: 文档变更 📝
- `style`: 代码格式 💄
- `refactor`: 重构 ♻️
- `perf`: 性能优化 ⚡
- `test`: 添加测试 ✅
- `chore`: 构建/工具变动 🔧
- `ci`: CI 配置 👷
- `build`: 构建系统 📦
- `revert`: 回退 ⏪

**示例**:
```
feat(backend): implement ProcessManager for async tasks

- Add ProcessManager class to manage long-running processes
- Support task status tracking (QUEUED, RUNNING, COMPLETED)
- Implement task cancellation with proper cleanup

Closes #123
```

## 工作流程

### 1. 分析变更
```bash
# 获取 staged 文件
git diff --cached --name-status

# 分析文件类型和模块
```

### 2. 敏感信息检测
扫描以下模式：
- API Keys: `sk-`, `AIza`, `ghp_`, etc.
- Tokens: `token`, `bearer`, `jwt`
- Passwords: `password`, `passwd`
- Secrets: `secret`, `private_key`
- 证书文件: `.pem`, `.key`, `.crt`

### 3. 智能拆分决策

**需要拆分的情况**:
- 跨多个模块的变更（backend + frontend + docs）
- 功能 + 修复混合
- 重构 + 新功能

**不需要拆分的情况**:
- 单个模块的紧密相关变更
- 简单的 bug 修复

### 4. 生成 Commit Message

基于：
- 文件变更内容
- 用户提供的上下文
- 项目历史风格
- Commit 规范

### 5. 质量评分

评分维度（0-100）:
- 格式规范（20%）
- 清晰度（25%）
- 完整性（20%）
- 范围准确（20%）
- 历史一致性（15%）

### 6. 执行提交

```bash
git commit -m "<commit message>"
```

## 配置支持

### 项目级配置 (.git-commit-agent.yml)

```yaml
# Commit 规范选择
convention: vuejs  # vuejs | conventional

# 拆分策略
split_strategy:
  enabled: true
  max_modules_per_commit: 3
  max_files_per_commit: 10

# 敏感信息检测
sensitive_detection:
  enabled: true
  custom_patterns:
    - COMPANY_SECRET_

# 质量标准
quality:
  min_score: 70
  learn_from_history: true

# 交互设置
interaction:
  auto_confirm: false
  confirm_on:
    - sensitive_data
    - large_commit
    - breaking_change
```

## 使用示例

### 基本用法
```
User: /commit 添加了用户登录功能
```

### 多上下文
```
User: /commit
- 实现了异步任务执行
- 添加了任务状态跟踪
- 修复了超时处理 bug
```

### 带问题确认
```
User: /commit 修复了后端并更新了文档

Claude: 检测到 backend 和 docs 两个模块的变更。
建议拆分为 2 个提交：
1. fix(backend): correct API endpoint configuration
2. docs: update API documentation

是否按此拆分提交？
1. 确认
2. 合并为一个
3. 自定义

User: 1
```

## 开发步骤

### Phase 1: 核心功能
- [x] 分析 git_commit_agent 代码
- [ ] 创建 Skill 基础结构
- [ ] 实现变更分析
- [ ] 实现敏感信息检测

### Phase 2: Message 生成
- [ ] 实现 commit message 生成逻辑
- [ ] 实现质量评分
- [ ] 添加多规范支持

### Phase 3: 交互与配置
- [ ] 添加交互式确认
- [ ] 支持配置文件
- [ ] 错误处理

### Phase 4: 测试与文档
- [ ] 实际项目测试
- [ ] 编写文档
- [ ] 创建示例

## 技术要点

### Claude Code Skill 最佳实践

1. **提示词优先**: 主要逻辑在 skill.md 中，而不是复杂代码
2. **工具集成**: 使用内置 Bash/Git 工具
3. **用户交互**: 通过 AskUserQuestion 实现交互
4. **错误处理**: 优雅处理失败情况
5. **可配置性**: 支持项目级配置

### 关键工具使用

- **Bash**: 执行 git 命令
- **AskUserQuestion**: 交互式确认
- **Read**: 读取文件内容
- **Grep**: 搜索敏感信息模式

## 依赖项

### Python 依赖（如需辅助代码）
```
GitPython>=3.1.40
PyYAML>=6.0.1
```

### Claude Code 内置工具
- Bash
- Git（通过 Bash）
- AskUserQuestion

## 测试计划

### 单元测试场景
1. 单文件提交
2. 多文件单模块提交
3. 多模块拆分提交
4. 敏感信息检测
5. 空变更处理
6. 未 staged 文件处理

### 集成测试场景
1. 实际项目提交
2. 与 git hooks 集成
3. 配置文件加载
4. 错误恢复

## 参考资源

- [Claude Code Skills 文档](https://github.com/anthropics/claude-code)
- [git_commit_agent 源码](../git_commit_agent/)
- [Vue.js Commit Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [Conventional Commits](https://www.conventionalcommits.org/)

## 贡献指南

欢迎贡献！请：
1. 查看 TODO.md 了解待办事项
2. 遵循现有代码风格
3. 添加测试覆盖新功能
4. 更新相关文档

## License

MIT（与 git_commit_agent 保持一致）

---

**项目状态**: 开发中
**最后更新**: 2026-01-09
