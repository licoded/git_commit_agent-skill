# Bash 历史扩展导致的 Commit 错误 - 根本原因与解决方案

## 🐛 问题症状

执行 skill 时出现以下错误：

```
Error: Bash command failed for pattern "!` after type/scope if breaking change detected:
```

## 🔍 根本原因

### Bash 历史扩展（History Expansion）

在 bash 中，`!` 字符有特殊含义 - 它用于**历史扩展**（History Expansion）：

```bash
# 示例：bash 会尝试扩展 ! 为历史命令
$ echo "Hello!"
# 可能触发: event not found 错误

$ git commit -m "feat(api)!: breaking change"
# 错误: bash: !: event not found
```

### 为什么发生在 Git Commit 中

Vue.js Commit Convention 使用 `!` 标记 breaking change：

```
feat(api)!: change response format

BREAKING CHANGE: API now uses camelCase
```

当 skill 尝试执行这样的 commit 时，bash 会：
1. 解析命令行
2. 看到 `!` 字符
3. 尝试进行历史扩展
4. 扩展失败（因为 `!` 后面不是有效的历史引用）
5. 报错退出

### 为什么用户改了 `!` 还报错

用户将 line 831 的 `` `!` `` 改为 `!`（去除反引号），但错误依然存在，因为：

**问题不在文档文字中，而在实际执行 git commit 命令时！**

SKILL.md 中的示例只是文档，但当 skill 真正执行 git commit 时，如果 commit message 包含 `!`，bash 就会尝试扩展它。

## ✅ 解决方案

### 方案 1: 禁用历史扩展（推荐）

在执行 git 命令前，添加：

```bash
set +H  # 禁用历史扩展
```

**优点**：
- 彻底解决问题
- 一次设置，全程有效
- 不影响其他功能

**已实施的修改**：
- ✅ 在 Step 1 添加 `set +H`
- ✅ 在 Breaking Change Detection 添加警告说明
- ✅ 在 Step 6 执行前提醒检查

### 方案 2: 使用单引号

在 git commit 命令中使用单引号（单引号内所有字符都是字面量）：

```bash
# ❌ 错误：双引号不能阻止历史扩展
git commit -m "feat(api)!: breaking change"

# ✅ 正确：单引号阻止所有特殊字符处理
git commit -m 'feat(api)!: breaking change'
```

**优点**：
- 不需要全局设置
- 更精确控制

**缺点**：
- 需要在每个命令中记住使用单引号
- 单引号内不能包含单引号字符

### 方案 3: 转义 `!` 字符

```bash
git commit -m "feat(api)\!: breaking change"
```

**缺点**：
- 容易遗漏
- commit message 中会出现 `\` 字符
- 不推荐

## 📝 实施的修改

### 1. Step 1: Repository & Status Check

```bash
# Disable bash history expansion to avoid issues with '!' in commit messages
set +H

# Verify git repository
git rev-parse --is-inside-work-tree
...
```

### 2. Breaking Change Detection Section

添加重要提示：

```markdown
#### Breaking Change Detection

**IMPORTANT**: The `!` character in breaking changes can trigger bash history expansion.
Always ensure `set +H` is executed before running git commits with `!` to avoid parsing errors.

Add ! after type/scope if breaking change detected:
```

### 3. Step 6: Execute Commit

添加执行前检查和单引号示例：

```markdown
### Step 6: Execute Commit

**Pre-execution check**: Ensure bash history expansion is disabled (`set +H`)
to handle breaking changes with `!` character.

#### Single Commit

```bash
# Use single quotes to preserve special characters including '!'
git commit -m '<message>'
```
```

## 🧪 验证修复

修复后，breaking change commit 应该能正常执行：

```bash
$ set +H  # 禁用历史扩展
$ git commit -m 'feat(api)!: change response format'

[main abc1234] feat(api)!: change response format
 1 file changed, 10 insertions(+), 5 deletions(-)
```

## 📚 相关知识

### Bash 历史扩展（History Expansion）

| 命令 | 说明 | 示例 |
|------|------|------|
| `!!` | 上一条命令 | `sudo !!` |
| `!n` | 历史第 n 条命令 | `!42` |
| `!string` | 最近以 string 开头的命令 | `!git` |
| `!?string?` | 最近包含 string 的命令 | `!?commit?` |
| `^string1^string2` | 替换上一命令的 string1 为 string2 | `^foo^bar` |

### 为什么 `set +H` 有效

- `set +H` = 禁用历史扩展（HistExpand）
- `set -H` = 启用历史扩展（默认）
- 在交互式 bash 中默认开启
- 在脚本中默认关闭

## 🎯 最佳实践

1. **在 skill 开头添加 `set +H`** ✅
2. **使用单引号包裹 commit message** ✅
3. **在文档中说明 `!` 的特殊含义** ✅
4. **提供 breaking change 示例时使用单引号** ✅

## 📖 参考资料

- [Bash Manual - History Expansion](https://www.gnu.org/software/bash/manual/html_node/History-Interaction.html)
- [Vue.js Commit Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**创建时间**: 2026-01-09
**修复版本**: v1.0.1
**修复内容**: 添加 `set +H` 和单引号使用说明
