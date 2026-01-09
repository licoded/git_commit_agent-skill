# Git Commit Agent Skill - TODO

## 项目目标

将 git_commit_agent 转换为 Claude Code Skill，让用户可以通过简单的命令（如 `/commit`）来智能提交代码。

## 核心功能

从 git_commit_agent 迁移以下功能：

### Phase 1: 核心功能迁移 ✅
- [x] 分析 git_commit_agent 代码结构
- [x] 理解工作流程和 API
- [ ] 创建 Skill 基础结构
- [ ] 实现变更分析功能
- [ ] 实现敏感信息检测
- [ ] 实现 commit message 生成
- [ ] 实现质量评分

### Phase 2: Skill 文件创建
- [ ] 创建 skill.yaml (Skill 配置文件)
- [ ] 创建 skill.md (Skill 提示词文件)
- [ ] 适配 Claude Code Skill 接口
- [ ] 处理用户交互（AskUserQuestion）

### Phase 3: 测试与优化
- [ ] 在实际项目中测试
- [ ] 优化 commit message 生成质量
- [ ] 添加更多 commit 类型支持
- [ ] 改进错误处理

### Phase 4: 文档与安装
- [ ] 编写安装指南
- [ ] 编写使用示例
- [ ] 创建配置模板
- [ ] 添加故障排除文档

## 技术要点

### 1. Skill 结构
```
.git_commit_agent-skill/
├── skill/              # Claude Code Skill 目录
│   ├── skill.yaml      # Skill 配置
│   └── skill.md        # Skill 提示词
├── src/                # 源代码（可选，如果需要复杂逻辑）
├── examples/           # 使用示例
├── docs/               # 文档
├── TODO.md             # 本文件
└── claude.md           # Claude Code 项目说明
```

### 2. 关键功能适配

#### git_commit_agent → Claude Code Skill 映射

| git_commit_agent | Claude Code Skill |
|-----------------|-------------------|
| `GitCommitAgent(repo_path, context)` | Skill 参数：`--context` 或直接对话 |
| `_analyze_changes()` | 使用 GitPython 获取 staged 文件 |
| `_detect_sensitive_info()` | 正则表达式检测敏感信息 |
| `_plan_commits()` | 分析是否需要拆分提交 |
| `_generate_commit_message()` | 使用 Claude 生成 message |
| `ask_user_callback` | 使用 `AskUserQuestion` 工具 |
| `_do_commit()` | 使用 Bash 工具执行 git commit |

### 3. Claude Code Skill 最佳实践

- **简单优先**: 主要逻辑在 skill.md 提示词中，而不是复杂代码
- **工具使用**: 充分利用 Claude Code 内置工具（Bash, Git 等）
- **交互式**: 使用 AskUserQuestion 获取用户确认
- **可配置**: 支持项目级配置文件

## 使用场景

### 场景 1: 简单提交
```
User: /commit 添加了用户登录功能
Claude: 分析变更 → 生成 commit message → 执行提交
```

### 场景 2: 智能拆分
```
User: /commit 修复了后端 API 和更新了前端文档
Claude: 检测到多模块 → 询问是否拆分 → 执行多个提交
```

### 场景 3: 敏感信息检测
```
User: /commit 添加了配置文件
Claude: 检测到敏感信息 → 警告用户 → 询问是否继续
```

## 依赖项

### 必需
- GitPython (已包含在 git_commit_agent)
- PyYAML (配置文件解析)

### 可选
- python-magic (文件类型检测)

## 配置文件

### 项目级配置 (.git-commit-agent.yml)
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

## 成功标准

1. ✅ 可以通过 `/commit` 命令智能提交代码
2. ✅ 生成的 commit message 符合规范
3. ✅ 可以检测敏感信息
4. ✅ 可以智能拆分提交
5. ✅ 交互式确认流程友好
6. ✅ 安装配置简单明了

## 参考资料

- [Claude Code Skills 文档](https://github.com/anthropics/claude-code)
- [Vue.js Commit Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [Conventional Commits](https://www.conventionalcommits.org/)
- git_commit_agent 源代码: `../git_commit_agent/`

## 进度跟踪

- [x] Phase 1: 分析和理解 (完成)
- [ ] Phase 2: 创建 Skill (进行中)
- [ ] Phase 3: 测试优化 (待开始)
- [ ] Phase 4: 文档完善 (待开始)

---

**最后更新**: 2026-01-09
