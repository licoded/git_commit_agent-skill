# Git Commit Agent Skill - 安装配置指南

## 安装步骤

### 1. 定位 Claude Code Skills 目录

Claude Code 的 skills 通常安装在以下位置之一：

```bash
# Linux/macOS
~/.claude/skills/

# 或者用户指定目录
# 可以通过 Claude Code 设置查看
```

### 2. 安装 Skill

将 `git-commit-agent.skill` 文件复制到 skills 目录：

```bash
# 创建 skills 目录（如果不存在）
mkdir -p ~/.claude/skills/

# 复制 skill 文件
cp git-commit-agent.skill ~/.claude/skills/

# 解压 skill 文件（.skill 文件实际上是 zip 格式）
cd ~/.claude/skills/
unzip git-commit-agent.skill
```

或者使用 Claude Code 内置的 skill 安装功能（如果支持）。

### 3. 验证安装

在 Claude Code 中测试 skill 是否可用：

```
/commit 测试提交
```

如果 skill 正确安装，Claude Code 应该会：
1. 检查 git 仓库
2. 检测 staged 变更
3. 执行 commit workflow

## 配置选项

### 项目级配置

在项目根目录创建 `.git-commit-agent.yml`：

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
    - INTERNAL_API_KEY

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

### 全局配置（可选）

如果需要全局配置，可以创建 `~/.git-commit-agent.yml`，项目级配置会覆盖全局配置。

## 使用方法

### 基本用法

```
/commit 添加了用户登录功能
```

### 上下文说明

```
/commit
- 实现了异步任务执行
- 添加了任务状态跟踪
- 修复了超时处理 bug
```

### 中文支持

```
/commit 修复了 API 认证问题
```

## 工作流程

1. **准备变更**: 先使用 `git add` 添加文件到暂存区
   ```bash
   git add file1.py file2.py
   ```

2. **调用 Skill**: 在 Claude Code 中使用 `/commit` 命令

3. **确认提交**: Skill 会：
   - 分析变更
   - 检测敏感信息
   - 生成 commit message
   - 询问是否拆分（如需要）
   - 执行提交

## 技能特性

### ✅ 自动功能

- 智能分析代码变更
- 生成符合规范的 commit message
- 支持中英文上下文
- 从项目历史学习风格

### ⚠️ 交互确认

- 敏感信息检测时确认
- 多模块拆分时确认
- Breaking changes 提示

### 📊 质量评分

自动对 commit message 进行质量评分（0-100），确保高质量提交。

## 故障排除

### 问题 1: Skill 未找到

**症状**: `/commit` 命令不起作用

**解决方案**:
1. 确认 skill 文件在正确目录
2. 检查 Claude Code 版本是否支持 skills
3. 重启 Claude Code

### 问题 2: Git 错误

**症状**: 提交失败，显示 git 错误

**解决方案**:
```bash
# 配置 git 用户信息
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 问题 3: 没有 staged 变更

**症状**: 提示 "没有已 staged 的变更"

**解决方案**:
```bash
# 添加要提交的文件
git add <files>

# 或添加所有变更
git add .
```

### 问题 4: 敏感信息误报

**症状**: 检测到误报的敏感信息

**解决方案**:
在 `.git-commit-agent.yml` 中自定义检测模式：
```yaml
sensitive_detection:
  enabled: true
  custom_patterns: []
```

## 卸载

```bash
# 删除 skill 文件
rm ~/.claude/skills/git-commit-agent.skill
rm -rf ~/.claude/skills/git-commit-agent/

# 或删除整个 skills 目录中的 skill
```

## 更新

```bash
# 复制新的 .skill 文件
cp git-commit-agent.skill ~/.claude/skills/

# 解压并覆盖
cd ~/.claude/skills/
unzip -o git-commit-agent.skill
```

## 高级用法

### 与 Git Hooks 集成

在 `.git/hooks/prepare-commit-msg` 中添加：

```bash
#!/bin/bash
# 可以在这里集成 commit message 验证
```

### 自定义 Commit 类型

编辑项目中的 `.git-commit-agent.yml`，添加自定义类型：

```yaml
custom_types:
  - name: "hotfix"
    description: "紧急修复"
  - name: "release"
    description: "发布版本"
```

## 参考资源

- [Vue.js Commit Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Claude Code Documentation](https://github.com/anthropics/claude-code)

## 支持

如有问题，请：
1. 查看 [claude.md](claude.md) 了解项目详情
2. 查看 [TODO.md](TODO.md) 了解功能计划
3. 提交 Issue 到项目仓库

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
