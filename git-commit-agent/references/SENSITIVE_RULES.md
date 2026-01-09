# 敏感信息检测规则

本文档详细说明 Git Commit Agent 的敏感信息检测规则和流程。

## 检测原则

**CRITICAL**: 只检测 `git diff --cached -U0`（staged 变更），不检测工作目录。

使用 `-U0`（不显示 diff 上下文）减少误报，专注于新增行。

---

## 强规则（Strong Rules）

默认**阻止提交**，需要用户明确确认才能继续。

### 规则列表

#### 1. AWS 密钥

**模式**：
```
AKIA[0-9A-Z]{16}
ASIA[0-9A-Z]{16}
[A-Z0-9]{20}  # AWS secret access key pattern
```

**示例**：
```
AKIAIOSFODNN7EXAMPLE
ASIAIOSFODNN7EXAMPLE
KXmVP9vBvvR4rfhQjKP4m5fZPv8hKY9pMk0S2v0k
```

**置信度**: 高（这些前缀是 AWS 专用的）

---

#### 2. PEM 私钥块

**模式**：
```
-----BEGIN [A-Z]+ PRIVATE KEY-----
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN EC PRIVATE KEY-----
-----BEGIN OPENSSH PRIVATE KEY-----
-----BEGIN DSA PRIVATE KEY-----
```

**示例**：
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAz7v5m3lJ9YxD8vNHo7uQaZpF5YvP2qN8oDxJqR7vL1wN9mZ2...
-----END RSA PRIVATE KEY-----
```

**置信度**: 高（PEM 格式是标准的私钥格式）

---

#### 3. 服务 Token（ distinctive 前缀）

**模式**：
```
sk-ant-[a-zA-Z0-9_-]{20,}     # Anthropic API Key
xoxb-[a-zA-Z0-9_-]{10,}        # Slack Bot Token
xoxp-[a-zA-Z0-9_-]{10,}        # Slack User Token
ghp_[a-zA-Z0-9]{36}            # GitHub Personal Access Token
gho_[a-zA-Z0-9]{36}            # GitHub OAuth Token
ghu_[a-zA-Z0-9]{36}            # GitHub User Token
ghs_[a-zA-Z0-9]{36}            # GitHub Server Token
ghr_[a-zA-Z0-9]{36}            # GitHub Refresh Token
glpat-[a-zA-Z0-9_-]{20}        # GitLab Personal Access Token
AKIA[0-9A-Z]{16}               # AWS Access Key (already covered above)
```

**示例**：
```
sk-ant-api03-1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7
xoxb-1234-5678-9012-3456
ghp_1234567890abcdefghijklmnopqrstuv
glpat-abcdef1234567890xyz
```

**置信度**: 高（这些前缀是各服务专用的）

---

### 强规则检测输出

```
🚨 强规则命中 - 检测到敏感信息！

文件: config/app.env:3
  AKIAIOSFODNN7EXAMPLE

文件: src/config.ts:42
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEAz7v5m3lJ9YxD8vNHo7uQaZpF5YvP2qN8...

⚠️  这是高置信度的敏感信息，默认阻止提交

处理建议:
1. 撤回 staged: git restore --staged <file>
2. 删除文件: git rm <file>
3. 替换为环境变量
4. 添加到 .gitignore
5. 如果是测试数据: 添加到 allowlist

选项:
1. 强制继续（不推荐）
2. 取消提交
3. 查看详细上下文
```

---

## 弱规则（Weak Rules）

需要**用户判断**，可能是敏感信息，也可能是正常代码。

### 规则列表

#### 1. 长_base64_字符串（高熵值）

**模式**：
```
[A-Za-z0-9+/]{20,}={0,2}
```

**触发条件**：
- 长度 ≥ 20 字符
- 高熵值（看起来随机）
- 不是明显的 URL 或文件路径

**示例**：
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9  # JWT token
SGVsbG8gV29ybGQh                       # 可能是测试数据（base64 of "Hello World!"）
dGhpc19pc19hX3Rlc3Rfc3RyaW5n          # 可能是测试数据（base64 of "this_is_a_test_string"）
```

**可能是**：
- JWT token / API key（敏感）
- 测试数据 / 示例代码（安全）
- 编码的配置值（需要判断）

**置信度**: 中（需要结合上下文判断）

---

#### 2. URL 模式（数据库连接字符串等）

**模式**：
```
DATABASE_URL=
REDIS_URL=
MONGODB_URI=
MONGO_URI=
POSTGRES_URI=
postgresql://
mysql://
mongodb://
redis://
amqp://
rabbitmq://
```

**示例**：
```
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
MONGODB_URI=mongodb://user:pass@host:27017/db
redis://:password@localhost:6379/0
```

**可能是**：
- 生产环境连接字符串（敏感）
- 本地开发配置（相对安全）
- 示例代码（安全）

**置信度**: 中（需要判断是否包含密码）

---

#### 3. Authorization 头部

**模式**：
```
Authorization: Bearer [a-zA-Z0-9._-]{20,}
Authorization: Token [a-zA-Z0-9]{20,}
api-key:\s*[a-zA-Z0-9]{20,}
x-api-key:\s*[a-zA-Z0-9]{20,}
```

**示例**：
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Authorization: Token 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p
api-key: sk-1234567890abcdef
x-api-key: live_abc123def456
```

**可能是**：
- 真实的 API key（敏感）
- 测试用 token（安全）
- 示例代码（安全）

**置信度**: 中（需要判断上下文）

---

### 弱规则检测输出

```
⚠️  弱规则命中 - 可能的敏感信息

文件: src/api.ts:42
  const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";

文件: .env:3
  DATABASE_URL=postgresql://user:password@localhost:5432/dbname

这可能是:
- 真实密钥 / token（敏感）
- 测试用 token（安全）
- 示例代码 / 模板（安全）
- 本地开发配置（相对安全）

选项:
1. 继续提交（确认这是安全的）
2. 取消提交
3. 查看上下文（±3 lines）
4. 将此模式添加到白名单
```

---

## 白名单模式（Allowlist）

自动跳过检测的模式（误报防护）

### 默认白名单

**匹配以下关键词的行跳过检测**：
```
example
test
dummy
placeholder
xxxx
xxxxxxxx
YOUR_
<your>
demo
sample
mock
fake
stub
```

**示例**（不会触发检测）：
```
const API_KEY = "YOUR_API_KEY_HERE";
export const DB_URL = "example://localhost:5432/test";
const token = "dummy_token_for_testing";
```

### 配置自定义白名单

在项目 `.git-commit-agent.yml` 中配置：

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
    - "mycompany_test_"  # 自定义
```

---

## 修复建议

### 方法 1: 撤回 Staged

```bash
# 只撤回 staged，保留工作区改动
git restore --staged <file>

# 同时撤回 staged 和工作区改动
git restore --staged <file>
git restore <file>
```

### 方法 2: 替换为环境变量

**改前**：
```env
API_KEY=sk-ant-xxx
DATABASE_URL=postgresql://user:pass@host/db
```

**改后**：
```env
API_KEY=${API_KEY}
DATABASE_URL=${DATABASE_URL}

# 或使用 .env.example 模板
API_KEY=your_api_key_here
DATABASE_URL=postgresql://user:password@host:port/database
```

### 方法 3: 添加到 .gitignore

```bash
# 添加模式到 .gitignore
echo "*.env" >> .gitignore
echo "config/secrets.yml" >> .gitignore
echo "**/private_key*" >> .gitignore

# 撤回已 staged 的敏感文件
git restore --staged <file>
git rm --cached <file>  # 从 git 中删除，但保留本地文件
```

### 方法 4: 旋转密钥（如果已暴露）

如果敏感信息已经提交到仓库：

1. **立即撤销密钥**：
   - 到服务控制台撤销旧密钥
   - 生成新密钥

2. **更新配置**：
   - 使用新密钥
   - 确保密钥不再提交

3. **清理 Git 历史**（如果必要）：
   ```bash
   # 使用 git filter-repo 清理历史
   git filter-repo --invert-paths --path config/secrets.yml

   # 或使用 BFG Repo-Cleaner
   bfg --replace-text passwords.txt
   ```

---

## 检测流程

### 完整检测算法

```python
def detect_sensitive(staged_diff):
    issues = []

    for line in staged_diff:
        # 检查白名单
        if matches_allowlist(line):
            continue

        # 检查强规则
        for rule in strong_rules:
            if rule.match(line):
                issues.append({
                    'type': 'strong',
                    'rule': rule.name,
                    'line': line,
                    'action': 'block'
                })

        # 检查弱规则
        for rule in weak_rules:
            if rule.match(line):
                issues.append({
                    'type': 'weak',
                    'rule': rule.name,
                    'line': line,
                    'action': 'warn'
                })

    return issues
```

### 用户交互流程

1. **扫描 staged 变更**
2. **分类检测**：
   - 强规则命中 → 阻止，要求确认
   - 弱规则命中 → 警告，询问用户
3. **用户选择**：
   - 强规则：强制继续 / 取消 / 查看上下文
   - 弱规则：继续 / 取消 / 查看上下文 / 添加白名单
4. **执行操作**：
   - 取消提交 → 结束
   - 继续提交 → 进入下一步（拆分规划）

---

## 最佳实践

### 1. 预防优于检测

**在提交前**：
- 使用 `.gitignore` 阻止敏感文件
- 使用 `.env.example` 模板而非真实配置
- 在 Git hooks 中添加检测（pre-commit）

**示例 pre-commit hook**：
```bash
#!/bin/bash
# .git/hooks/pre-commit

# 检测是否有 .env 文件被 staged
if git diff --cached --name-only | grep -E "\.env$|secrets|private_key"; then
  echo "⚠️  检测到敏感文件可能被提交！"
  echo "请确认这些文件应该被提交。"
  exit 1
fi
```

### 2. 使用 Secret 管理

**推荐方案**：
- **本地**: `.env` 文件（添加到 .gitignore）
- **CI/CD**: 环境变量 / Secret 管理工具
- **生产**: Vault / AWS Secrets Manager / etc.

### 3. 定期审计

```bash
# 扫描 Git 历史
git log --all --full-history --source -- "*secret*"

# 使用 trufflehog 扫描
trufflehog git https://github.com/your/repo
```

---

## 相关文档

- [SKILL.md](../SKILL.md) - 核心工作流
- [CONFIGURATION.md](CONFIGURATION.md) - 配置白名单
- [EXAMPLES.md](EXAMPLES.md) - 实战案例

---

**版本**: 1.0.0
**最后更新**: 2026-01-09
