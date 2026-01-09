# Claude Code Project Notes

## 开发注意事项

### SKILL.md 编写规范

1. **不要在代码块中使用反引号包裹特殊字符**

   ❌ **错误**:
   ```markdown
   Add `!` after type/scope if breaking change detected:
   ```

   ✅ **正确**:
   ```markdown
   Add ! after type/scope if breaking change detected:
   ```

   **原因**: 反引号内的 `!` 可能被 bash 解析为历史扩展字符，导致 "Bash command failed" 错误。直接使用 `!` 而不加反引号可以避免这个问题。

2. **优先使用单引号包裹 commit message**

   ```bash
   git commit -m 'feat(api)!: breaking change'
   ```

   单引号可以保留所有特殊字符的原始含义，包括 `!`、`$` 等。

---

## 项目历史

### 2026-01-09: 重构优化

基于 Anthropic 官方最佳实践优化 skill 结构：

- SKILL.md: 1549 → 741 行（减少 52%）
- 创建 references/ 目录，采用渐进式披露模式
- 删除用户文档（README, QUICK_START 等，官方不建议包含）
- 新增 4 个详细参考文档：
  - SENSITIVE_RULES.md - 敏感信息检测规则
  - CONFIGURATION.md - 完整配置指南
  - DECISION_TREE.md - 拆分决策树
  - EXAMPLES.md - 使用示例集

### 2026-01-09: Bash History Expansion 问题修复

**问题**: Breaking change `!` 字符导致 bash 执行错误

**症状**:
```
Error: Bash command failed for pattern "!` after type/scope if breaking change detected:
```

**解决方案**:
```
1. 在 SKILL.md 中直接使用 ! 而非 `!`
2. 不使用 `set +H`（用户选择的方式）
3. 使用单引号包裹 commit message
```

**相关文档**:
- BASH_ESCAPE_FIX.md 已删除（内容整合到 SKILL.md）

---

## 项目结构

```
git_commit_agent-skill/
├── git-commit-agent/
│   ├── SKILL.md (741 lines) - 核心工作流
│   ├── references/            # 详细参考文档
│   │   ├── CONVENTIONS.md     # Vue.js Commit 规范
│   │   ├── SENSITIVE_RULES.md # 敏感信息检测
│   │   ├── CONFIGURATION.md   # 配置详解
│   │   ├── DECISION_TREE.md   # 拆分决策树
│   │   └── EXAMPLES.md        # 使用示例
│   └── scripts/               # 辅助脚本
│       └── analyze_layers.sh
└── claude.md                  # 本文件
```

---

## 参考资料

- [Anthropic Official Skills](https://github.com/anthropics/skills)
- [Vue.js Commit Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [Conventional Commits](https://www.conventionalcommits.org/)
